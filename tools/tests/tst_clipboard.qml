import QtQuick
import QtTest
import "../../shell/utils/Clipboard.js" as Clipboard

TestCase {
    name: "Clipboard"

    function text(content, time) {
        return Clipboard.entryOf({ kind: "text", text: content }, time ?? 0)
    }

    function fill(count, size) {
        let entries = []
        for (let index = 1; index <= count; index++)
            entries = Clipboard.add(entries, text("entry " + index, index), size)
        return entries
    }

    function test_newestComesFirst() {
        const entries = fill(3, 150)
        compare(entries.map(entry => entry.text), ["entry 3", "entry 2", "entry 1"])
    }

    function test_theHistoryHoldsItsSize() {
        const entries = fill(151, 150)
        compare(entries.length, 150)
        compare(entries[0].text, "entry 151")
        compare(entries[149].text, "entry 2", "the oldest goes first")
    }

    function test_pinnedEntriesOutliveTheCap() {
        let entries = fill(3, 3)
        entries = Clipboard.togglePin(entries, entries[2].key)
        for (let index = 4; index <= 10; index++)
            entries = Clipboard.add(entries, text("entry " + index, index), 3)
        compare(entries.length, 3)
        verify(entries.some(entry => entry.text === "entry 1" && entry.isPinned), "a pinned entry is never pushed out")
        compare(Clipboard.shown(entries, 2)[0].text, "entry 1", "pinned entries are shown first")
    }

    function test_copyingAgainMovesWithoutDuplicates() {
        let entries = fill(3, 150)
        entries = Clipboard.togglePin(entries, entries[2].key)
        entries = Clipboard.add(entries, text("entry 1", 9), 150)
        compare(entries.length, 3, "picking a row copies it without a new entry")
        compare(entries[0].text, "entry 1")
        verify(entries[0].isPinned, "it keeps its pin")
    }

    function test_kindsAreRecognised() {
        compare(text("hello there").kind, "text")
        compare(text("https://example.org/page").kind, "url")
        compare(text("www.example.org").kind, "url")
        compare(text("see https://example.org").kind, "text")
        compare(Clipboard.entryOf({ kind: "file", text: "file:///home/me/notes%20draft.txt" }, 0).kind, "file")
        compare(Clipboard.entryOf({ kind: "image", path: "/cache/shot.png" }, 0).kind, "image")
        compare(Clipboard.entryOf({ kind: "image" }, 0), null, "an image that was not kept has no entry")
        compare(Clipboard.entryOf({ skip: "secret" }, 0), null, "a password manager copy has no entry")
        compare(text("   "), null)
    }

    function test_secretsAreRecognised() {
        verify(Clipboard.isSecret("ghp_" + "a".repeat(36)))
        verify(Clipboard.isSecret("AKIA" + "ABCDEFGHIJKLMNOP"))
        verify(Clipboard.isSecret("-----BEGIN OPENSSH PRIVATE KEY-----\nabc"))
        verify(Clipboard.isSecret("sk-" + "x1".repeat(16)))
        verify(Clipboard.isSecret("Tr0ub4dor&3xyz"), "a word with every kind of character")
        verify(Clipboard.isSecret("k8sQ2mZ7xT4pL9vR3nW6yB1c"), "a long token")
        verify(!Clipboard.isSecret("hello world, this is a sentence"))
        verify(!Clipboard.isSecret("https://example.org/Very-Long-Path_2026?page=two"))
        verify(!Clipboard.isSecret("/home/me/Projects/Shell2026"))
        verify(!Clipboard.isSecret("ordinaryword"))
    }

    function test_secretsAreMaskedAndNeverStored() {
        const secret = text("Tr0ub4dor&3xyz", 1)
        verify(secret.isSecret)
        verify(Clipboard.labelOf(secret).indexOf("Tr0") < 0, "the label never shows the secret")
        const entries = Clipboard.add(Clipboard.add([], text("plain", 1), 150), secret, 150)
        compare(entries.length, 2)
        compare(Clipboard.storable(entries).map(entry => entry.text), ["plain"])
        compare(Clipboard.restore([{ key: "text:Tr0ub4dor&3xyz", kind: "text", text: "Tr0ub4dor&3xyz", path: "", time: 1 }]).length, 0, "a secret found on disk is dropped")
    }

    function test_restoreKeepsOnlyValidEntries() {
        const restored = Clipboard.restore([
            { key: "text:kept", kind: "text", text: "kept", path: "", time: 1, isPinned: true },
            { key: "broken", kind: "audio", text: "", path: "" },
            null,
            "text"
        ])
        compare(restored.length, 1)
        verify(restored[0].isPinned)
        compare(Clipboard.restore("broken").length, 0)
    }

    function test_mergeKeepsWhatArrivedBeforeTheFileLoaded() {
        const fresh = [text("new", 5)]
        const saved = [text("old", 1), text("new", 2)]
        compare(Clipboard.merge(fresh, saved, 150).map(entry => entry.text), ["new", "old"])
    }

    function test_clearKeepsPinnedEntries() {
        let entries = fill(4, 150)
        entries = Clipboard.togglePin(entries, entries[1].key)
        compare(Clipboard.clear(entries).map(entry => entry.text), ["entry 3"])
        compare(Clipboard.remove(entries, entries[0].key).length, 3)
    }

    function test_droppedImagesAreFound() {
        const image = Clipboard.entryOf({ kind: "image", path: "/cache/shot.png" }, 1)
        const entries = Clipboard.add([text("plain", 0)], image, 150)
        compare(Clipboard.droppedImages(entries, Clipboard.withoutImages(entries)), ["/cache/shot.png"])
        compare(Clipboard.droppedImages(entries, entries), [])
    }

    function test_labelsAndTypes() {
        compare(Clipboard.labelOf(text("https://example.org/")), "example.org/")
        compare(Clipboard.labelOf(text("one\n  two\tthree")), "one two three")
        const files = Clipboard.entryOf({ kind: "file", text: "file:///home/me/notes%20draft.txt\nfile:///home/me/plan.txt" }, 0)
        compare(Clipboard.labelOf(files), "notes draft.txt  +1")
        compare(Clipboard.mimeOf(files), "text/uri-list")
        compare(Clipboard.mimeOf(Clipboard.entryOf({ kind: "image", path: "/cache/shot.jpg" }, 0)), "image/jpeg")
        compare(Clipboard.mimeOf(text("plain")), "text/plain;charset=utf-8")
    }
}
