.pragma library
.import "Lock.js" as Lock
.import "Placement.js" as Placement
.import "Schema.js" as Schema

const failures = {
    failed: "WRONG PASSWORD",
    maxTries: "TOO MANY ATTEMPTS, WAIT AND TRY AGAIN",
    error: "AUTHENTICATION FAILED",
    startFailed: "AUTHENTICATION COULD NOT START",
    timedOut: "AUTHENTICATION TIMED OUT"
}

function sessionKey(bootId, sessionId) {
    const boot = String(bootId ?? "").trim()
    const session = String(sessionId ?? "").trim()
    return boot.length > 0 && session.length > 0 ? boot + ":" + session : ""
}

function shouldRecover(marker, key) {
    return typeof key === "string" && key.length > 0 && marker !== null && typeof marker === "object"
        && marker.isLocked === true && marker.session === key
}

function failureOf(kind) {
    return failures[kind] ?? failures.error
}

function typeInto(draft, key, text, modifiers) {
    if (key === Qt.Key_Return || key === Qt.Key_Enter)
        return { draft: "", password: draft }
    if (key === Qt.Key_Escape || (key === Qt.Key_Backspace && (modifiers & Qt.ControlModifier)))
        return { draft: "", password: "" }
    if (key === Qt.Key_Backspace)
        return { draft: draft.slice(0, -1), password: "" }
    if (text.length > 0 && text.charCodeAt(0) >= 32 && !(modifiers & (Qt.ControlModifier | Qt.MetaModifier)))
        return { draft: draft + text, password: "" }
    return { draft: draft, password: "" }
}

function fileOf(key) {
    return key.length === 0 ? "" : key.charAt(0).toUpperCase() + key.slice(1) + "Module.qml"
}

function mainScreenOf(screenNames, wanted) {
    if (screenNames.indexOf(wanted) >= 0)
        return wanted
    return screenNames.length > 0 ? screenNames[0] : ""
}

function layoutOf(entries) {
    const settled = Placement.settle(entries, Lock.modules, Lock.grid)
    const homes = Lock.parse(Schema.settings["lock.layout"].fallback)
    for (const module of Lock.modules) {
        if (!module.isCore || settled.some(placement => placement.key === module.key))
            continue
        const home = homes.find(placement => placement.key === module.key) ?? { column: 0, row: 0 }
        const spot = Placement.nearestFree(settled, Lock.grid, module, home.column, home.row, "") ?? home
        settled.push({ key: module.key, column: spot.column, row: spot.row, columns: module.columns, rows: module.rows })
    }
    return settled
}

function rectOf(placement, width, height, gap) {
    const cellWidth = width / Lock.columns
    const cellHeight = height / Lock.rows
    return {
        x: placement.column * cellWidth + gap / 2,
        y: placement.row * cellHeight + gap / 2,
        width: Math.max(0, placement.columns * cellWidth - gap),
        height: Math.max(0, placement.rows * cellHeight - gap)
    }
}

function delays(count, stagger, random) {
    const order = Array.from({ length: count }, (_, index) => index)
    for (let index = count - 1; index > 0; index--) {
        const other = Math.floor(random() * (index + 1))
        const kept = order[index]
        order[index] = order[other]
        order[other] = kept
    }
    const result = new Array(count)
    order.forEach((moduleIndex, slot) => result[moduleIndex] = slot * stagger)
    return result
}
