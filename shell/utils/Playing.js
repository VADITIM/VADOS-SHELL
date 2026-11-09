.pragma library

const sources = []

function enlist(source) {
    if (sources.indexOf(source) < 0)
        sources.push(source)
}

function delist(source) {
    const at = sources.indexOf(source)
    if (at >= 0)
        sources.splice(at, 1)
}

function names() {
    const counts = {}
    const order = []
    for (const source of sources) {
        const name = source.playing ?? ""
        if (name.length === 0)
            continue
        if (!counts[name])
            order.push(name)
        counts[name] = (counts[name] ?? 0) + 1
    }
    return order.map(name => counts[name] > 1 ? name + " x" + counts[name] : name)
}
