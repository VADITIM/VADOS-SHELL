.pragma library

const germanCodes = [196, 214, 220, 228, 246, 252, 223]

function parse(text) {
    const lines = (text ?? "").split("\n").map(line => line.replace(/\r$/, ""))
    const header = (lines[0] ?? "").split(" ")
    if (!header[0] || !header[0].startsWith("flf2a"))
        return null
    const hardBlank = header[0].charAt(5)
    const height = parseInt(header[1])
    const commentLines = parseInt(header[5])
    if (!(height > 0) || !(commentLines >= 0))
        return null
    const glyphs = {}
    let cursor = 1 + commentLines

    function readGlyph() {
        if (cursor + height > lines.length)
            return null
        const rows = lines.slice(cursor, cursor + height).map(row => {
            const endMark = row.charAt(row.length - 1)
            let end = row.length
            while (end > 0 && row.charAt(end - 1) === endMark)
                end--
            return row.slice(0, end)
        })
        cursor += height
        return rows
    }

    const codes = []
    for (let code = 32; code <= 126; code++)
        codes.push(code)
    for (const code of codes.concat(germanCodes)) {
        const rows = readGlyph()
        if (!rows)
            return { hardBlank: hardBlank, height: height, glyphs: glyphs }
        glyphs[code] = rows
    }
    while (cursor < lines.length) {
        const tag = lines[cursor].trim().split(/\s+/)[0]
        cursor++
        if (!tag)
            continue
        const code = tag.toLowerCase().startsWith("0x") ? parseInt(tag, 16) : tag.startsWith("0") && tag.length > 1 ? parseInt(tag, 8) : parseInt(tag, 10)
        const rows = readGlyph()
        if (!rows)
            break
        if (!isNaN(code) && code >= 0)
            glyphs[code] = rows
    }
    return { hardBlank: hardBlank, height: height, glyphs: glyphs }
}

function leadingOf(row) {
    let count = 0
    while (count < row.length && row.charAt(count) === " ")
        count++
    return count
}

function trailingOf(row) {
    let count = 0
    while (count < row.length && row.charAt(row.length - 1 - count) === " ")
        count++
    return count
}

function render(font, text) {
    if (!font)
        return ""
    let rows = []
    for (let index = 0; index < font.height; index++)
        rows.push("")
    for (const character of text ?? "") {
        const glyph = font.glyphs[character.codePointAt(0)]
        if (!glyph)
            continue
        const widest = Math.max(...rows.map(row => row.length))
        rows = rows.map(row => row + " ".repeat(widest - row.length))
        let overlap = Infinity
        for (let index = 0; index < font.height; index++) {
            const piece = glyph[index] ?? ""
            const room = trailingOf(rows[index]) + (piece.length > 0 ? leadingOf(piece) : Infinity)
            overlap = Math.min(overlap, room)
        }
        overlap = Math.max(0, Math.min(isFinite(overlap) ? overlap : 0, widest))
        rows = rows.map((row, index) => {
            const piece = glyph[index] ?? ""
            const shared = Math.min(overlap, piece.length)
            let merged = row.slice(0, row.length - overlap)
            for (let step = 0; step < overlap; step++) {
                const before = row.charAt(row.length - overlap + step)
                const after = step < shared ? piece.charAt(step) : " "
                merged += before === " " ? after : before
            }
            return merged + piece.slice(shared)
        })
    }
    const blank = new RegExp(font.hardBlank.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "g")
    rows = rows.map(row => row.replace(blank, " ").replace(/\s+$/, ""))
    while (rows.length > 0 && rows[0].trim().length === 0)
        rows.shift()
    while (rows.length > 0 && rows[rows.length - 1].trim().length === 0)
        rows.pop()
    return rows.join("\n")
}
