.pragma library

const columns = 16
const rows = 16

const modules = [
    { key: "clock", label: "TIME / DATE", group: "CORE", columns: 6, rows: 3, isCore: true },
    { key: "profile", label: "USER PROFILE", group: "CORE", columns: 4, rows: 4, isCore: true },
    { key: "login", label: "LOGIN WINDOW", group: "CORE", columns: 6, rows: 3, isCore: true },
    { key: "weather", label: "WEATHER", group: "WIDGETS", columns: 4, rows: 3, isCore: false },
    { key: "music", label: "MUSIC PLAYER", group: "WIDGETS", columns: 5, rows: 3, isCore: false },
    { key: "dashboard", label: "MINI DASHBOARD", group: "WIDGETS", columns: 6, rows: 4, isCore: false },
    { key: "notifications", label: "NOTIFICATIONS", group: "WIDGETS", columns: 5, rows: 5, isCore: false }
]

function moduleOf(key) {
    return modules.find(entry => entry.key === key) ?? null
}

function parse(entries) {
    const result = []
    for (const entry of entries || []) {
        const parts = String(entry).split(":")
        const found = moduleOf(parts[0])
        const column = Number(parts[1])
        const row = Number(parts[2])
        if (found && Number.isInteger(column) && Number.isInteger(row))
            result.push({ key: found.key, column: column, row: row, columns: found.columns, rows: found.rows })
    }
    return result
}

function format(placement) {
    return placement.key + ":" + placement.column + ":" + placement.row
}

function isInside(found, column, row) {
    return column >= 0 && row >= 0 && column + found.columns <= columns && row + found.rows <= rows
}

function overlaps(placement, found, column, row) {
    return placement.column < column + found.columns && column < placement.column + placement.columns
        && placement.row < row + found.rows && row < placement.row + placement.rows
}

function fits(entries, key, column, row) {
    const found = moduleOf(key)
    if (!found || !isInside(found, column, row))
        return false
    return parse(entries).every(placement => placement.key === key || !overlaps(placement, found, column, row))
}

function place(entries, key, column, row) {
    if (!fits(entries, key, column, row))
        return entries
    const kept = parse(entries).filter(placement => placement.key !== key).map(format)
    return kept.concat([key + ":" + column + ":" + row])
}

function remove(entries, key) {
    const found = moduleOf(key)
    if (!found || found.isCore)
        return entries
    return parse(entries).filter(placement => placement.key !== key).map(format)
}

function isPlaced(entries, key) {
    return parse(entries).some(placement => placement.key === key)
}
