.pragma library

.import "Toml.js" as Toml

const everyKeyboard = "*"
const separator = "|"
const entryPattern = new RegExp("^(\\S+)\\s+(.*)$")
const describedPattern = new RegExp("^(\\S+):\\s*(.*)$")
const spacePattern = new RegExp("\\s+", "g")
const namePattern = new RegExp("^[A-Za-z0-9_+.-]*$")
const unsafePattern = new RegExp("[\\n{}=;#]")
const quotePattern = new RegExp("^\"|\"$", "g")
const blockPattern = new RegExp("\\n\\s*\\n")
const devicePattern = new RegExp("^N: Name=\"(.*)\"$", "m")
const handlerPattern = new RegExp("^H: Handlers=(.*)$", "m")
const eventPattern = new RegExp("^B: EV=([0-9a-f]+)$", "m")
const busPattern = new RegExp("^I: Bus=([0-9a-f]+)", "m")
const keyboardHandlerPattern = new RegExp("\\bkbd\\b")
const keyEvents = 0x2
const repeatEvents = 0x100000
const builtInBus = "0011"
const builtInName = "AT Translated Set 2"

function parseRules(text) {
    const layouts = []
    const variants = []
    let section = ""
    for (const raw of String(text ?? "").split("\n")) {
        const line = raw.trim()
        if (line.startsWith("!")) {
            section = line.slice(1).trim()
            continue
        }
        const found = line.match(entryPattern)
        if (!found)
            continue
        if (section === "layout") {
            layouts.push({ layout: found[1], variant: "", description: found[2].trim() })
        } else if (section === "variant") {
            const described = found[2].match(describedPattern)
            if (described)
                variants.push({ layout: described[1], variant: found[1], description: described[2].trim() })
        }
    }
    const choices = []
    for (const layout of layouts) {
        choices.push(layout)
        for (const variant of variants)
            if (variant.layout === layout.layout)
                choices.push(variant)
    }
    return choices
}

function keyOf(choice) {
    return choice.variant.length > 0 ? choice.layout + "(" + choice.variant + ")" : choice.layout
}

function matches(choice, query) {
    const needle = String(query ?? "").trim().toLowerCase()
    if (needle.length === 0)
        return true
    return keyOf(choice).toLowerCase().includes(needle) || choice.description.toLowerCase().includes(needle)
}

function encode(override) {
    return [override.device, override.layout, override.variant ?? ""].join(separator)
}

function decode(entry) {
    const parts = String(entry).split(separator)
    if (parts.length < 2 || parts[0].length === 0 || parts[1].length === 0)
        return null
    return { device: parts[0], layout: parts[1], variant: parts[2] ?? "" }
}

function overridesOf(entries) {
    return Array.from(entries ?? []).map(decode).filter(override => override !== null)
}

function withOverride(entries, override) {
    const kept = overridesOf(entries).filter(entry => entry.device !== override.device)
    if (override.layout.length > 0)
        kept.push(override)
    return kept.map(encode)
}

function overrideFor(entries, device) {
    return overridesOf(entries).find(entry => entry.device === device) ?? null
}

function hyprlandName(name) {
    return String(name).trim().toLowerCase().replace(spacePattern, "-")
}

function isSafe(override) {
    return override.layout.length > 0 && namePattern.test(override.layout) && namePattern.test(override.variant) && !unsafePattern.test(override.device)
}

function hyprlandConfig(entries) {
    const lines = []
    for (const override of overridesOf(entries).filter(isSafe)) {
        if (override.device === everyKeyboard)
            lines.push("input {", "    kb_layout = " + override.layout, "    kb_variant = " + override.variant, "}", "")
        else
            lines.push("device {", "    name = " + hyprlandName(override.device), "    kb_layout = " + override.layout, "    kb_variant = " + override.variant, "}", "")
    }
    return lines.join("\n")
}

function driftwmLayout(text) {
    const lines = String(text ?? "").split("\n")
    const start = lines.findIndex(line => line.trim() === "[input.keyboard]")
    const found = { layout: "", variant: "" }
    if (start < 0)
        return found
    for (let index = start + 1; index < lines.length && !Toml.isHeader(lines[index]); index++) {
        const key = Toml.keyOf(lines[index])
        if (key === "layout" || key === "variant")
            found[key] = Toml.valueOf(lines[index]).replace(quotePattern, "")
    }
    return found
}

function driftwmText(text, entries, previous) {
    const override = overrideFor(entries, everyKeyboard)
    const chosen = override !== null && isSafe(override) ? override : previous
    if (!chosen || chosen.layout.length === 0)
        return text
    return Toml.withTable(text, "input.keyboard", { layout: chosen.layout, variant: chosen.variant ?? "" })
}

function parseDevices(text) {
    const devices = []
    for (const block of String(text ?? "").split(blockPattern)) {
        const name = (block.match(devicePattern) ?? [])[1]
        const handlers = (block.match(handlerPattern) ?? [])[1] ?? ""
        const events = parseInt((block.match(eventPattern) ?? [])[1] ?? "0", 16)
        const bus = (block.match(busPattern) ?? [])[1] ?? ""
        if (!name || !keyboardHandlerPattern.test(handlers) || (events & keyEvents) === 0 || (events & repeatEvents) === 0)
            continue
        if (devices.some(device => device.name === name))
            continue
        devices.push({ name: name, isBuiltIn: bus === builtInBus || name.includes(builtInName) })
    }
    return devices.sort((first, second) => (second.isBuiltIn ? 1 : 0) - (first.isBuiltIn ? 1 : 0))
}
