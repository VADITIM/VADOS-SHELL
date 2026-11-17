.pragma library
.import "Placement.js" as Placement

const widgets = [
    { key: "clock", label: "CLOCK", root: "ClockWidget", columns: 4, rows: 2, sources: [] },
    { key: "system", label: "SYSTEM", root: "SystemWidget", columns: 4, rows: 2, sources: ["hardware"] },
    { key: "weather", label: "WEATHER", root: "WeatherWidget", columns: 4, rows: 2, sources: ["weather"] },
    { key: "network", label: "NETWORK", root: "NetworkWidget", columns: 4, rows: 2, sources: [] },
    { key: "battery", label: "BATTERY", root: "BatteryWidget", columns: 2, rows: 2, sources: [] },
    { key: "disk", label: "DISK", root: "DiskWidget", columns: 2, rows: 2, sources: ["hardware"] }
]

const sources = ["hardware", "weather"]

function widgetOf(key) {
    return Placement.sizeOf(widgets, key)
}

function entryOf(entry) {
    const parts = String(entry).split(":")
    if (parts.length < 4)
        return null
    const screen = parts.slice(0, parts.length - 3).join(":")
    if (screen.length === 0)
        return null
    return { screen: screen, placement: parts.slice(parts.length - 3).join(":") }
}

function layoutOn(entries, screen) {
    const result = []
    for (const entry of entries || []) {
        const found = entryOf(entry)
        if (found && found.screen === screen)
            result.push(found.placement)
    }
    return result
}

function withLayout(entries, screen, placements) {
    const kept = (entries || []).filter(entry => {
        const found = entryOf(entry)
        return found !== null && found.screen !== screen
    })
    return kept.concat(placements.map(placement => screen + ":" + placement))
}

function screensOf(entries) {
    const names = []
    for (const entry of entries || []) {
        const found = entryOf(entry)
        if (found && names.indexOf(found.screen) < 0)
            names.push(found.screen)
    }
    return names
}

function hasLayout(entries, screen) {
    return Placement.parse(layoutOn(entries, screen), widgets).length > 0
}

function gridOn(width, height, look) {
    return Placement.gridOf(width - look.inset * 2, height - look.inset * 2, look.cell)
}

function originOn(width, height, grid, look) {
    return {
        x: Math.round((width - grid.columns * look.cell + look.gap) / 2),
        y: Math.round((height - grid.rows * look.cell + look.gap) / 2)
    }
}

function rectOf(placement, origin, look) {
    return {
        x: origin.x + placement.column * look.cell,
        y: origin.y + placement.row * look.cell,
        width: placement.columns * look.cell - look.gap,
        height: placement.rows * look.cell - look.gap
    }
}

function placedOn(entries, screen, grid) {
    return Placement.settle(layoutOn(entries, screen), widgets, grid)
}

function added(placements, grid, key) {
    const found = widgetOf(key)
    const current = placements.map(Placement.format)
    if (!found || placements.some(placement => placement.key === key))
        return current
    const spot = Placement.firstFree(placements, grid, found)
    if (!spot)
        return current
    return current.concat([Placement.format({ key: key, column: spot.column, row: spot.row })])
}

function removed(placements, key) {
    return placements.filter(placement => placement.key !== key).map(Placement.format)
}

function landing(placements, grid, key, column, row) {
    const found = placements.find(placement => placement.key === key)
    if (!found)
        return null
    const wantedColumn = Math.max(0, Math.min(column, grid.columns - found.columns))
    const wantedRow = Math.max(0, Math.min(row, grid.rows - found.rows))
    const spot = Placement.nearestFree(placements, grid, found, wantedColumn, wantedRow, key) ?? found
    return { key: key, column: spot.column, row: spot.row, columns: found.columns, rows: found.rows }
}

function moved(placements, grid, key, column, row) {
    const spot = landing(placements, grid, key, column, row)
    if (!spot)
        return placements.map(Placement.format)
    return placements.map(placement => Placement.format(placement.key === key ? { key: key, column: spot.column, row: spot.row } : placement))
}

function sourcesShown(entries, screens, look) {
    const shown = []
    for (const screen of screens || []) {
        if (screen.isCovered)
            continue
        for (const placement of placedOn(entries, screen.name, gridOn(screen.width, screen.height, look))) {
            for (const source of widgetOf(placement.key).sources) {
                if (shown.indexOf(source) < 0)
                    shown.push(source)
            }
        }
    }
    return shown.sort()
}
