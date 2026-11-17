pragma Singleton
import QtQuick
import "../utils/Clipboard.js" as Entries
QtObject {
    property bool isEnabled: true
    property int size: 150
    property bool isKeepingImages: true
    property var entries: [
        Entries.entryOf({ kind: "text", text: "git rebase --onto master feature" }, 6),
        Entries.entryOf({ kind: "text", text: "https://github.com/VADITIM/VADOS-SHELL/pull/12" }, 5),
        Entries.entryOf({ kind: "file", text: "file:///home/vadim/Pictures/shell-burst.png" }, 4),
        Entries.entryOf({ kind: "text", text: "Tr0ub4dor&3xyz" }, 3),
        Entries.entryOf({ kind: "text", text: "The liquid necks and fuses with its neighbours." }, 2),
        Entries.entryOf({ kind: "text", text: "qs -p ~/.config/vados/shell" }, 1),
        Entries.entryOf({ kind: "url", text: "www.space-mono.org" }, 0)
    ]
    property var picked: []
    function pick(entry) { picked = picked.concat([entry.key]); entries = Entries.add(entries, Object.assign({}, entry, { time: Date.now() }), size) }
    function togglePin(entry) { entries = Entries.togglePin(entries, entry.key) }
    function remove(entry) { entries = Entries.remove(entries, entry.key) }
    function clear() { entries = Entries.clear(entries) }
}
