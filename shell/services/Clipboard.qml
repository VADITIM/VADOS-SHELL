pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../utils/Clipboard.js" as Entries
import "../utils/Log.js" as Log

Singleton {
    id: clipboard

    readonly property bool isEnabled: Config.data.clipboard.enabled
    readonly property int size: Config.data.clipboard.size
    readonly property bool isKeepingImages: Config.data.clipboard.images
    readonly property string imageDirectory: store.directory + "/clipboard"
    property var entries: []
    property string pendingText: ""

    function receive(line) {
        let raw = null
        try {
            raw = JSON.parse(line)
        } catch (error) {
            Log.warn("clipboard", "the watcher sent a line that is not JSON; it is ignored")
            return
        }
        const entry = Entries.entryOf(raw, Date.now())
        if (entry)
            update(Entries.add(entries, entry, size))
    }

    function update(next) {
        const dropped = Entries.droppedImages(entries, next)
        if (dropped.length > 0)
            Quickshell.execDetached(["rm", "-f", "--"].concat(dropped))
        entries = next
        if (store.isLoaded)
            store.update({ entries: Entries.storable(next) })
    }

    function load() {
        const saved = Entries.restore(store.values.entries)
        const merged = Entries.merge(entries, saved, size)
        update(isKeepingImages ? merged : Entries.withoutImages(merged))
    }

    function pick(entry) {
        if (!entry)
            return
        if (entry.kind === "image") {
            Quickshell.execDetached(["sh", "-c", "exec wl-copy --type \"$1\" < \"$2\"", "sh", Entries.mimeOf(entry), entry.path])
            return
        }
        pendingText = entry.text
        copier.command = ["wl-copy", "--type", Entries.mimeOf(entry)]
        copier.running = true
    }

    function togglePin(entry) {
        update(Entries.togglePin(entries, entry.key))
    }

    function remove(entry) {
        update(Entries.remove(entries, entry.key))
    }

    function clear() {
        update(Entries.clear(entries))
    }

    onSizeChanged: {
        if (store.isLoaded)
            update(Entries.trim(entries, size))
    }
    onIsKeepingImagesChanged: {
        if (!isKeepingImages)
            update(Entries.withoutImages(entries))
        supervisor.stop()
    }

    StateFile {
        id: store
        name: "clipboard"
        defaults: ({ entries: [] })
        onIsLoadedChanged: {
            if (isLoaded)
                clipboard.load()
        }
    }

    Process {
        id: watcher
        command: ["wl-paste", "--watch", "python3", Quickshell.shellPath("scripts/clipboard.py"), "read", clipboard.imageDirectory, clipboard.isKeepingImages ? "images" : "text"]
        stdout: SplitParser {
            onRead: line => clipboard.receive(line)
        }
    }

    Supervisor {
        id: supervisor
        name: "clipboard"
        process: watcher
        isActive: clipboard.isEnabled
    }

    Process {
        id: copier
        stdinEnabled: true
        onStarted: {
            write(clipboard.pendingText)
            clipboard.pendingText = ""
            stdinEnabled = false
        }
        onExited: exitCode => {
            stdinEnabled = true
            if (exitCode !== 0)
                Log.warn("clipboard", "wl-copy exited with code " + exitCode + ", nothing was copied; is wl-clipboard installed?")
        }
    }
}
