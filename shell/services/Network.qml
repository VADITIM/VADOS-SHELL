pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: network

    property bool isEnabled: true
    property bool isWired: false
    property string ssid: ""
    property real strength: 0
    property bool isWatching: false
    property var networks: []
    readonly property bool isConnected: isWired || ssid.length > 0

    function readNetworks(text) {
        const best = {}
        for (const line of text.split("\n")) {
            const parts = line.split(":")
            if (parts.length < 4)
                continue
            const name = parts.slice(3).join(":").split("\\").join("")
            if (name.length === 0)
                continue
            const entry = {
                ssid: name,
                strength: Math.round(Number(parts[1]) / 10) / 10,
                isSecured: parts[2].length > 0 && parts[2] !== "--",
                isActive: parts[0] === "yes"
            }
            const known = best[name]
            if (!known || entry.isActive || (!known.isActive && entry.strength > known.strength))
                best[name] = entry
        }
        const sorted = Object.values(best).sort((first, second) => (second.isActive - first.isActive) || (second.strength - first.strength))
        if (JSON.stringify(sorted) !== JSON.stringify(networks))
            networks = sorted
    }

    function connectTo(name) {
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", name])
    }

    function refresh() {
        radioQuery.running = true
        deviceQuery.running = true
        wifiQuery.running = true
    }

    function readWifi(text) {
        const active = text.split("\n").find(line => line.startsWith("yes:"))
        if (!active) {
            ssid = ""
            strength = 0
            return
        }
        const parts = active.split(":")
        strength = Number(parts[1]) / 100
        ssid = parts.slice(2).join(":").replace(/\\/g, "")
    }

    function toggle() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", isEnabled ? "off" : "on"])
        isEnabled = !isEnabled
    }

    Component.onCompleted: refresh()

    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: settle.restart()
        }
    }

    Supervisor {
        name: "network"
        process: monitor
    }

    Timer {
        id: settle
        interval: 300
        onTriggered: network.refresh()
    }

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: network.refresh()
    }

    Timer {
        interval: 8000
        running: network.isWatching && network.isEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: networkQuery.running = true
    }

    Process {
        id: networkQuery
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: network.readNetworks(text)
        }
    }

    Process {
        id: radioQuery
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: network.isEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: deviceQuery
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: network.isWired = text.split("\n").some(line => line === "ethernet:connected")
        }
    }

    Process {
        id: wifiQuery
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: network.readWifi(text)
        }
    }
}
