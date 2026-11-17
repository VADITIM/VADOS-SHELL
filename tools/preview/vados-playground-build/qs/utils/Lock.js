.pragma library
.import "Placement.js" as Placement

const columns = 16
const rows = 16
const grid = { columns: columns, rows: rows }

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
    return Placement.parse(entries, modules)
}

function format(placement) {
    return Placement.format(placement)
}

function isInside(found, column, row) {
    return Placement.isInside(grid, found, column, row)
}

function overlaps(placement, found, column, row) {
    return Placement.overlaps(placement, found, column, row)
}

function fits(entries, key, column, row) {
    return Placement.fits(entries, modules, grid, key, column, row)
}

function place(entries, key, column, row) {
    return Placement.place(entries, modules, grid, key, column, row)
}

function remove(entries, key) {
    const found = moduleOf(key)
    if (!found || found.isCore)
        return entries
    return Placement.remove(entries, modules, key)
}

function isPlaced(entries, key) {
    return Placement.isPlaced(entries, modules, key)
}
