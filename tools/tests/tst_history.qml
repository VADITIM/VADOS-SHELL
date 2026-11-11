import QtQuick
import QtTest
import "../../shell/utils/History.js" as History

TestCase {
    name: "History"

    function notification(id, extra) {
        return Object.assign({ id: id, appName: "Vesktop", desktopEntry: "dev.vencord.Vesktop", summary: "#general", body: "hi", urgency: 1 }, extra || {})
    }

    function test_newestComesFirstAndTheLimitHolds() {
        let entries = []
        for (let index = 1; index <= 5; index++)
            entries = History.record(entries, History.entryOf(notification(index), index * 10, ""), 3)
        compare(entries.length, 3)
        compare(entries.map(entry => entry.id), [5, 4, 3])
    }

    function test_aZeroLimitKeepsNothing() {
        compare(History.record([], History.entryOf(notification(1), 1, ""), 0).length, 0)
        compare(History.trim([History.entryOf(notification(1), 1, "")], 0).length, 0)
    }

    function test_transientNotificationsAreNotKept() {
        verify(History.isKept(notification(1)))
        verify(!History.isKept(notification(2, { transient: true })))
    }

    function test_forgetRemovesOnlyThatEntry() {
        const first = History.entryOf(notification(1), 10, "")
        const second = History.entryOf(notification(2), 20, "")
        const entries = History.forget([second, first], first.key)
        compare(entries.length, 1)
        compare(entries[0].id, 2)
    }

    function test_anEntryHoldsPlainData() {
        const entry = History.entryOf(notification(7, { image: "image://qsimage/7" }), 70, "/usr/share/icons/vesktop.png")
        compare(JSON.parse(JSON.stringify(entry)).summary, "#general")
        compare(entry.icon, "/usr/share/icons/vesktop.png")
        verify(History.isStorableIcon("/a.png"))
        verify(!History.isStorableIcon("image://qsimage/7"), "an image the server hands out lives only as long as the notification")
    }
}
