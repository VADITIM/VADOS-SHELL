.pragma library

const pills = ["usb", "audio", "network", "battery", "settings", "power"]
const fold = "fold"
const keys = ["usb", "audio", "network", "battery", fold, "settings", "power"]
const foldFromEnd = 2

function normalise(order) {
    const wanted = Array.isArray(order) ? order : []
    const result = []
    for (const key of wanted) {
        if (keys.indexOf(key) >= 0 && result.indexOf(key) < 0)
            result.push(key)
    }
    for (const key of pills) {
        if (result.indexOf(key) < 0)
            result.push(key)
    }
    if (result.indexOf(fold) < 0)
        result.splice(Math.max(0, result.length - foldFromEnd), 0, fold)
    return result
}

function move(order, key, target) {
    const result = normalise(order)
    const from = result.indexOf(key)
    if (from < 0)
        return result
    const to = Math.max(0, Math.min(result.length - 1, target))
    result.splice(from, 1)
    result.splice(to, 0, key)
    return result
}

function rankOf(order, key) {
    return normalise(order).indexOf(key)
}

function isKeptCompact(order, key) {
    const result = normalise(order)
    return result.indexOf(key) > result.indexOf(fold)
}

function keyAt(order, heights, offset) {
    const result = normalise(order)
    let top = 0
    for (const key of result) {
        top += heights[key] ?? 0
        if (offset < top)
            return key
    }
    return result[result.length - 1]
}

function slotFor(order, key, center, heights) {
    const others = normalise(order).filter(entry => entry !== key)
    let top = 0
    for (let index = 0; index < others.length; index++) {
        const height = heights[others[index]] ?? 0
        if (center < top + height / 2)
            return index
        top += height
    }
    return others.length
}

function offsetsFor(order, heights) {
    const offsets = {}
    let top = 0
    for (const key of normalise(order)) {
        offsets[key] = top
        top += heights[key] ?? 0
    }
    offsets.total = top
    return offsets
}
