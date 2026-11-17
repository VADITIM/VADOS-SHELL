pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Controls.js" as Controls

Singleton {
    id: brightness

    property bool isWatching: false
    property bool isAvailable: false
    property real level: 0

    function refresh() {
        query.running = true
    }

    function setLevel(value) {
        level = Math.max(0.01, Math.min(1, value))
        pending.restart()
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
        running: brightness.isWatching && !pending.running
        repeat: true
        onTriggered: brightness.refresh()
    }

    Timer {
        id: pending
        interval: 60
        onTriggered: Quickshell.execDetached(["brightnessctl", "set", Controls.brightnessArgument(brightness.level)])
    }

    Process {
        id: query
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const read = Controls.parseBrightness(text)
                brightness.isAvailable = read !== null
                if (read && !pending.running)
                    brightness.level = read.level
            }
        }
    }
}
