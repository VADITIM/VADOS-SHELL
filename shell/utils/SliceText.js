.pragma library
.import "Geometry.js" as Geometry
.import "Scramble.js" as Scramble

function linesOf(text) {
    return text.length > 0 ? text.split("\n") : []
}

function columnsOf(text) {
    return linesOf(text).reduce((widest, line) => Math.max(widest, line.length), 0)
}

function rowsOf(text) {
    return linesOf(text).length
}

function scatterOf(seed) {
    const value = Math.sin(seed * 12.9898 + 78.233) * 43758.5453
    return value - Math.floor(value)
}

function glyphsOf(text, jitter) {
    const lines = linesOf(text)
    const lastColumn = Math.max(1, columnsOf(text) - 1)
    const lastRow = Math.max(1, lines.length - 1)
    const glyphs = []
    lines.forEach((line, row) => {
        for (let column = 0; column < line.length; column++) {
            const glyph = line.charAt(column)
            if (glyph === " ")
                continue
            const seed = glyphs.length + 1
            glyphs.push({
                glyph: glyph,
                order: seed,
                column: column,
                row: row,
                diagonal: (column / lastColumn + row / lastRow) / 2,
                middle: lines.length > 1 ? 1 - Math.abs(row / lastRow * 2 - 1) : 1,
                speed: 1 + (scatterOf(seed) * 2 - 1) * jitter,
                scatter: scatterOf(seed + 0.31),
                spin: scatterOf(seed + 0.67) * 2 - 1,
                leaveShare: 1 - scatterOf(seed + 0.89) * jitter / 2
            })
        }
    })
    return glyphs
}

function pointIn(reach, glyph, round, cellWidth, cellHeight) {
    return {
        x: reach.x + scatterOf(glyph.order * 7.13 + round * 101.7) * Math.max(0, reach.width - cellWidth),
        y: reach.y + scatterOf(glyph.order * 3.91 + round * 57.3 + 0.5) * Math.max(0, reach.height - cellHeight)
    }
}

function enterTotal(pace, jitter) {
    return Math.round(pace.sweep + pace.scatter + pace.settle / (1 - jitter))
}

function enterClock(glyph, time, pace) {
    return (time - glyph.diagonal * pace.sweep - glyph.scatter * pace.scatter) / 1000 * glyph.speed
}

function pullOf(glyph, time, pace) {
    const start = glyph.diagonal * pace.leaveSweep
    const length = Math.max(1, pace.leave * glyph.leaveShare)
    const share = Geometry.clampUnit((time - start) / length)
    return share * share
}

function pushOf(glyphX, glyphY, pointerX, pointerY, reach, depth) {
    const deltaX = glyphX - pointerX
    const deltaY = glyphY - pointerY
    const distance = Math.hypot(deltaX, deltaY)
    if (reach <= 0 || distance >= reach || distance === 0)
        return { x: 0, y: 0 }
    const strength = depth * Geometry.smooth(1 - distance / reach)
    return { x: deltaX / distance * strength, y: deltaY / distance * strength }
}

function sweepTotal(text, stagger, spin, stretch) {
    return Math.max(0, columnsOf(text) - 1) * stagger + spin * (1 + (stretch || 0))
}

function sweepOf(glyph, time, stagger, timing, symbols) {
    const stretch = timing.spin * (timing.stretch || 0)
    const reach = stretch * glyph.middle
    const start = glyph.column * stagger + (stretch - reach) / 2
    const phase = Scramble.phaseOf(0, (time - start) * timing.spin / (timing.spin + reach), timing)
    const isSpinning = phase.isVisible && !phase.isResolved
    return {
        glyph: isSpinning ? Scramble.symbolAt(symbols, glyph.order, phase.step) : glyph.glyph,
        rotation: phase.isVisible ? phase.rotation : 0
    }
}
