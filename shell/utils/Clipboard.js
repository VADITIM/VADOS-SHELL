.pragma library

const kinds = ["text", "url", "file", "image"]
const imageTypes = { png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", webp: "image/webp", gif: "image/gif", bmp: "image/bmp" }
const textLimit = 20000
const labelLimit = 120
const maskLength = 12
const maskCharacter = "•"
const tokenLength = 24
const passwordLength = 12
const urlPattern = new RegExp("^(https?|ftp)://\\S+$|^www\\.\\S+\\.\\S+$", "i")
const schemePattern = new RegExp("^(https?|ftp)://", "i")
const spacePattern = new RegExp("\\s")
const spacesPattern = new RegExp("\\s+", "g")
const linePattern = new RegExp("\\r?\\n")
const pathStartPattern = new RegExp("^[~/.]")
const digitPattern = new RegExp("[0-9]")
const characterClasses = [new RegExp("[a-z]"), new RegExp("[A-Z]"), digitPattern, new RegExp("[^A-Za-z0-9]")]
const secretPatterns = [
    new RegExp("-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    new RegExp("^eyJ[\\w-]{8,}\\.[\\w-]{8,}\\.[\\w-]{8,}$"),
    new RegExp("\\bAKIA[0-9A-Z]{16}\\b"),
    new RegExp("\\bgh[pousr]_[A-Za-z0-9]{36,}\\b"),
    new RegExp("\\bgithub_pat_[A-Za-z0-9_]{40,}\\b"),
    new RegExp("\\bxox[abprs]-[A-Za-z0-9-]{10,}"),
    new RegExp("\\bsk-[A-Za-z0-9_-]{20,}"),
    new RegExp("\\bAIza[0-9A-Za-z_-]{35}\\b"),
    new RegExp("\\bglpat-[A-Za-z0-9_-]{20,}\\b")
]

function classesOf(text) {
    return characterClasses.filter(pattern => pattern.test(text)).length
}

function isSecret(text) {
    if (typeof text !== "string" || text.length === 0)
        return false
    if (secretPatterns.some(pattern => pattern.test(text)))
        return true
    const word = text.trim()
    if (spacePattern.test(word) || word.includes("://") || pathStartPattern.test(word))
        return false
    if (word.length >= tokenLength && classesOf(word) >= 3 && digitPattern.test(word))
        return true
    return word.length >= passwordLength && classesOf(word) === characterClasses.length
}

function kindOf(raw) {
    if (raw.kind === "image" || raw.kind === "file")
        return raw.kind
    return urlPattern.test((raw.text ?? "").trim()) ? "url" : "text"
}

function keyOf(kind, content) {
    return kind + ":" + content
}

function entryOf(raw, time) {
    if (!raw || typeof raw !== "object" || raw.skip)
        return null
    if (raw.kind === "image") {
        if (typeof raw.path !== "string" || raw.path.length === 0)
            return null
        return { key: keyOf("image", raw.path), kind: "image", text: "", path: raw.path, time: time, isPinned: false, isSecret: false }
    }
    const text = typeof raw.text === "string" ? raw.text.slice(0, textLimit) : ""
    if (text.trim().length === 0)
        return null
    const kind = kindOf({ kind: raw.kind, text: text })
    return { key: keyOf(kind, text), kind: kind, text: text, path: "", time: time, isPinned: false, isSecret: kind === "text" && isSecret(text) }
}

function trim(entries, size) {
    const list = entries || []
    let surplus = list.length - Math.max(0, size)
    if (surplus <= 0)
        return list.slice()
    const kept = []
    for (let index = list.length - 1; index >= 0; index--) {
        if (surplus > 0 && !list[index].isPinned) {
            surplus -= 1
            continue
        }
        kept.unshift(list[index])
    }
    return kept
}

function add(entries, entry, size) {
    if (!entry)
        return (entries || []).slice()
    const before = (entries || []).find(candidate => candidate.key === entry.key)
    const fresh = Object.assign({}, entry, { isPinned: before ? before.isPinned : entry.isPinned })
    return trim([fresh].concat((entries || []).filter(candidate => candidate.key !== entry.key)), size)
}

function merge(fresh, saved, size) {
    const keys = (fresh || []).map(entry => entry.key)
    return trim((fresh || []).concat((saved || []).filter(entry => keys.indexOf(entry.key) < 0)), size)
}

function togglePin(entries, key) {
    return (entries || []).map(entry => entry.key === key ? Object.assign({}, entry, { isPinned: !entry.isPinned }) : entry)
}

function remove(entries, key) {
    return (entries || []).filter(entry => entry.key !== key)
}

function clear(entries) {
    return (entries || []).filter(entry => entry.isPinned)
}

function withoutImages(entries) {
    return (entries || []).filter(entry => entry.kind !== "image")
}

function shown(entries, count) {
    const list = entries || []
    return list.filter(entry => entry.isPinned).concat(list.filter(entry => !entry.isPinned)).slice(0, Math.max(0, count))
}

function storable(entries) {
    return (entries || []).filter(entry => !entry.isSecret)
}

function restore(saved) {
    if (!Array.isArray(saved))
        return []
    return saved.filter(entry => entry && typeof entry === "object"
        && kinds.indexOf(entry.kind) >= 0
        && typeof entry.key === "string"
        && typeof entry.text === "string"
        && !isSecret(entry.text))
        .map(entry => ({
            key: entry.key,
            kind: entry.kind,
            text: entry.text,
            path: typeof entry.path === "string" ? entry.path : "",
            time: Number(entry.time) || 0,
            isPinned: entry.isPinned === true,
            isSecret: false
        }))
}

function imagesOf(entries) {
    return (entries || []).filter(entry => entry.kind === "image").map(entry => entry.path)
}

function droppedImages(before, after) {
    const kept = imagesOf(after)
    return imagesOf(before).filter(path => kept.indexOf(path) < 0)
}

function filesOf(text) {
    return (text || "").split(linePattern)
        .map(line => line.trim())
        .filter(line => line.startsWith("file://"))
        .map(line => {
            const path = line.slice("file://".length)
            try {
                return decodeURIComponent(path)
            } catch (error) {
                return path
            }
        })
}

function nameOf(path) {
    const parts = path.split("/").filter(part => part.length > 0)
    return parts.length > 0 ? parts[parts.length - 1] : path
}

function maskOf(text) {
    return maskCharacter.repeat(Math.min(maskLength, Math.max(1, (text || "").length)))
}

function labelOf(entry) {
    if (entry.isSecret)
        return maskOf(entry.text)
    if (entry.kind === "image")
        return "IMAGE"
    if (entry.kind === "file") {
        const files = filesOf(entry.text)
        if (files.length === 0)
            return entry.text.slice(0, labelLimit)
        return files.length === 1 ? nameOf(files[0]) : nameOf(files[0]) + "  +" + (files.length - 1)
    }
    const flat = entry.text.replace(spacesPattern, " ").trim()
    return (entry.kind === "url" ? flat.replace(schemePattern, "") : flat).slice(0, labelLimit)
}

function mimeOf(entry) {
    if (entry.kind === "file")
        return "text/uri-list"
    if (entry.kind === "image")
        return imageTypes[entry.path.split(".").pop().toLowerCase()] ?? imageTypes.png
    return "text/plain;charset=utf-8"
}
