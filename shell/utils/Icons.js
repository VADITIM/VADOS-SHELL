.pragma library
.import "IconPaths.js" as IconPaths

const paths = IconPaths.paths

const steps = {
    speaker: { above: [[0.5, "volume-2"], [0.01, "volume-1"]], otherwise: "volume-0" },
    wifi: { above: [[0.7, "wifi-4"], [0.4, "wifi-3"], [0.05, "wifi-2"], [0, "wifi-1"]], otherwise: "wifi-off" },
    battery: { above: [[0.75, "battery-full"], [0.45, "battery-mid"], [0.2, "battery-low"], [0.1, "battery-empty"]], otherwise: "battery-critical", charging: "battery-charging" }
}

function pick(name, level, isCharging) {
    const step = steps[name]
    if (!step)
        return name
    if (isCharging && step.charging)
        return step.charging
    for (const entry of step.above) {
        if (level > entry[0])
            return entry[1]
    }
    return step.otherwise
}

function has(name) {
    return Object.prototype.hasOwnProperty.call(paths, name)
}

function strokeOf(name) {
    return has(name) ? paths[name].stroke : ""
}

function fillOf(name) {
    return has(name) ? paths[name].fill : ""
}
