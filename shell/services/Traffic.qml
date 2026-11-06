pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: traffic

    property bool isActive: false
    property real download: 0
    property real upload: 0
    property var downloads: []
    property var uploads: []
    property real ping: 0
    property real jitter: 0
    property bool hasPing: false
    property var pings: []
    property var previous: null

    readonly property string pingHost: "1.1.1.1"
    readonly property var spaces: new RegExp("\\s+", "g")
    readonly property var pingTime: new RegExp("time=([\\d.]+)")

    function remember(history, value) {
        const kept = history.concat([value])
        return kept.slice(Math.max(0, kept.length - Motion.dashboard.trafficSamples))
    }

    function readCounters(text) {
        let received = 0
        let sent = 0
        for (const line of text.split("\n").slice(2)) {
            const parts = line.trim().split(spaces)
            if (parts.length < 10 || parts[0] === "lo:")
                continue
            received += Number(parts[1])
            sent += Number(parts[9])
        }
        const now = Date.now()
        if (previous) {
            const seconds = Math.max(0.001, (now - previous.time) / 1000)
            download = Math.max(0, (received - previous.received) / seconds)
            upload = Math.max(0, (sent - previous.sent) / seconds)
            downloads = remember(downloads, download)
            uploads = remember(uploads, upload)
        }
        previous = { time: now, received: received, sent: sent }
    }

    function readPing(line) {
        const found = line.match(pingTime)
        if (!found)
            return
        const latest = Number(found[1])
        pings = pings.concat([latest]).slice(-Motion.dashboard.pingSamples)
        ping = latest
        hasPing = true
        if (pings.length < 2)
            return
        let spread = 0
        for (let index = 1; index < pings.length; index++)
            spread += Math.abs(pings[index] - pings[index - 1])
        jitter = spread / (pings.length - 1)
    }

    onIsActiveChanged: if (!isActive) {
        pings = []
        hasPing = false
    }

    Timer {
        interval: Motion.dashboard.trafficPoll
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: counterFile.reload()
    }

    FileView {
        id: counterFile
        path: "/proc/net/dev"
        onLoaded: traffic.readCounters(text())
    }

    Process {
        command: ["ping", "-n", "-i", "1", traffic.pingHost]
        running: traffic.isActive
        stdout: SplitParser {
            onRead: line => traffic.readPing(line)
        }
    }
}
