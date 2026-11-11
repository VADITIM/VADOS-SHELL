.pragma library

function clampUnit(value) {
    return Math.max(0, Math.min(1, value))
}

function smooth(value) {
    return value * value * (3 - 2 * value)
}

function rebound(value, overshoot) {
    const shifted = value - 1
    return 1 + shifted * shifted * ((overshoot + 1) * shifted + overshoot)
}

function superellipse(width, height, exponent, count) {
    const points = []
    for (let index = 0; index < count; index++) {
        const angle = index / count * 2 * Math.PI
        const cosine = Math.cos(angle)
        const sine = Math.sin(angle)
        const reachX = Math.sign(cosine) * Math.pow(Math.abs(cosine), 2 / exponent)
        const reachY = Math.sign(sine) * Math.pow(Math.abs(sine), 2 / exponent)
        points.push(Qt.point(width / 2 * (1 + reachX), height / 2 * (1 + reachY)))
    }
    return points
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

function samplesFor(length, step) {
    return Math.max(2, Math.ceil(length / step))
}

function traceSpline(points, step, slack) {
    if (points.length === 0)
        return []
    const outline = [points[0]]
    for (let index = 0; index < points.length - 1; index++) {
        const before = points[Math.max(0, index - 1)]
        const from = points[index]
        const to = points[index + 1]
        const after = points[Math.min(points.length - 1, index + 2)]
        const samples = samplesFor(Math.hypot(to.x - from.x, to.y - from.y) * slack, step)
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

function pointAlong(points, lengths, distance) {
    let low = 0
    let high = lengths.length - 1
    while (high - low > 1) {
        const middle = (low + high) >> 1
        if (lengths[middle] <= distance)
            low = middle
        else
            high = middle
    }
    const span = lengths[high] - lengths[low]
    const share = span > 0 ? clampUnit((distance - lengths[low]) / span) : 0
    return Qt.point(points[low].x + (points[high].x - points[low].x) * share, points[low].y + (points[high].y - points[low].y) * share)
}

function roundCorners(points, reach, step, sharpness) {
    const count = points.length
    if (count < 3 || reach < 0.5)
        return points
    const lengths = [0]
    for (let index = 1; index < count; index++)
        lengths.push(lengths[index - 1] + Math.hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y))
    const corners = []
    const limit = Math.cos(sharpness)
    for (let index = 1; index < count - 1; index++) {
        const before = lengths[index] - lengths[index - 1]
        const after = lengths[index + 1] - lengths[index]
        if (before <= 0 || after <= 0)
            continue
        const along = (points[index].x - points[index - 1].x) * (points[index + 1].x - points[index].x) + (points[index].y - points[index - 1].y) * (points[index + 1].y - points[index].y)
        if (along / (before * after) < limit)
            corners.push(index)
    }
    if (corners.length === 0)
        return points
    const cuts = corners.map((index, place) => {
        const behind = lengths[index] - (place > 0 ? lengths[corners[place - 1]] : 0)
        const ahead = (place < corners.length - 1 ? lengths[corners[place + 1]] : lengths[count - 1]) - lengths[index]
        const depth = Math.min(reach, behind / 2, ahead / 2)
        return { index: index, from: lengths[index] - depth, to: lengths[index] + depth, depth: depth }
    })
    const rounded = []
    let place = 0
    for (let index = 0; index < count; index++) {
        while (place < cuts.length && lengths[index] >= cuts[place].to && index > cuts[place].index)
            place++
        const cut = place < cuts.length ? cuts[place] : null
        if (cut && cut.depth > 0 && lengths[index] > cut.from && lengths[index] < cut.to) {
            if (index === cut.index) {
                const start = pointAlong(points, lengths, cut.from)
                const end = pointAlong(points, lengths, cut.to)
                const samples = samplesFor(cut.depth * 2, step)
                for (let sample = 0; sample <= samples; sample++) {
                    const time = sample / samples
                    const rest = 1 - time
                    rounded.push(Qt.point(
                        rest * rest * start.x + 2 * rest * time * points[index].x + time * time * end.x,
                        rest * rest * start.y + 2 * rest * time * points[index].y + time * time * end.y))
                }
            }
            continue
        }
        rounded.push(points[index])
    }
    return rounded
}

function halfOutline(width, height, radius, isClockwise, step) {
    const corner = Math.max(0, Math.min(radius, width / 2, height / 2))
    const quarter = Math.PI / 2
    const turns = isClockwise
        ? [[corner, corner, 2.5 * quarter, 3 * quarter], [width - corner, corner, 3 * quarter, 4 * quarter], [width - corner, height - corner, 0, 0.5 * quarter]]
        : [[corner, corner, 2.5 * quarter, 2 * quarter], [corner, height - corner, 2 * quarter, quarter], [width - corner, height - corner, quarter, 0.5 * quarter]]
    const points = []
    for (const [centerX, centerY, from, to] of turns) {
        const samples = samplesFor(Math.abs(to - from) * corner, step)
        for (let sample = 0; sample <= samples; sample++) {
            const angle = mix(from, to, sample / samples)
            points.push(Qt.point(centerX + Math.cos(angle) * corner, centerY + Math.sin(angle) * corner))
        }
    }
    return points
}

function cutAlong(points, share) {
    if (points.length < 2)
        return points
    const lengths = [0]
    for (let index = 1; index < points.length; index++)
        lengths.push(lengths[index - 1] + Math.hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y))
    const distance = clampUnit(share) * lengths[lengths.length - 1]
    const kept = [points[0]]
    for (let index = 1; index < points.length && lengths[index] < distance; index++)
        kept.push(points[index])
    kept.push(pointAlong(points, lengths, distance))
    return kept
}

function heightOn(line, x) {
    if (x <= line[0].x)
        return line[0].y
    const last = line[line.length - 1]
    if (x >= last.x)
        return last.y
    let low = 0
    let high = line.length - 1
    while (high - low > 1) {
        const middle = (low + high) >> 1
        if (line[middle].x <= x)
            low = middle
        else
            high = middle
    }
    const from = line[low]
    const to = line[high]
    return from.y + (to.y - from.y) * (x - from.x) / Math.max(0.001, to.x - from.x)
}

function pointsBetween(line, fromX, toX) {
    const inner = line.filter(point => point.x > Math.min(fromX, toX) && point.x < Math.max(fromX, toX))
    return fromX <= toX ? inner : inner.reverse()
}

function clipAlong(points, line, isKeepingAbove) {
    const sign = isKeepingAbove ? 1 : -1
    const reach = point => sign * (heightOn(line, point.x) - point.y)
    const first = points.findIndex(point => reach(point) >= 0)
    if (first < 0)
        return []
    const kept = []
    let leftX = points[first].x
    for (let step = 1; step <= points.length; step++) {
        const previous = points[(first + step - 1) % points.length]
        const current = points[(first + step) % points.length]
        const previousReach = reach(previous)
        const currentReach = reach(current)
        const isCurrentIn = currentReach >= 0
        if (isCurrentIn !== previousReach >= 0) {
            const share = previousReach / (previousReach - currentReach)
            const crossing = Qt.point(previous.x + (current.x - previous.x) * share, previous.y + (current.y - previous.y) * share)
            if (isCurrentIn)
                kept.push(...pointsBetween(line, leftX, crossing.x))
            else
                leftX = crossing.x
            kept.push(crossing)
        }
        if (isCurrentIn)
            kept.push(current)
    }
    return kept.length >= 3 ? kept : []
}

function splitAlong(points, upper, lower) {
    const isOpen = upper.some((point, index) => lower[index].y > point.y)
    if (points.length < 3 || !isOpen)
        return [points]
    return [clipAlong(points, upper, true), clipAlong(points, lower, false)].filter(piece => piece.length >= 3)
}
