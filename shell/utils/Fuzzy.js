.pragma library


function isBoundary(text, index) {
    if (index === 0)
        return true
    const before = text[index - 1]
    if (before === " " || before === "-" || before === "_" || before === "." || before === "/")
        return true
    const here = text[index]
    return here !== here.toLowerCase() && before === before.toLowerCase()
}

function match(query, loose, text) {
    if (!text || query.length === 0)
        return -1
    const lower = text.toLowerCase()
    const at = lower.indexOf(query)
    if (at === 0)
        return 1000 - text.length
    if (at > 0)
        return (isBoundary(text, at) ? 820 : 640) - at * 2 - text.length * 0.5
    let score = 0
    let from = 0
    let previous = -2
    let scattered = 0
    for (const character of loose) {
        const found = lower.indexOf(character, from)
        if (found < 0)
            return -1
        if (found === previous + 1)
            score += 18
        else if (isBoundary(text, found))
            score += 14
        else {
            score -= Math.min(10, found - from)
            scattered++
        }
        previous = found
        from = found + 1
    }
    if (scattered > Math.ceil(loose.length / 2))
        return -1
    return 300 + score - text.length * 0.5
}

function frecency(use, now) {
    if (!use)
        return 0
    const hours = Math.max(0, (now - use.last) / 3600000)
    return Math.log2(1 + use.count) * Math.pow(0.5, hours / 168)
}

function rank(apps, query, usage, now) {
    const trimmed = query.trim().toLowerCase()
    const loose = trimmed.replace(/\s+/g, "")
    const used = usage || {}
    const found = []
    for (const app of apps) {
        const fields = [[app.name, 1], [app.genericName, 0.75], [app.keywords, 0.6], [app.id, 0.55]]
        let best = -1
        for (const field of fields) {
            const score = match(trimmed, loose, field[0])
            if (score >= 0)
                best = Math.max(best, score * field[1])
        }
        if (best >= 0)
            found.push({ app: app, score: best + 45 * frecency(used[app.id], now) })
    }
    found.sort((first, second) => second.score - first.score || first.app.name.localeCompare(second.app.name))
    return found.map(entry => entry.app)
}

function recent(apps, usage) {
    const used = usage || {}
    const launched = apps.filter(app => used[app.id]).sort((first, second) => used[second.id].last - used[first.id].last)
    return launched.concat(apps.filter(app => !used[app.id]))
}
