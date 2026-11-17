.pragma library

const profileOrder = ["performance", "balanced", "power-saver"]
const profileTitles = { "performance": "PERFORMANCE", "balanced": "BALANCED", "power-saver": "POWER SAVER" }

function profileTitle(key) {
    return profileTitles[key] ?? key.toUpperCase()
}

function parseProfiles(text) {
    const found = []
    let active = ""
    for (const line of text.split("\n")) {
        const match = /^(\*?)\s*([a-z-]+):\s*$/.exec(line)
        if (!match)
            continue
        found.push(match[2])
        if (match[1] === "*")
            active = match[2]
    }
    const keys = profileOrder.filter(key => found.indexOf(key) >= 0).concat(found.filter(key => profileOrder.indexOf(key) < 0))
    return { keys: keys, active: active }
}

function parseBrightness(text) {
    for (const line of text.split("\n")) {
        const parts = line.split(",")
        if (parts.length < 5 || parts[1] !== "backlight")
            continue
        const level = Number(parts[3].replace("%", "")) / 100
        if (!isNaN(level))
            return { device: parts[0], level: Math.max(0, Math.min(1, level)) }
    }
    return null
}

function brightnessArgument(level) {
    return Math.round(Math.max(0.01, Math.min(1, level)) * 100) + "%"
}

function deviceLabel(description, nickname, name) {
    const label = description || nickname || name || ""
    return label.length > 0 ? label : "UNKNOWN"
}

function streamLabel(properties, description, name) {
    const application = properties ? (properties["application.name"] || properties["application.process.binary"]) : ""
    return application || description || name || "STREAM"
}

function sectionRows(outputs, inputs, streams) {
    const rows = []
    const add = (title, kind, items) => {
        if (items.length === 0)
            return
        rows.push({ kind: "header", title: title, key: "header-" + kind })
        for (const item of items)
            rows.push(Object.assign({ kind: kind }, item))
    }
    add("OUTPUT", "output", outputs)
    add("INPUT", "input", inputs)
    add("STREAMS", "stream", streams)
    return rows
}

function stripEscapes(text) {
    return text.replace(/\x1b\[[0-9;]*m/g, "")
}

function parseStationName(text) {
    for (const line of stripEscapes(text).split("\n")) {
        const match = /^\s+(\S+)\s+(connected|disconnected|connecting|disconnecting)\b/.exec(line)
        if (match)
            return match[1]
    }
    return ""
}

function parseStationShow(text) {
    const state = /^\s*(?:\*\s+)?State\s+(\S+)/m.exec(stripEscapes(text))
    const network = /^\s*(?:\*\s+)?Connected network\s+(.+?)\s*$/m.exec(stripEscapes(text))
    return { isConnected: state !== null && state[1] === "connected", ssid: network ? network[1] : "" }
}

function parsePowered(text) {
    const match = /Powered\s+(on|off)\b/.exec(stripEscapes(text))
    return match === null || match[1] === "on"
}

function parseIwdNetworks(text) {
    const networks = []
    for (const line of stripEscapes(text).split("\n")) {
        const match = /^\s*(>)?\s*(.+?)\s{2,}(open|psk|8021x|wep)\s+(\*+)\s*$/.exec(line)
        if (!match)
            continue
        networks.push({
            ssid: match[2],
            strength: Math.min(1, match[4].length / 4),
            isSecured: match[3] !== "open",
            isActive: match[1] === ">"
        })
    }
    return networks.sort((first, second) => (second.isActive - first.isActive) || (second.strength - first.strength))
}

function parseFamilies(text) {
    const found = {}
    for (const line of text.split("\n")) {
        const family = line.split(",")[0].replace(/\\(.)/g, "$1").trim()
        if (family.length > 0 && family[0] !== ".")
            found[family] = true
    }
    return Object.keys(found).sort((first, second) => first.localeCompare(second))
}

function parseJoinLine(line) {
    const words = line.trim().split(" ")
    if (words[0] === "ask" && words.length > 1)
        return { kind: "ask", ask: words[1] }
    if (words[0] === "connected")
        return { kind: "result", result: "connected" }
    if (words[0] === "failed")
        return { kind: "result", result: words[1] || "error" }
    if (words[0] === "cancel")
        return { kind: "cancel" }
    return null
}

function parseIwdKnown(text) {
    const names = []
    for (const line of stripEscapes(text).split("\n")) {
        const match = /^\s+(.+?)\s{2,}(open|psk|8021x|wep)\b/.exec(line)
        if (match)
            names.push(match[1])
    }
    return names
}

function parseNmcliKnown(text) {
    const names = []
    for (const line of text.split("\n")) {
        const match = /^(.*):802-11-wireless$/.exec(line)
        if (match)
            names.push(match[1].replace(/\\(.)/g, "$1"))
    }
    return names
}

function joinMessage(result) {
    const messages = { "wrong": "WRONG PASSWORD", "missing": "NETWORK NOT FOUND", "canceled": "CANCELED", "error": "COULD NOT CONNECT" }
    return messages[result] ?? ""
}

const chargeLimitPercent = 80
const chargeFullPercent = 100

function parseChargeLimit(text) {
    const lines = text.split("\n").map(line => line.trim()).filter(line => line.length > 0)
    if (lines.length < 2 || lines[0] !== "Acer")
        return null
    const fields = lines[1].split(" ")
    if (fields.length < 3)
        return null
    const path = fields[0]
    const kind = path.endsWith("/health_mode") ? "health" : "threshold"
    const value = parseInt(fields[2])
    if (isNaN(value))
        return null
    return {
        path: path,
        kind: kind,
        isWritable: fields[1] === "w",
        isLimited: kind === "health" ? value === 1 : value <= chargeLimitPercent
    }
}

function chargeLimitValue(kind, isLimited) {
    if (kind === "health")
        return isLimited ? "1" : "0"
    return String(isLimited ? chargeLimitPercent : chargeFullPercent)
}
