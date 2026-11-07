import QtQuick
import Quickshell

QtObject {
    id: file

    property string path: ""
    property bool printErrors: true
    property string content: ""

    signal loaded()
    signal loadFailed(var error)

    function text() {
        return content
    }

    function setText(value) {
        content = value
        Quickshell.writeFile(path, value)
    }

    function load() {
        const read = Quickshell.readFile(path)
        if (read.length === 0) {
            loadFailed("missing")
            return
        }
        content = read
        loaded()
    }

    onPathChanged: Qt.callLater(load)
}
