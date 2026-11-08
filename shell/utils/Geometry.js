.pragma library

function clampUnit(value) {
    return Math.max(0, Math.min(1, value))
}

function smooth(value) {
    return value * value * (3 - 2 * value)
}

function mix(from, to, share) {
    return from + (to - from) * share
}

function centerOf(rectangle) {
    return Qt.point(rectangle.x + rectangle.width / 2, rectangle.y + rectangle.height / 2)
}

function headingOf(fromX, fromY, toX, toY) {
    return Math.atan2(toY - fromY, toX - fromX)
}

function splineAt(before, from, to, after, time) {
    const square = time * time
    return 0.5 * (2 * from + (to - before) * time + (2 * before - 5 * from + 4 * to - after) * square + (3 * from - before - 3 * to + after) * square * time)
}

function traceSpline(points, samples) {
    if (points.length === 0)
        return []
    const outline = [points[0]]
    for (let index = 0; index < points.length - 1; index++) {
        const before = points[Math.max(0, index - 1)]
        const from = points[index]
        const to = points[index + 1]
        const after = points[Math.min(points.length - 1, index + 2)]
        for (let sample = 1; sample <= samples; sample++) {
            const time = sample / samples
            outline.push(Qt.point(splineAt(before.x, from.x, to.x, after.x, time), splineAt(before.y, from.y, to.y, after.y, time)))
        }
    }
    return outline
}

function refit(shape, from, to) {
    const scaleX = from.width > 0 ? to.width / from.width : 1
    const scaleY = from.height > 0 ? to.height / from.height : 1
    const corner = Math.min(scaleX, scaleY)
    const fitted = Object.assign({}, shape, {
        x: to.x + (shape.x - from.x) * scaleX,
        y: to.y + (shape.y - from.y) * scaleY,
        width: shape.width * scaleX,
        height: shape.height * scaleY
    })
    for (const key of ["left", "right", "radius"]) {
        if (key in shape)
            fitted[key] = shape[key] * corner
    }
    return fitted
}
