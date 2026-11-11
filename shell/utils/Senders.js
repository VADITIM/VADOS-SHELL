.pragma library

const senders = [
    { key: "blip", name: "BLIP", binary: "blip", desktopEntry: "net.blip.Blip" }
]

function byKey(key) {
    return senders.find(sender => sender.key === key) ?? null
}

function sendCommand(sender, peer, file) {
    if (sender.key === "blip")
        return peer.length > 0 ? ["blip", "--peer=" + peer, "--file=" + file] : ["blip", "--file=" + file]
    return []
}

function devicesOf(entries) {
    const devices = []
    for (const entry of entries || []) {
        const at = String(entry).indexOf(":")
        const name = at > 0 ? entry.slice(0, at).trim() : ""
        const peer = at > 0 ? entry.slice(at + 1).trim() : ""
        if (name.length > 0 && peer.length > 0)
            devices.push({ name: name, peer: peer })
    }
    return devices
}

function nextOf(installed, current) {
    const keys = senders.map(sender => sender.key).filter(key => installed.indexOf(key) >= 0)
    if (keys.length === 0)
        return current
    return keys[(keys.indexOf(current) + 1) % keys.length]
}
