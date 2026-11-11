.pragma library
.import "Geometry.js" as Geometry

const tools = [
    { key: "select", glyph: "pointer", label: "SELECT" },
    { key: "color", glyph: "drop", label: "COLOR" },
    { key: "paint", glyph: "pen", label: "PAINT" },
    { key: "erase", glyph: "eraser", label: "ERASE" },
    { key: "shape", glyph: "shape-box", label: "SHAPE" },
    { key: "text", glyph: "text", label: "TEXT" }
]

const shapes = [
    { key: "box", glyph: "shape-box" },
    { key: "circle", glyph: "shape-circle" },
    { key: "line", glyph: "shape-line" },
    { key: "arrow", glyph: "shape-arrow" }
]

const drawingTools = ["paint", "shape"]
const circleSteps = 48
const arrowSpread = 0.5
const arrowShare = 4
const textAdvance = 0.62
const textLeading = 1.5

function toolOf(key) {
    return tools.find(tool => tool.key === key) ?? tools[0]
}

function shapeOf(key) {
    return shapes.find(shape => shape.key === key) ?? shapes[0]
}

function nextOf(list, key, direction) {
    const at = Math.max(0, list.findIndex(entry => entry.key === key))
    return list[(at + direction + list.length) % list.length].key
}

function isDrawing(tool) {
    return drawingTools.indexOf(tool) >= 0
}

function pointOf(point) {
    return { x: point.x, y: point.y }
}

function rectOf(from, to) {
    return {
        x: Math.min(from.x, to.x),
        y: Math.min(from.y, to.y),
        width: Math.abs(to.x - from.x),
        height: Math.abs(to.y - from.y)
    }
}

function isUsable(rect, smallest) {
    return rect !== null && rect.width >= smallest && rect.height >= smallest
}

function contains(rect, point) {
    return rect !== null && point.x >= rect.x && point.x <= rect.x + rect.width && point.y >= rect.y && point.y <= rect.y + rect.height
}

function clampInto(rect, bounds) {
    const width = Math.min(rect.width, bounds.width)
    const height = Math.min(rect.height, bounds.height)
    return {
        x: Math.max(bounds.x, Math.min(bounds.x + bounds.width - width, rect.x)),
        y: Math.max(bounds.y, Math.min(bounds.y + bounds.height - height, rect.y)),
        width: width,
        height: height
    }
}

function moved(rect, travelX, travelY, bounds) {
    return clampInto({ x: rect.x + travelX, y: rect.y + travelY, width: rect.width, height: rect.height }, bounds)
}

function centeredAt(rect, point, bounds) {
    return clampInto({ x: point.x - rect.width / 2, y: point.y - rect.height / 2, width: rect.width, height: rect.height }, bounds)
}

function cornersOfRect(rect) {
    return [
        { x: rect.x, y: rect.y },
        { x: rect.x + rect.width, y: rect.y },
        { x: rect.x + rect.width, y: rect.y + rect.height },
        { x: rect.x, y: rect.y + rect.height }
    ]
}

function cornerAt(corners, point, reach) {
    let nearest = -1
    let nearestDistance = reach
    corners.forEach((corner, index) => {
        const distance = Math.hypot(point.x - corner.x, point.y - corner.y)
        if (distance <= nearestDistance) {
            nearest = index
            nearestDistance = distance
        }
    })
    return nearest
}

function resized(rect, corner, point, bounds) {
    const opposite = cornersOfRect(rect)[(corner + 2) % 4]
    const reach = { x: Math.max(bounds.x, Math.min(bounds.x + bounds.width, point.x)), y: Math.max(bounds.y, Math.min(bounds.y + bounds.height, point.y)) }
    return rectOf(opposite, reach)
}

function isShape(stroke) {
    return stroke.kind !== "paint" && stroke.kind !== "text"
}

function isText(stroke) {
    return stroke.kind === "text"
}

function isMovable(stroke) {
    return stroke.kind !== "paint"
}

function textOf(color, size, point) {
    return { kind: "text", color: color, width: size, points: [point], text: "" }
}

function withText(stroke, text) {
    return Object.assign({}, stroke, { text: text })
}

function textRectOf(stroke) {
    const rows = stroke.text.split("\n")
    const longest = rows.reduce((most, row) => Math.max(most, row.length), 1)
    return { x: stroke.points[0].x, y: stroke.points[0].y, width: longest * stroke.width * textAdvance, height: rows.length * stroke.width * textLeading }
}

function textAt(strokes, point, reach) {
    for (let index = strokes.length - 1; index >= 0; index--) {
        if (isText(strokes[index]) && isHit(strokes[index], point, reach))
            return index
    }
    return -1
}

function removed(strokes, index) {
    return strokes.filter((entry, at) => at !== index)
}

function isEndpointShape(stroke) {
    return stroke.kind === "line" || stroke.kind === "arrow"
}

