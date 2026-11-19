.pragma library
.import "Geometry.js" as Geometry

function cutOf(share, width, height, lean, isMirrored) {
    const reach = height * lean
    const top = share * (width + reach)
    const bottom = top - reach
    return isMirrored ? { top: width - top, bottom: width - bottom } : { top: top, bottom: bottom }
}

function bladeOf(cut, width, height, coversLeft) {
    const size = 2 * (width + height)
    const pivotX = (cut.top + cut.bottom) / 2
    return {
        x: coversLeft ? pivotX - size : pivotX,
        y: height / 2 - size / 2,
        size: size,
        pivotX: pivotX,
        pivotY: height / 2,
        originX: coversLeft ? size : 0,
        angle: Math.atan2(cut.top - cut.bottom, height) * 180 / Math.PI
    }
}

function isCoveredAt(cut, height, coversLeft, x, y) {
    const lineX = Geometry.mix(cut.top, cut.bottom, y / height)
    return coversLeft ? x < lineX : x > lineX
}

function pressOf(size, distance, limit) {
    const overlap = Math.min(size * limit, Math.max(0, size / 2 - distance))
    const along = Math.max(1, size - overlap)
    return { along: along, across: size * size / along, distance: overlap > 0 ? along / 2 : distance }
}

function bendOf(from, to, bend) {
    return Qt.point((from.x + to.x) / 2 - (to.y - from.y) * bend, (from.y + to.y) / 2 + (to.x - from.x) * bend)
}

function placedOf(rect, width, isMirrored) {
    return isMirrored ? { x: width - rect.x - rect.width, y: rect.y, width: rect.width, height: rect.height } : { x: rect.x, y: rect.y, width: rect.width, height: rect.height }
}

function anchorOf(rects) {
    if (!rects || rects.length === 0)
        return null
    let left = Infinity
    let right = -Infinity
    let top = Infinity
    let bottom = -Infinity
    for (const rect of rects) {
        left = Math.min(left, rect.x)
        right = Math.max(right, rect.x + rect.width)
        top = Math.min(top, rect.y)
        bottom = Math.max(bottom, rect.y + rect.height)
    }
    return Qt.point((left + right) / 2, (top + bottom) / 2)
}

function groupsOf(groups, width, isMirrored) {
    const kinds = ["tasks", "activity", "system"]
    const found = []
    for (const kind of kinds) {
        const rects = ((groups ?? {})[kind] ?? []).map(rect => placedOf(rect, width, isMirrored))
        if (rects.length > 0)
            found.push({ kind: kind, rects: rects, anchor: anchorOf(rects) })
    }
    return found
}

function departureOf(times, depart) {
    if (times.length === 0)
        return 0
    let total = 0
    for (const time of times)
        total += Geometry.clampUnit(time / depart)
    return total / times.length
}
