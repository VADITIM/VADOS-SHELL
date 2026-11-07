import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Scope {
    id: store

    required property string name
    property int version: 1
    property var defaults: ({})
    property var values: defaults
    property bool isLoaded: false
    readonly property string directory: Quickshell.env("HOME") + "/.cache/vados"
    readonly property string path: directory + "/" + name + ".json"

    function update(next) {
        values = next
        pendingWrite.restart()
    }

    function flush() {
        if (!pendingWrite.running)
            return
        pendingWrite.stop()
        write()
    }

    function write() {
        file.setText(JSON.stringify({ version: version, data: values }, null, 2))
    }

    function keepAside(suffix) {
        Quickshell.execDetached(["cp", path, path + "." + suffix])
    }

    function read(text) {
        let parsed = null
        try {
            parsed = JSON.parse(text)
        } catch (error) {
            keepAside("corrupt")
        }
        if (parsed === null || typeof parsed !== "object")
            values = defaults
        else if (parsed.version === undefined)
            values = Object.assign({}, defaults, parsed)
        else if (parsed.version === version && typeof parsed.data === "object")
            values = Object.assign({}, defaults, parsed.data)
        else {
            keepAside("version" + parsed.version)
            values = defaults
        }
        isLoaded = true
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", directory])
    Component.onDestruction: flush()

    FileView {
        id: file
        path: store.path
        printErrors: false
        onLoaded: store.read(text())
        onLoadFailed: store.isLoaded = true
    }

    Timer {
        id: pendingWrite
        interval: Motion.store.write
        onTriggered: store.write()
    }
}
