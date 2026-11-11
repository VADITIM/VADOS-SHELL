pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Log.js" as Log

Singleton {
    id: chooser

    property bool isPicking: false
    property var receiver: null
    property var chosen: []

    function choose(title, kind, onChosen) {
        if (isPicking)
            return false
        receiver = onChosen
        chosen = []
        isPicking = true
        picker.command = ["python3", Quickshell.shellPath("scripts/pick-files.py"), title, kind]
        picker.running = true
        return true
    }

    function finish(code) {
        if (code !== 0)
            Log.warn("files", "the file chooser exited with code " + code + "; nothing was chosen")
        const deliver = receiver
        receiver = null
        isPicking = false
        if (deliver)
            deliver(code === 0 ? chosen : [])
    }

    Process {
        id: picker
        stdout: StdioCollector {
            onStreamFinished: chooser.chosen = text.split("\n").filter(line => line.length > 0)
        }
        onExited: code => Qt.callLater(() => chooser.finish(code))
    }
}
