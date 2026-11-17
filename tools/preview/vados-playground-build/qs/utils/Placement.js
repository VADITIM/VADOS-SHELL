.pragma library

function sizeOf(catalogue, key) {
    return catalogue.find(entry => entry.key === key) ?? null
}

function gridOf(width, height, cell) {
    if (!(cell > 0))
        return { columns: 0, rows: 0 }
    return { columns: Math.max(0, Math.floor(width / cell)), rows: Math.max(0, Math.floor(height / cell)) }
}

function parse(entries, catalogue) {
    const result = []
    for (const entry of entries || []) {
        const parts = String(entry).split(":")
        const found = sizeOf(catalogue, parts[0])
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

function isInside(grid, size, column, row) {
    return column >= 0 && row >= 0 && column + size.columns <= grid.columns && row + size.rows <= grid.rows
}

function overlaps(placement, size, column, row) {
    return placement.column < column + size.columns && column < placement.column + placement.columns
        && placement.row < row + size.rows && row < placement.row + placement.rows
}

function isFree(placements, size, column, row, ignoredKey) {
    return placements.every(placement => placement.key === ignoredKey || !overlaps(placement, size, column, row))
}

function fits(entries, catalogue, grid, key, column, row) {
    const found = sizeOf(catalogue, key)
    if (!found || !isInside(grid, found, column, row))
        return false
    return isFree(parse(entries, catalogue), found, column, row, key)
}

function place(entries, catalogue, grid, key, column, row) {
    if (!fits(entries, catalogue, grid, key, column, row))
        return entries
    const kept = parse(entries, catalogue).filter(placement => placement.key !== key).map(format)
    return kept.concat([format({ key: key, column: column, row: row })])
}

function remove(entries, catalogue, key) {
    return parse(entries, catalogue).filter(placement => placement.key !== key).map(format)
}

function isPlaced(entries, catalogue, key) {
    return parse(entries, catalogue).some(placement => placement.key === key)
}

function nearestFree(placements, grid, size, column, row, ignoredKey) {
    let best = null
    let bestDistance = Infinity
    for (let candidateRow = 0; candidateRow + size.rows <= grid.rows; candidateRow++) {
        for (let candidateColumn = 0; candidateColumn + size.columns <= grid.columns; candidateColumn++) {
            if (!isFree(placements, size, candidateColumn, candidateRow, ignoredKey))
                continue
            const distance = (candidateColumn - column) * (candidateColumn - column) + (candidateRow - row) * (candidateRow - row)
            if (distance < bestDistance) {
                best = { column: candidateColumn, row: candidateRow }
                bestDistance = distance
            }
        }
    }
    return best
}

function firstFree(placements, grid, size) {
    for (let row = 0; row + size.rows <= grid.rows; row++) {
        for (let column = 0; column + size.columns <= grid.columns; column++) {
            if (isFree(placements, size, column, row, ""))
                return { column: column, row: row }
        }
    }
    return null
}

function settle(entries, catalogue, grid) {
    const settled = []
    const waiting = []
    for (const placement of parse(entries, catalogue)) {
        if (settled.some(kept => kept.key === placement.key) || waiting.some(kept => kept.key === placement.key))
            continue
        if (isInside(grid, placement, placement.column, placement.row) && isFree(settled, placement, placement.column, placement.row, ""))
            settled.push(placement)
        else
            waiting.push(placement)
    }
    for (const placement of waiting) {
        const column = Math.max(0, Math.min(placement.column, grid.columns - placement.columns))
        const row = Math.max(0, Math.min(placement.row, grid.rows - placement.rows))
        const spot = nearestFree(settled, grid, placement, column, row, "")
        if (spot)
            settled.push({ key: placement.key, column: spot.column, row: spot.row, columns: placement.columns, rows: placement.rows })
    }
    return settled
}