function cornersOf(stroke) {
    const from = stroke.points[0]
    const to = stroke.points[stroke.points.length - 1]
    if (isEndpointShape(stroke))
        return [from, to]
    return cornersOfRect(rectOf(from, to))
}

function grabOf(strokes, point, reach) {
    for (let index = strokes.length - 1; index >= 0; index--) {
        if (!isShape(strokes[index]))
            continue
        const corner = cornerAt(cornersOf(strokes[index]), point, reach)
        if (corner >= 0)
            return { index: index, corner: corner }
    }
    return null
}

function reshaped(stroke, corner, point) {
    const corners = cornersOf(stroke)
    if (isEndpointShape(stroke))
        return Object.assign({}, stroke, { points: corner === 0 ? [point, corners[1]] : [corners[0], point] })
    return Object.assign({}, stroke, { points: [corners[(corner + 2) % 4], point] })
}

function shapeAt(strokes, point, reach) {
    for (let index = strokes.length - 1; index >= 0; index--) {
        if (isMovable(strokes[index]) && isHit(strokes[index], point, reach))
            return index
    }
    return -1
}

function shifted(stroke, travelX, travelY) {
    return Object.assign({}, stroke, { points: stroke.points.map(point => ({ x: point.x + travelX, y: point.y + travelY })) })
}

function replaced(strokes, index, stroke) {
    return strokes.map((entry, at) => at === index ? stroke : entry)
}

function handlesOf(strokes) {
    const handles = []
    strokes.forEach(stroke => {
        if (isShape(stroke))
            cornersOf(stroke).forEach(corner => handles.push(corner))
    })
    return handles
}

function strokeOf(kind, color, width, point) {
    return { kind: kind, color: color, width: width, points: [point, point] }
}

function extended(stroke, point) {
    if (stroke.kind === "paint")
        return Object.assign({}, stroke, { points: stroke.points.concat([point]) })
    return Object.assign({}, stroke, { points: [stroke.points[0], point] })
}

function ellipseOf(from, to) {
    const centerX = (from.x + to.x) / 2
    const centerY = (from.y + to.y) / 2
    const radiusX = Math.abs(to.x - from.x) / 2
    const radiusY = Math.abs(to.y - from.y) / 2
    const points = []
    for (let step = 0; step <= circleSteps; step++) {
        const angle = Math.PI * 2 * step / circleSteps
        points.push({ x: centerX + Math.cos(angle) * radiusX, y: centerY + Math.sin(angle) * radiusY })
    }
    return points
}

function headOf(from, to, width) {
    const length = Math.hypot(to.x - from.x, to.y - from.y)
    if (length < 1)
        return []
    const size = Math.min(length / 2, width * arrowShare + width * 2)
    const angle = Math.atan2(to.y - from.y, to.x - from.x)
    const wing = side => ({ x: to.x - Math.cos(angle + side * arrowSpread) * size, y: to.y - Math.sin(angle + side * arrowSpread) * size })
    return [wing(1), to, wing(-1)]
}

function linesOf(stroke) {
    const from = stroke.points[0]
    const to = stroke.points[stroke.points.length - 1]
    if (isText(stroke))
        return []
    if (stroke.kind === "paint" || stroke.kind === "line")
        return [stroke.kind === "paint" ? stroke.points : [from, to]]
    if (stroke.kind === "arrow")
        return [[from, to], headOf(from, to, stroke.width)]
    if (stroke.kind === "circle")
        return [ellipseOf(from, to)]
    const box = rectOf(from, to)
    return [[
        { x: box.x, y: box.y },
        { x: box.x + box.width, y: box.y },
        { x: box.x + box.width, y: box.y + box.height },
        { x: box.x, y: box.y + box.height },
        { x: box.x, y: box.y }
    ]]
}

function distanceToSegment(point, from, to) {
    const spanX = to.x - from.x
    const spanY = to.y - from.y
    const lengthSquared = spanX * spanX + spanY * spanY
    const share = lengthSquared === 0 ? 0 : Geometry.clampUnit(((point.x - from.x) * spanX + (point.y - from.y) * spanY) / lengthSquared)
    return Math.hypot(point.x - (from.x + spanX * share), point.y - (from.y + spanY * share))
}

function isHit(stroke, point, reach) {
    if (isText(stroke)) {
        const box = textRectOf(stroke)
        return contains({ x: box.x - reach, y: box.y - reach, width: box.width + reach * 2, height: box.height + reach * 2 }, point)
    }
    const limit = reach + stroke.width / 2
    for (const line of linesOf(stroke)) {
        if (line.length === 1 && Math.hypot(point.x - line[0].x, point.y - line[0].y) <= limit)
            return true
        for (let at = 1; at < line.length; at++) {
            if (distanceToSegment(point, line[at - 1], line[at]) <= limit)
                return true
        }
    }
    return false
}

function erased(strokes, point, reach) {
    return strokes.filter(stroke => !isHit(stroke, point, reach))
}

function undone(strokes) {
    return strokes.slice(0, -1)
}
