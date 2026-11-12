.pragma library

function shadeOf(red, green, blue) {
    const highest = Math.max(red, green, blue)
    const lowest = Math.min(red, green, blue)
    const lightness = (highest + lowest) / 2
    const spread = highest - lowest
    const saturation = spread === 0 ? 0 : spread / (1 - Math.abs(2 * lightness - 1))
    let hue = 0
    if (spread > 0 && highest === red)
        hue = ((green - blue) / spread + 6) % 6
    else if (spread > 0 && highest === green)
        hue = (blue - red) / spread + 2
    else if (spread > 0)
        hue = (red - green) / spread + 4
    return { hue: hue / 6, saturation: Math.min(1, saturation), lightness: lightness }
}

function channelOf(low, high, hue) {
    const turn = (hue % 1 + 1) % 1
    if (turn < 1 / 6)
        return low + (high - low) * 6 * turn
    if (turn < 1 / 2)
        return high
    if (turn < 2 / 3)
        return low + (high - low) * (2 / 3 - turn) * 6
    return low
}

function colorOf(shade) {
    const high = shade.lightness < 0.5 ? shade.lightness * (1 + shade.saturation) : shade.lightness + shade.saturation - shade.lightness * shade.saturation
    const low = 2 * shade.lightness - high
    return {
        red: channelOf(low, high, shade.hue + 1 / 3),
        green: channelOf(low, high, shade.hue),
        blue: channelOf(low, high, shade.hue - 1 / 3)
    }
}

function hexOf(color) {
    return "#" + [color.red, color.green, color.blue].map(channel => Math.round(Math.max(0, Math.min(1, channel)) * 255).toString(16).padStart(2, "0")).join("")
}

function dominant(pixels, look) {
    const weights = new Array(look.buckets).fill(0)
    const sums = weights.map(() => ({ red: 0, green: 0, blue: 0 }))
    for (let index = 0; index + 3 < pixels.length; index += 4) {
        const alpha = pixels[index + 3] / 255
        if (alpha < look.alpha)
            continue
        const red = pixels[index] / 255
        const green = pixels[index + 1] / 255
        const blue = pixels[index + 2] / 255
        const shade = shadeOf(red, green, blue)
        if (shade.saturation < look.saturation || shade.lightness < look.darkest || shade.lightness > look.brightest)
            continue
        const bucket = Math.floor(shade.hue * look.buckets) % look.buckets
        const weight = alpha * shade.saturation
        weights[bucket] += weight
        sums[bucket].red += red * weight
        sums[bucket].green += green * weight
        sums[bucket].blue += blue * weight
    }
    const best = weights.indexOf(Math.max(...weights))
    if (weights[best] <= 0)
        return ""
    const average = { red: sums[best].red / weights[best], green: sums[best].green / weights[best], blue: sums[best].blue / weights[best] }
    const shade = shadeOf(average.red, average.green, average.blue)
    shade.lightness = Math.max(look.lightness, shade.lightness)
    return hexOf(colorOf(shade))
}

function nudge(hex, amount) {
    const color = Qt.color(hex)
    const shade = shadeOf(color.r, color.g, color.b)
    shade.lightness = Math.max(0, Math.min(1, shade.lightness + (shade.lightness > 0.5 ? -amount : amount)))
    return hexOf(colorOf(shade))
}
