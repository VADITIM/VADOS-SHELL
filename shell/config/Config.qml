pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User config loaded from ~/.config/vados/shell.json.
Singleton {
    readonly property var data: adapter

    FileView {
        path: Quickshell.env("HOME") + "/.config/vados/shell.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property JsonObject bar: JsonObject {
                property bool enabled: true
            }
        }
    }
}
