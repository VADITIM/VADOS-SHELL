.pragma library

function quoted(value) {
    return "\"" + value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\""
}

function literal(value) {
    if (Array.isArray(value))
        return "[" + value.map(entry => literal(entry)).join(", ") + "]"
    if (typeof value === "number")
        return String(value)
    if (typeof value === "boolean")
        return value ? "true" : "false"
    return quoted(String(value))
}

function isHeader(line) {
    return line.trim().startsWith("[")
}

function keyOf(line) {
    return line.split("=")[0].trim()
}

function valueOf(line) {
    const equals = line.indexOf("=")
    if (equals < 0)
        return ""
    const rest = line.slice(equals + 1).trim()
    if (!rest.startsWith("\""))
        return rest.split("#")[0].trim()
    for (let index = 1; index < rest.length; index++) {
        if (rest[index] === "\\")
            index++
        else if (rest[index] === "\"")
            return rest.slice(0, index + 1)
    }
    return rest
}

function endOf(lines, start) {
    const end = lines.findIndex((line, index) => index > start && isHeader(line))
    return end < 0 ? lines.length : end
}

function withKeys(lines, start, end, entries, isAppending) {
    let added = 0
    let tail = end
    while (isAppending && tail > start + 1 && lines[tail - 1].trim().length === 0)
        tail--
    for (const key of Object.keys(entries)) {
        const written = key + " = " + literal(entries[key])
        let found = -1
        for (let index = start + 1; index < end + added; index++) {
            if (keyOf(lines[index]) === key) {
                found = index
                break
            }
        }
        if (entries[key] === null) {
            if (found >= 0) {
                lines.splice(found, 1)
                added -= 1
            }
            continue
        }
        if (found >= 0) {
            lines[found] = written
            continue
        }
        lines.splice(isAppending ? tail + added : start + 1 + added, 0, written)
        added += 1
    }
    return lines
}

function block(header, entries) {
    return [header].concat(Object.keys(entries).filter(key => entries[key] !== null).map(key => key + " = " + literal(entries[key])))
}

function appended(text, written) {
    const lead = text.length === 0 ? "" : text.endsWith("\n") ? "\n" : "\n\n"
    return text + lead + written.join("\n") + "\n"
}

function withTable(text, table, entries) {
    const lines = text.split("\n")
    const header = "[" + table + "]"
    const start = lines.findIndex(line => line.trim() === header)
    if (start < 0)
        return appended(text, block(header, entries))
    return withKeys(lines, start, endOf(lines, start), entries, false).join("\n")
}

function isSubtable(line, array) {
    return line.trim().startsWith("[" + array + ".")
}

function entryStarts(lines, array) {
    const header = "[[" + array + "]]"
    const starts = []
    lines.forEach((line, index) => {
        if (line.trim() === header)
            starts.push(index)
    })
    return starts
}

function withEntry(text, array, key, value, entries) {
    const lines = text.split("\n")
    const match = literal(value)
    const starts = entryStarts(lines, array)
    const start = starts.find(index => lines.slice(index + 1, endOf(lines, index)).some(line => keyOf(line) === key && valueOf(line) === match))
    if (start !== undefined)
        return withKeys(lines, start, endOf(lines, start), entries, true).join("\n")
    const written = block("[[" + array + "]]", Object.assign({ [key]: value }, entries))
    if (starts.length === 0)
        return appended(text, written)
    let end = endOf(lines, starts[starts.length - 1])
    while (end < lines.length && isSubtable(lines[end], array))
        end = endOf(lines, end)
    while (end > 0 && lines[end - 1].trim().length === 0)
        end--
    lines.splice(end, 0, "", ...written)
    return lines.join("\n")
}
