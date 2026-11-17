pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Controls.js" as Controls
import "../utils/Log.js" as Log

Singleton {
    id: network

    property bool isEnabled: true
    property bool isWired: false
    property string ssid: ""
    property real strength: 0
    property bool isWatching: false
    property var networks: []
    property string backend: ""
    property string device: ""
    property var known: []
    property var prompt: null
    property string joining: ""
    property string joinResult: ""
    property var queuedJoin: []
    property bool isJoiningHidden: false
    property string asked: "passphrase"
    readonly property string joinMessage: Controls.joinMessage(joinResult)
    readonly property bool isJoining: joiner.running
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
                isEnterprise: parts[2].indexOf("802.1X") >= 0,
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

    function connectTo(name, isHidden, isAgain) {
        const entry = networks.find(candidate => candidate.ssid === name)
        if (name.length === 0 || (entry && entry.isActive))
            return
        prompt = null
        joinResult = ""
        joining = name
        isJoiningHidden = isHidden === true
        if (isAgain !== true)
            asked = "passphrase"
        queuedJoin = ["python3", Quickshell.shellPath("scripts/wifi.py"), "connect", backend, device, name, isHidden === true ? "hidden" : "visible", Controls.securityOf(entry), isAgain === true ? "again" : "first"]
        if (joiner.running)
            joiner.running = false
        else
            startQueuedJoin()
    }

    function startQueuedJoin() {
        joiner.command = queuedJoin
        queuedJoin = []
        joiner.running = true
    }

    function answer(values) {
        if (prompt === null || !joiner.running)
            return
        for (const value of values)
            joiner.write(value + "\n")
        prompt = null
    }

    function cancelJoin() {
        queuedJoin = []
        joiner.running = false
        prompt = null
        joining = ""
        joinResult = ""
    }

    function settleJoin() {
        if (prompt !== null)
            cancelJoin()
        else if (!joiner.running)
            joinResult = ""
    }

    function readJoinLine(line) {
        const read = Controls.parseJoinLine(line)
        if (read === null)
            return
        if (read.kind === "ask") {
            asked = read.ask
            prompt = { ssid: joining, ask: read.ask }
        }
        else if (read.kind === "cancel")
            prompt = null
        else if (read.result === "wrong") {
            Log.warn("network", "the password for a network was refused, asking again")
            connectTo(joining, isJoiningHidden, true)
            joinResult = "wrong"
        } else {
            prompt = null
            joinResult = read.result
            joining = ""
            if (read.result === "connected")
                refresh()
            else
                Log.warn("network", "joining a network failed (" + read.result + "), the page shows it")
            knownQuery.running = true
        }
    }

    function forget(name) {
        if (backend === "iwd")
            forgetter.command = ["iwctl", "known-networks", name, "forget"]
        else
            forgetter.command = ["nmcli", "connection", "delete", "id", name]
        forgetter.running = true
    }

    function refresh() {
        if (backend === "iwd") {
            if (device.length === 0)
                stationQuery.running = true
            else {
                powerQuery.running = true
                showQuery.running = true
            }
            wiredQuery.running = true
        } else if (backend === "nmcli") {
            radioQuery.running = true
            deviceQuery.running = true
            wifiQuery.running = true
        }
    }

    function scan() {
        if (backend === "iwd") {
            Quickshell.execDetached(["iwctl", "station", device, "scan"])
            listQuery.running = true
        } else if (backend === "nmcli")
            networkQuery.running = true
        knownQuery.running = true
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
        if (backend === "iwd")
            Quickshell.execDetached(["iwctl", "device", device, "set-property", "Powered", isEnabled ? "off" : "on"])
        else
            Quickshell.execDetached(["nmcli", "radio", "wifi", isEnabled ? "off" : "on"])
        isEnabled = !isEnabled
    }

    Component.onCompleted: backendQuery.running = true

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
        isActive: network.backend === "nmcli"
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
        onTriggered: network.scan()
    }

    Process {
        id: joiner
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => network.readJoinLine(line)
        }
        onExited: {
            if (network.queuedJoin.length > 0) {
                network.startQueuedJoin()
                return
            }
            network.prompt = null
            if (network.joining.length > 0) {
                network.joining = ""
                network.joinResult = "error"
            }
        }
    }

    Process {
        id: forgetter
        onExited: {
            knownQuery.running = true
            network.refresh()
        }
    }

    Process {
        id: knownQuery
        command: network.backend === "iwd" ? ["iwctl", "known-networks", "list"] : ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = network.backend === "iwd" ? Controls.parseIwdKnown(text) : Controls.parseNmcliKnown(text)
                if (JSON.stringify(found) !== JSON.stringify(network.known))
                    network.known = found
            }
        }
    }

    Process {
        id: backendQuery
        command: ["sh", "-c", "if command -v nmcli >/dev/null; then echo nmcli; elif command -v iwctl >/dev/null; then echo iwd; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                network.backend = text.trim()
                network.refresh()
            }
        }
    }

    Process {
        id: stationQuery
        command: ["iwctl", "station", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                network.device = Controls.parseStationName(text)
                if (network.device.length > 0)
                    network.refresh()
            }
        }
    }

    Process {
        id: powerQuery
        command: ["iwctl", "device", network.device, "show"]
        stdout: StdioCollector {
            onStreamFinished: network.isEnabled = Controls.parsePowered(text)
        }
    }

    Process {
        id: showQuery
        command: ["iwctl", "station", network.device, "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const read = Controls.parseStationShow(text)
                network.ssid = read.isConnected ? read.ssid : ""
                const active = network.networks.find(entry => entry.ssid === network.ssid)
                network.strength = read.isConnected ? (active ? active.strength : 0.5) : 0
                listQuery.running = true
            }
        }
    }

    Process {
        id: listQuery
        command: ["iwctl", "station", network.device, "get-networks"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = Controls.parseIwdNetworks(text)
                if (JSON.stringify(found) !== JSON.stringify(network.networks))
                    network.networks = found
            }
        }
    }

    Process {
        id: wiredQuery
        command: ["sh", "-c", "cat /sys/class/net/e*/operstate 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: network.isWired = text.split("\n").some(line => line === "up")
        }
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
