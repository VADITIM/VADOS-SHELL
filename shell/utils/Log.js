.pragma library

var capacity = 100
var repeatWindow = 300000

var entries = []
var latest = ({})

function format(subsystem, message) {
    return "vados: " + subsystem + ": " + message
}

function emitLine(level, line) {
    if (level === "error")
        console.error(line)
    else if (level === "warn")
        console.warn(line)
    else
        console.info(line)
}

function forget(now) {
    const keys = Object.keys(latest)
    if (keys.length <= capacity)
        return
    for (const key of keys) {
        if (now - latest[key].time >= repeatWindow)
            delete latest[key]
    }
}

function write(level, subsystem, message, now) {
    const time = now === undefined ? Date.now() : now
    const key = level + "|" + subsystem + "|" + message
    const known = latest[key]
    if (known && time - known.time < repeatWindow) {
        known.repeats += 1
        known.last = time
        return false
    }
    const suffix = known && known.repeats > 0 ? " (repeated " + known.repeats + " more times)" : ""
    emitLine(level, format(subsystem, message) + suffix)
    const entry = { time: time, last: time, level: level, subsystem: subsystem, message: message, repeats: 0 }
    latest[key] = entry
    entries.push(entry)
    if (entries.length > capacity)
        entries.splice(0, entries.length - capacity)
    forget(time)
    return true
}

function info(subsystem, message, now) {
    return write("info", subsystem, message, now)
}

function warn(subsystem, message, now) {
    return write("warn", subsystem, message, now)
}

function error(subsystem, message, now) {
    return write("error", subsystem, message, now)
}

function recent() {
    return entries.slice()
}

function clear() {
    entries = []
    latest = ({})
}
