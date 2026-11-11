.pragma library

const unknown = -1

const tabs = [
    { key: "processes", label: "PROCESSES" },
    { key: "history", label: "APP HISTORY" }
]

const columns = {
    processes: [
        { key: "name", label: "NAME" },
        { key: "cpu", label: "CPU" },
        { key: "memory", label: "MEMORY" },
        { key: "disk", label: "DISK" },
        { key: "network", label: "NETWORK" }
    ],
    history: [
        { key: "name", label: "NAME" },
        { key: "cpuTime", label: "CPU TIME" },
        { key: "memory", label: "PEAK" },
        { key: "disk", label: "DISK" },
        { key: "network", label: "NETWORK" }
    ]
}

const actions = [
    { key: "kill", label: "KILL" },
    { key: "open", label: "OPEN" },
    { key: "find", label: "FIND PATH" }
]

function remember(sample) {
    const byPid = {}
    for (const entry of sample.processes)
        byPid[entry[0]] = { ticks: entry[3], disk: entry[5] }
    return { time: sample.time, ticks: sample.ticks, byPid: byPid }
}

function measure(previous, sample) {
    if (!previous)
        return null
    const spentTicks = sample.ticks - previous.ticks
    const seconds = sample.time - previous.time
    if (spentTicks <= 0 || seconds <= 0)
        return null
    return sample.processes.map(entry => {
        const before = previous.byPid[entry[0]]
        const ticks = before ? Math.max(0, entry[3] - before.ticks) : 0
        const isDiskKnown = entry[5] >= 0 && (!before || before.disk >= 0)
        return {
            pid: entry[0],
            name: entry[1],
            path: entry[2],
            cpu: ticks / spentTicks,
            cpuTotal: entry[3] / sample.hertz,
            memory: entry[4],
            disk: isDiskKnown ? (before ? Math.max(0, entry[5] - before.disk) / seconds : 0) : unknown,
            diskTotal: Math.max(0, entry[5]),
            network: unknown
        }
    })
}

function sum(first, second) {
    if (first === unknown)
        return second
    if (second === unknown)
        return first
    return first + second
}

function group(rows) {
    const byName = {}
    const order = []
    for (const row of rows) {
        let found = byName[row.name]
        if (!found) {
            found = { key: row.name, name: row.name, path: row.path, pids: [], cpu: 0, memory: 0, disk: unknown, network: unknown }
            byName[row.name] = found
            order.push(found)
        }
        found.pids.push(row.pid)
        found.path = found.path || row.path
        found.cpu += row.cpu
        found.memory += row.memory
        found.disk = sum(found.disk, row.disk)
        found.network = sum(found.network, row.network)
    }
    return order
}

function close(entry, live) {
    entry.cpuTime += live[0]
    entry.disk += live[1]
}

function record(history, rows) {
    const byName = {}
    for (const row of rows)
        (byName[row.name] = byName[row.name] ?? []).push(row)
    const next = {}
    for (const name of Object.keys(history).concat(Object.keys(byName))) {
        if (name in next)
            continue
        const before = history[name] ?? { name: name, path: "", cpuTime: 0, memory: 0, disk: 0, network: unknown, live: {} }
        const entry = { name: name, path: before.path, cpuTime: before.cpuTime, memory: before.memory, disk: before.disk, network: before.network, live: {} }
        let memory = 0
        for (const row of byName[name] ?? []) {
            const was = before.live[row.pid]
            if (was && (row.cpuTotal < was[0] || row.diskTotal < was[1]))
                close(entry, was)
            entry.live[row.pid] = [row.cpuTotal, row.diskTotal]
            entry.path = entry.path || row.path
            memory += row.memory
        }
        for (const pid of Object.keys(before.live)) {
            if (!(pid in entry.live))
                close(entry, before.live[pid])
        }
        entry.memory = Math.max(before.memory, memory)
        next[name] = entry
    }
    return next
}

function historyRows(history) {
    return Object.keys(history).map(name => {
        const entry = history[name]
        const live = Object.keys(entry.live).map(pid => entry.live[pid])
        return {
            key: name,
            name: name,
            path: entry.path,
            pids: [],
            cpuTime: live.reduce((total, values) => total + values[0], entry.cpuTime),
            memory: entry.memory,
            disk: live.reduce((total, values) => total + values[1], entry.disk),
            network: entry.network
        }
    })
}

function fieldsOf(row) {
    return {
        key: row.key,
        name: row.name,
        count: row.pids.length,
        cpu: row.cpu ?? 0,
        cpuTime: row.cpuTime ?? 0,
        memory: row.memory,
        disk: row.disk,
        network: row.network
    }
}

function sync(model, rows) {
    for (let index = 0; index < rows.length; index++) {
        const fields = fieldsOf(rows[index])
        let found = -1
        for (let at = index; at < model.count && found < 0; at++) {
            if (model.get(at).key === fields.key)
                found = at
        }
        if (found < 0) {
            model.insert(index, fields)
            continue
        }
        if (found !== index)
            model.move(found, index, 1)
        model.set(index, fields)
    }
    if (model.count > rows.length)
        model.remove(rows.length, model.count - rows.length)
}

function compare(first, second, key) {
    if (key === "name")
        return first.name.localeCompare(second.name, undefined, { sensitivity: "base" })
    return first[key] - second[key]
}

function sorted(rows, sort) {
    const direction = sort.isDescending ? -1 : 1
    return rows.slice().sort((first, second) => direction * compare(first, second, sort.key) || compare(first, second, "name"))
}

function nextSort(sort, key) {
    if (sort.key === key)
        return { key: key, isDescending: !sort.isDescending }
    return { key: key, isDescending: key !== "name" }
}

function step(rows, selectedKey, offset) {
    if (rows.length === 0)
        return ""
    const at = rows.findIndex(row => row.key === selectedKey)
    if (at < 0)
        return rows[offset > 0 ? 0 : rows.length - 1].key
    return rows[Math.max(0, Math.min(rows.length - 1, at + offset))].key
}

function percent(share) {
    if (share === unknown)
        return "--"
    const value = share * 100
    return (value < 10 ? value.toFixed(1) : Math.round(value)) + "%"
}

function bytes(amount) {
    if (amount === unknown)
        return "--"
    const units = ["B", "KB", "MB", "GB", "TB"]
    let value = amount
    let unit = 0
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024
        unit++
    }
    return (unit === 0 || value >= 100 ? Math.round(value) : value.toFixed(1)) + " " + units[unit]
}

function rate(amount) {
    return amount === unknown ? "--" : bytes(amount) + "/s"
}

function duration(seconds) {
    const total = Math.round(seconds)
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor(total % 3600 / 60)
    const rest = total % 60
    const padded = value => (value < 10 ? "0" : "") + value
    return hours + ":" + padded(minutes) + ":" + padded(rest)
}

function cell(row, key) {
    if (key === "cpu")
        return percent(row.cpu)
    if (key === "cpuTime")
        return duration(row.cpuTime)
    if (key === "memory")
        return bytes(row.memory)
    if (key === "disk")
        return row.count === 0 ? bytes(row.disk) : rate(row.disk)
    if (key === "network")
        return row.count === 0 ? bytes(row.network) : rate(row.network)
    return row.name
}

function share(row, key, totals) {
    const value = row[key]
    const whole = totals[key] ?? 0
    return value === unknown || whole <= 0 ? 0 : Math.min(1, value / whole)
}

function directory(path) {
    const at = path.lastIndexOf("/")
    return at > 0 ? path.slice(0, at) : "/"
}
