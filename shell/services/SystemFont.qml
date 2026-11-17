pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Controls.js" as Controls
import "../utils/Log.js" as Log

Singleton {
    id: systemFont

    property bool isWatching: false
    property var families: []
    readonly property string applied: store.values.applied || ""
    readonly property bool isApplied: applied.length > 0
    readonly property bool isBusy: worker.running

    function refresh() {
        lister.running = true
    }

    function apply(family) {
        if (isBusy || families.indexOf(family) < 0)
            return
        worker.begin(family, ["python3", Quickshell.shellPath("scripts/system-font.py"), "apply", family])
    }

    function restore() {
        if (isBusy || !isApplied)
            return
        worker.begin("", ["python3", Quickshell.shellPath("scripts/system-font.py"), "restore", store.values.previous || ""])
    }

    onIsWatchingChanged: {
        if (isWatching)
            refresh()
    }

    StateFile {
        id: store
        name: "font"
        defaults: ({ applied: "", previous: "" })
    }

    Process {
        id: lister
        command: ["fc-list", ":", "family"]
        stdout: StdioCollector {
            onStreamFinished: systemFont.families = Controls.parseFamilies(text)
        }
    }

    Process {
        id: worker

        property string family: ""
        property string answer: ""
        property int exitCode: -1
        property bool hasAnswer: false

        function begin(nextFamily, nextCommand) {
            family = nextFamily
            exitCode = -1
            hasAnswer = false
            command = nextCommand
            running = true
        }

        function settle() {
            if (exitCode < 0 || !hasAnswer)
                return
            if (exitCode !== 0) {
                Log.warn("font", `system-font.py exited with code ${exitCode}; the system font is unchanged`)
                return
            }
            if (family.length === 0)
                store.update({ applied: "", previous: "" })
            else
                store.update({ applied: family, previous: systemFont.isApplied ? store.values.previous : answer })
        }

        stdout: StdioCollector {
            onStreamFinished: {
                worker.answer = text.trim()
                worker.hasAnswer = true
                worker.settle()
            }
        }
        onExited: code => {
            exitCode = code
            settle()
        }
    }
}
