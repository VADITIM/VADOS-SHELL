.pragma library

const splashPath = "/usr/share/vados/boot/splash.bmp"
const theme = "vados"
const hook = "plymouth"
const words = ["quiet", "splash"]
const hookAnchors = ["kms", "systemd", "udev"]
const mkinitcpioPath = "/etc/mkinitcpio.conf"
const cmdlinePath = "/etc/kernel/cmdline"
const plymouthPath = "/etc/plymouth/plymouthd.conf"

const commentPattern = new RegExp("^\\s*#")
const quotedPattern = new RegExp("^\\s*([\"'])(.*)\\1\\s*$")
const assignmentPattern = new RegExp("^\\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$")
const namePattern = new RegExp("[A-Za-z0-9_-]+", "g")
const splashPattern = new RegExp("(?:^|\\s)--splash(?:=|\\s+)(\\S+)")
const splashOptionPattern = new RegExp("(^|\\s)--splash(?:=|\\s+)\\S+")
const spacePattern = new RegExp("\\s+", "g")
const sectionPattern = new RegExp("^\\s*\\[(.+)\\]\\s*$")
const daemonPattern = new RegExp("^\\s*\\[Daemon\\]\\s*$")
const themeLinePattern = new RegExp("^\\s*Theme=")
const trailingPattern = new RegExp("\\n*$")

function emptyRecord() {
    return { splash: {}, addedWords: [], addedHook: false, theme: "", hasTheme: false }
}

function lines(text) {
    return (text || "").split("\n")
}

function isActive(line) {
    return !commentPattern.test(line)
}

function quoted(value) {
    const match = quotedPattern.exec(value)
    return match ? match[2] : value.trim()
}

function assignment(line) {
    const match = assignmentPattern.exec(line)
    return match && isActive(line) ? { name: match[1], value: match[2] } : null
}

function namesIn(value) {
    return value.match(namePattern) || []
}

function lastAssignment(rows, name) {
    let last = -1
    for (let index = 0; index < rows.length; index++) {
        const found = assignment(rows[index])
        if (found && found.name === name)
            last = index
    }
    return last
}

function valueOf(text, name) {
    const rows = lines(text)
    const index = lastAssignment(rows, name)
    return index >= 0 ? quoted(assignment(rows[index]).value) : null
}

function presetNames(text) {
    const value = valueOf(text, "PRESETS")
    return value === null ? [] : namesIn(value)
}

function ukiPresets(text) {
    return presetNames(text).filter(name => (valueOf(text, name + "_uki") || "").length > 0)
}

function imagesOf(presets) {
    return Object.keys(presets || {}).sort().reduce((found, path) => found.concat(ukiPresets(presets[path]).map(name => valueOf(presets[path], name + "_uki"))), [])
}

function splashIn(options) {
    const match = splashPattern.exec(options || "")
    return match ? match[1] : ""
}

function splashOf(text, name) {
    return splashIn(valueOf(text, name + "_options"))
}

function withSplashIn(options, value) {
    const without = (options || "").replace(splashOptionPattern, "").replace(spacePattern, " ").trim()
    if (value.length === 0)
        return without
    return without.length > 0 ? `--splash ${value} ${without}` : `--splash ${value}`
}

function withSplash(text, name, value) {
    const key = name + "_options"
    const rows = lines(text)
    const last = lastAssignment(rows, key)
    if (last >= 0) {
        rows[last] = `${key}="${withSplashIn(quoted(assignment(rows[last]).value), value)}"`
        return rows.join("\n")
    }
    if (value.length === 0)
        return text
    rows.splice(lastAssignment(rows, name + "_uki") + 1, 0, `${key}="--splash ${value}"`)
    return rows.join("\n")
}

function isSplashOn(presets) {
    const found = Object.keys(presets || {}).reduce((all, path) => all.concat(ukiPresets(presets[path]).map(name => splashOf(presets[path], name))), [])
    return found.length > 0 && found.every(value => value === splashPath)
}

function hooksOf(text) {
    const value = valueOf(text, "HOOKS")
    return value === null ? [] : namesIn(value)
}

function withHooks(text, hooks) {
    const rows = lines(text)
    const last = lastAssignment(rows, "HOOKS")
    const line = `HOOKS=(${hooks.join(" ")})`
    if (last >= 0)
        rows[last] = line
    else
        rows.push(line)
    return rows.join("\n")
}

