pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: notes

    readonly property string text: store.values.text ?? ""
    readonly property bool isLoaded: store.isLoaded

    function write(next) {
        if (next === text)
            return
        store.update(Object.assign({}, store.values, { text: String(next) }))
    }

    StateFile {
        id: store
        name: "notes"
        defaults: ({ text: "" })
    }
}
