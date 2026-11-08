.pragma library

function padded(value) {
    return value < 10 ? "0" + value : "" + value
}

function clockOf(time) {
    const date = new Date(time)
    return padded(date.getHours()) + ":" + padded(date.getMinutes()) + ":" + padded(date.getSeconds())
}

function describeCompositor(compositor) {
    const capabilities = compositor.capabilities ?? {}
    const names = Object.keys(capabilities)
    const present = names.filter(name => capabilities[name])
    const missing = names.filter(name => !capabilities[name])
    return [
        "compositor: " + compositor.name + ", level " + compositor.level,
        "  capabilities: " + (present.length > 0 ? present.join(", ") : "none"),
        "  missing: " + (missing.length > 0 ? missing.join(", ") : "none")
    ]
}

function describeOverlays(overlays) {
    const stack = overlays.stack ?? []
    const screens = overlays.screens ?? {}
    const phases = overlays.phases ?? {}
    const lines = ["overlays: " + (stack.length > 0 ? stack.map(key => key + " on " + (screens[key] ?? "?")).join(" < ") : "none open")]
    for (const screenName of Object.keys(phases).sort()) {
        for (const key of Object.keys(phases[screenName]).sort())
            lines.push("  " + screenName + " " + key + ": " + phases[screenName][key])
    }
    return lines
}

function describeSupervisor(supervisor) {
    let line = "  " + supervisor.name + ": " + supervisor.status + ", " + supervisor.restarts + (supervisor.restarts === 1 ? " restart" : " restarts")
    if (supervisor.failures > 0)
        line += ", " + supervisor.failures + " failing in a row"
    if (supervisor.lastFailure.length > 0)
        line += ", last failure: " + supervisor.lastFailure
    return line
}

function describeEntry(entry) {
    const repeats = entry.repeats > 0 ? " (" + (entry.repeats + 1) + " times, last " + clockOf(entry.last) + ")" : ""
    return "  " + clockOf(entry.time) + " " + entry.level + " " + entry.subsystem + ": " + entry.message + repeats
}

function report(compositor, overlays, supervisors, entries) {
    const lines = ["vados diagnostics"]
    lines.push(...describeCompositor(compositor))
    lines.push(...describeOverlays(overlays))
    lines.push("supervised:" + (supervisors.length > 0 ? "" : " none"))
    lines.push(...supervisors.map(describeSupervisor))
    lines.push("log: " + (entries.length > 0 ? entries.length + " recent" : "empty"))
    lines.push(...entries.map(describeEntry))
    return lines.join("\n")
}