function withHook(text, isOn) {
    const hooks = hooksOf(text).filter(name => name !== hook)
    if (!isOn)
        return withHooks(text, hooks)
    const anchor = hookAnchors.map(name => hooks.indexOf(name)).find(index => index >= 0)
    hooks.splice(anchor === undefined ? 0 : anchor + 1, 0, hook)
    return withHooks(text, hooks)
}

function wordsOf(text) {
    return (text || "").trim().split(spacePattern).filter(word => word.length > 0)
}

function withWords(text, added, removed) {
    const kept = wordsOf(text).filter(word => removed.indexOf(word) < 0)
    return kept.concat(added.filter(word => kept.indexOf(word) < 0)).join(" ") + "\n"
}

function themeOf(text) {
    let section = ""
    let value = ""
    for (const line of lines(text)) {
        const header = sectionPattern.exec(line)
        if (header) {
            section = header[1]
            continue
        }
        const found = assignment(line)
        if (section === "Daemon" && found && found.name === "Theme")
            value = found.value.trim()
    }
    return value
}

function withTheme(text, value) {
    const rows = lines(text).filter(line => !(isActive(line) && themeLinePattern.test(line)))
    if (value.length === 0)
        return rows.join("\n")
    const header = rows.findIndex(line => daemonPattern.test(line))
    if (header < 0) {
        const body = rows.join("\n").replace(trailingPattern, "")
        return (body.length > 0 ? body + "\n\n" : "") + `[Daemon]\nTheme=${value}\n`
    }
    rows.splice(header + 1, 0, `Theme=${value}`)
    return rows.join("\n")
}

function isPlymouthOn(current) {
    return hooksOf(current.mkinitcpio).indexOf(hook) >= 0 && wordsOf(current.cmdline).indexOf("splash") >= 0 && themeOf(current.plymouth) === theme
}

function canSplash(current) {
    return current.hasMkinitcpio === true && imagesOf(current.presets).length > 0
}

function canPlymouth(current) {
    return canSplash(current) && current.hasPlymouth === true && typeof current.cmdline === "string"
}

function planSplash(current, next, isWanted, files) {
    if (isWanted === isSplashOn(current.presets))
        return
    for (const path of Object.keys(current.presets || {}).sort()) {
        let text = current.presets[path]
        for (const name of ukiPresets(text)) {
            const key = `${path}:${name}`
            if (isWanted) {
                const before = splashOf(text, name)
                if (before !== splashPath)
                    next.splash[key] = before
                text = withSplash(text, name, splashPath)
            } else {
                text = withSplash(text, name, next.splash[key] || "")
                delete next.splash[key]
            }
        }
        if (text !== current.presets[path])
            files[path] = text
    }
}

function planPlymouth(current, next, isWanted, files) {
    if (isWanted === isPlymouthOn(current))
        return
    let mkinitcpio = current.mkinitcpio
    let cmdline = current.cmdline
    let plymouth = current.plymouth || ""
    if (isWanted) {
        const present = wordsOf(cmdline)
        next.addedHook = next.addedHook || hooksOf(mkinitcpio).indexOf(hook) < 0
        next.addedWords = next.addedWords.concat(words.filter(word => present.indexOf(word) < 0 && next.addedWords.indexOf(word) < 0))
        if (themeOf(plymouth) !== theme) {
            next.theme = themeOf(plymouth)
            next.hasTheme = true
        }
        mkinitcpio = withHook(mkinitcpio, true)
        cmdline = withWords(cmdline, words, [])
        plymouth = withTheme(plymouth, theme)
    } else {
        if (next.addedHook)
            mkinitcpio = withHook(mkinitcpio, false)
        cmdline = withWords(cmdline, [], next.addedWords)
        plymouth = withTheme(plymouth, next.hasTheme ? next.theme : "")
        next.addedHook = false
        next.addedWords = []
        next.theme = ""
        next.hasTheme = false
    }
    if (mkinitcpio !== current.mkinitcpio)
        files[mkinitcpioPath] = mkinitcpio
    if (cmdline !== current.cmdline)
        files[cmdlinePath] = cmdline
    if (plymouth !== (current.plymouth || ""))
        files[plymouthPath] = plymouth
}

function plan(current, record, wanted) {
    const next = Object.assign(emptyRecord(), JSON.parse(JSON.stringify(record || {})))
    const files = {}
    planSplash(current, next, wanted.splash, files)
    planPlymouth(current, next, wanted.plymouth, files)
    return { files: files, record: next, images: imagesOf(current.presets) }
}
