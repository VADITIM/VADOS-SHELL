.pragma library

const keys = ["os", "kernel", "compositor", "shell", "host", "uptime", "cpu", "gpu", "memory"]
const labels = { os: "OS", kernel: "KERNEL", compositor: "COMPOSITOR", shell: "SHELL", host: "HOST", uptime: "UPTIME", cpu: "CPU", gpu: "GPU", memory: "MEMORY" }

function osNameOf(text) {
    const fields = {}
    for (const line of (text ?? "").split("\n")) {
        const split = line.indexOf("=")
        if (split <= 0)
            continue
        fields[line.slice(0, split).trim()] = line.slice(split + 1).trim().replace(/^["']|["']$/g, "")
    }
    return fields.PRETTY_NAME || fields.NAME || ""
}

function uptimeOf(seconds) {
    if (!(seconds > 0))
        return ""
    const minutes = Math.floor(seconds / 60)
    const days = Math.floor(minutes / 1440)
    const hours = Math.floor(minutes % 1440 / 60)
    const rest = minutes % 60
    if (days > 0)
        return days + " D " + hours + " H"
    if (hours > 0)
        return hours + " H " + rest + " M"
    return rest + " M"
}

function memoryOf(bytes) {
    if (!(bytes > 0))
        return ""
    return Math.round(bytes / 1073741824) + " GB"
}
