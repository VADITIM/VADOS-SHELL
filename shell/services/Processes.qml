pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../utils/Processes.js" as ProcessTable
import "../utils/Log.js" as Log

Singleton {
    id: processes

    property bool isActive: false
    property var groups: []
    property var history: ({})
    property var previous: null
    readonly property var historyRows: ProcessTable.historyRows(history)
    readonly property real diskRate: groups.reduce((total, row) => total + Math.max(0, row.disk), 0)

    readonly property string reveal: [
        "gdbus call --session --dest org.freedesktop.FileManager1 --object-path /org/freedesktop/FileManager1",
        "--method org.freedesktop.FileManager1.ShowItems \"['file://$1']\" '' >/dev/null 2>&1",
        "|| xdg-open \"$(dirname \"$1\")\""
    ].join(" ")

    function read(line) {
        let sample = null
        try {
            sample = JSON.parse(line)
        } catch (error) {
            Log.warn("processes", "unreadable sample, skipping it")
            return
        }
        const measured = ProcessTable.measure(previous, sample)
        previous = ProcessTable.remember(sample)
        if (measured === null)
            return
        groups = ProcessTable.group(measured)
        history = ProcessTable.record(history, measured)
    }

    function save() {
        store.update({ apps: history })
    }

    function kill(row) {
        if (row.pids.length === 0)
            return
        killer.command = ["kill", "-TERM"].concat(row.pids.map(String))
        killer.running = true
    }

    function open(row) {
        const name = row.name.toLowerCase()
        const group = Toplevels.groups.find(candidate => candidate.appId.toLowerCase() === name)
            ?? Toplevels.groups.find(candidate => candidate.appId.toLowerCase().includes(name))
        if (group) {
            Toplevels.activate(group)
            return
        }
        if (row.path.length > 0)
            Quickshell.execDetached([row.path])
    }

    function find(row) {
        if (row.path.length > 0)
            Quickshell.execDetached(["sh", "-c", reveal, "sh", row.path])
    }

    onIsActiveChanged: {
        previous = null
        if (!isActive)
            save()
    }

    Connections {
        target: store

        function onIsLoadedChanged() {
            processes.history = Object.assign({}, store.values.apps, processes.history)
        }
    }

    Process {
        id: sampler
        command: ["python3", Quickshell.shellPath("scripts/processes.py"), String(Motion.dashboard.poll)]
        stdout: SplitParser {
            onRead: line => processes.read(line)
        }
    }

    Supervisor {
        name: "processes"
        process: sampler
        isActive: processes.isActive
    }

    Process {
        id: killer
        onExited: exitCode => {
            if (exitCode !== 0)
                Log.warn("processes", "kill exited with code " + exitCode + ", the process may belong to another user")
        }
    }

    Timer {
        interval: Motion.dashboard.historySave
        running: processes.isActive
        repeat: true
        onTriggered: processes.save()
    }

    StateFile {
        id: store
        name: "apphistory"
        defaults: ({ apps: {} })
    }
}
