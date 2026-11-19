.pragma library

function spanOf(count, stagger, spin) {
    return count > 0 ? (count - 1) * stagger + spin : 0
}

function phaseAt(index, elapsed, timing) {
    const local = (elapsed - index * timing.stagger) / timing.spin
    if (local <= 0)
        return { isVisible: false, isResolved: false, rotation: 0, step: 0 }
    if (local >= 1)
        return { isVisible: true, isResolved: true, rotation: 0, step: 0 }
    const eased = 1 - Math.pow(1 - local, 3)
    return {
        isVisible: true,
        isResolved: local >= timing.settle,
        rotation: (1 - eased) * timing.turns * 360,
        step: Math.floor(local / timing.settle * timing.cycles)
    }
}

const settled = -1e9

function phaseOf(start, elapsed, timing) {
    return phaseAt(0, elapsed - start, timing)
}

function startsFor(starts, length, from, now, stagger) {
    const placed = []
    for (let index = 0; index < length; index++)
        placed.push(index < from ? (starts[index] ?? settled) : now + (index - from) * stagger)
    return placed
}

function settle(starts) {
    return starts.map(() => settled)
}

function endOf(starts, spin) {
    return starts.reduce((end, start) => Math.max(end, start + spin), 0)
}

function firstDifference(previous, next) {
    const shared = Math.min(previous.length, next.length)
    for (let index = 0; index < shared; index++) {
        if (previous.charAt(index) !== next.charAt(index))
            return index
    }
    return shared
}

function symbolAt(symbols, index, step) {
    if (symbols.length === 0)
        return ""
    return symbols.charAt((index * 7 + step * 3) % symbols.length)
}

function characterAt(target, symbols, index, phase) {
    const actual = target.charAt(index)
    if (actual === " " || !phase.isVisible)
        return ""
    return phase.isResolved ? actual : symbolAt(symbols, index, phase.step)
}
