.pragma library

const stillPrefix = "Screenshot"
const motionPrefix = "Recording"
const stillExtension = "png"
const motionExtension = "mp4"
const stillFolder = "Screenshots"
const motionFolder = "Recordings"
const frameRate = "60"
const pauseSignal = 12
const stopSignal = 2

const recorders = [
    { key: "gpu-screen-recorder", canPause: true },
    { key: "wf-recorder", canPause: false }
]

function expand(path, home) {
    const trimmed = String(path ?? "").trim()
    let expanded = trimmed
    if (trimmed === "~")
        expanded = home
    else if (trimmed.startsWith("~/"))
        expanded = home + trimmed.slice(1)
    while (expanded.length > 1 && expanded.endsWith("/"))
        expanded = expanded.slice(0, -1)
    return expanded
}

function folderOf(setting, home, standard, leaf) {
    const chosen = expand(setting, home)
    if (chosen.length > 0)
        return chosen
    return expand(standard, home) + "/" + leaf
}

function padded(value) {
    return (value < 10 ? "0" : "") + value
}

function stampOf(date) {
    return date.getFullYear() + "-" + padded(date.getMonth() + 1) + "-" + padded(date.getDate())
        + "_" + padded(date.getHours()) + "-" + padded(date.getMinutes()) + "-" + padded(date.getSeconds())
}

function stillNameOf(date) {
    return stillPrefix + "_" + stampOf(date) + "." + stillExtension
}

function motionNameOf(date) {
    return motionPrefix + "_" + stampOf(date) + "." + motionExtension
}

function clockOf(seconds) {
    const whole = Math.max(0, Math.floor(seconds))
    const hours = Math.floor(whole / 3600)
    const minutes = Math.floor(whole % 3600 / 60)
    const rest = whole % 60
    if (hours > 0)
        return hours + ":" + padded(minutes) + ":" + padded(rest)
    return minutes + ":" + padded(rest)
}

function pickRecorder(installed) {
    return recorders.find(recorder => installed.indexOf(recorder.key) >= 0) ?? null
}

function recordCommand(recorder, screenName, file) {
    if (recorder.key === "gpu-screen-recorder")
        return ["gpu-screen-recorder", "-w", screenName, "-f", frameRate, "-a", "default_output", "-o", file]
    return ["wf-recorder", "-o", screenName, "-f", file]
}
