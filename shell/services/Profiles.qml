pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Controls.js" as Controls

Singleton {
    id: profiles

    property bool isWatching: false
    property var keys: []
    property string active: ""
    readonly property bool isAvailable: keys.length > 0

    function refresh() {
        listQuery.running = true
    }

    function set(key) {
        Quickshell.execDetached(["powerprofilesctl", "set", key])
        active = key
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 4000
        running: profiles.isWatching
        repeat: true
        onTriggered: profiles.refresh()
    }

    Process {
        id: listQuery
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const read = Controls.parseProfiles(text)
                profiles.keys = read.keys
                profiles.active = read.active
            }
        }
    }
}
