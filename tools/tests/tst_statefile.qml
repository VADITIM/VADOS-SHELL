import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.services

TestCase {
    name: "StateFile"

    readonly property string directory: Quickshell.env("HOME") + "/.cache/vados"

    Component {
        id: storeComponent

        StateFile {
            defaults: ({ count: 0, items: [] })
        }
    }

    function open(name) {
        const store = createTemporaryObject(storeComponent, this, { name: name })
        tryCompare(store, "isLoaded", true, 1000)
        return store
    }

    function test_missingFileGivesDefaults() {
        const store = open("missing")
        compare(store.values.count, 0)
    }

    function test_writesAndReadsBack() {
        const store = open("roundtrip")
        store.update({ count: 3, items: ["a"] })
        wait(Motion.store.write + 100)
        const saved = JSON.parse(Quickshell.readFile(directory + "/roundtrip.json"))
        compare(saved.version, 1)
        compare(saved.data.count, 3)
        const again = open("roundtrip")
        compare(again.values.count, 3)
        compare(again.values.items[0], "a")
    }

    function test_legacyFileIsReadAsData() {
        Quickshell.writeFile(directory + "/legacy.json", JSON.stringify({ count: 7 }))
        compare(open("legacy").values.count, 7)
    }

    function test_corruptFileIsKeptAside() {
        Quickshell.writeFile(directory + "/broken.json", "{ not json")
        compare(open("broken").values.count, 0)
        compare(Quickshell.readFile(directory + "/broken.json.corrupt"), "{ not json")
    }

    function test_otherVersionIsKeptAside() {
        Quickshell.writeFile(directory + "/future.json", JSON.stringify({ version: 2, data: { count: 9 } }))
        compare(open("future").values.count, 0)
        verify(Quickshell.readFile(directory + "/future.json.version2").length > 0)
    }

    function test_flushWritesAtOnce() {
        const store = open("flushed")
        store.update({ count: 5, items: [] })
        store.flush()
        compare(JSON.parse(Quickshell.readFile(directory + "/flushed.json")).data.count, 5)
    }
}
