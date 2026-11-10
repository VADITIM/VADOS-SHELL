.pragma library

const glyphs = ["chat", "send", "mail", "music", "bell"]

const generic = { key: "generic", label: "", glyph: "bell", tint: "", ids: [] }

const sources = [
    { key: "discord", label: "Discord", glyph: "chat", tint: "#5865f2", ids: ["discord", "discord-canary", "discord-ptb", "com.discordapp.discord", "vesktop", "dev.vencord.vesktop", "webcord", "io.github.spacingbat3.webcord", "legcord", "armcord"] },
    { key: "telegram", label: "Telegram", glyph: "send", tint: "#2ea6ff", ids: ["telegram", "telegramdesktop", "telegram-desktop", "org.telegram.desktop", "64gram", "materialgram", "ayugram"] },
    { key: "whatsapp", label: "WhatsApp", glyph: "chat", tint: "#25d366", ids: ["whatsapp", "zapzap", "com.rtosta.zapzap", "whatsapp-for-linux", "com.github.eneshecan.whatsappforlinux", "whatsie", "karere"] },
    { key: "signal", label: "Signal", glyph: "chat", tint: "#3a76f0", ids: ["signal", "signal-desktop", "org.signal.signal"] },
    { key: "slack", label: "Slack", glyph: "chat", tint: "#e01e5a", ids: ["slack", "com.slack.slack"] },
    { key: "element", label: "Element", glyph: "chat", tint: "#0dbd8b", ids: ["element", "element-desktop", "im.riot.riot"] },
    { key: "thunderbird", label: "Thunderbird", glyph: "mail", tint: "#0a84ff", ids: ["thunderbird", "org.mozilla.thunderbird", "betterbird", "eu.betterbird.betterbird"] },
    { key: "spotify", label: "Spotify", glyph: "music", tint: "#1db954", ids: ["spotify", "com.spotify.client"] }
]

const entities = { "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&amp;": "&" }
const blanks = " \n\r\t"
const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
const desktopSuffix = ".desktop"
const breaks = ["br", "p", "div", "li"]

function normalize(name) {
    return String(name ?? "").trim().toLowerCase()
}

function namesOf(name) {
    const normalized = normalize(name)
    if (normalized.length === 0)
        return []
    return normalized.endsWith(desktopSuffix) ? [normalized, normalized.slice(0, -desktopSuffix.length)] : [normalized]
}

function wordsOf(name) {
    const words = []
    let word = ""
    for (const character of normalize(name) + " ") {
        if (letters.includes(character)) {
            word += character
            continue
        }
        if (word.length > 0)
            words.push(word)
        word = ""
    }
    return words
}

function identify(appName, desktopEntry) {
    const candidates = namesOf(desktopEntry).concat(namesOf(appName))
    let source = null
    for (const candidate of candidates)
        source = source ?? sources.find(row => row.ids.includes(candidate)) ?? null
    for (const candidate of candidates) {
        const words = wordsOf(candidate)
        source = source ?? sources.find(row => words.includes(row.key)) ?? null
    }
    if (source)
        return source
    return Object.assign({}, generic, { label: String(appName ?? "").trim() })
}

function plainOf(text) {
    let plain = ""
    let tag = null
    for (const character of String(text ?? "")) {
        if (character === "<") {
            tag = ""
        } else if (character === ">" && tag !== null) {
            if (breaks.includes(wordsOf(tag)[0] ?? ""))
                plain += " "
            tag = null
        } else if (tag !== null) {
            tag += character
        } else {
            plain += blanks.includes(character) ? " " : character
        }
    }
    for (const entity in entities)
        plain = plain.split(entity).join(entities[entity])
    return plain.split(" ").filter(part => part.length > 0).join(" ")
}

function clip(text, limit) {
    const plain = plainOf(text)
    if (plain.length <= limit)
        return plain
    let kept = plain.slice(0, Math.max(0, limit - 1))
    while (kept.endsWith(" "))
        kept = kept.slice(0, -1)
    return kept + "…"
}

function leadOf(notifications) {
    return notifications && notifications.length > 0 ? notifications[notifications.length - 1] : null
}
