import QtQuick
import QtTest
import "../../shell/utils/Fuzzy.js" as Fuzzy

TestCase {
    name: "Fresh"

    readonly property var apps: [{ id: "a" }, { id: "b" }, { id: "c" }]
    readonly property real day: 86400000

    function test_theFirstRunMarksEveryAppAsOld() {
        const seen = Fuzzy.noteSeen(apps, null, 1000)
        compare(seen, { a: 0, b: 0, c: 0 })
        compare(Fuzzy.fresh(apps, seen, {}, 2000, day).length, 0)
    }

    function test_anAppThatAppearsLaterIsNew() {
        const seen = Fuzzy.noteSeen(apps, { a: 0, b: 0 }, 5000)
        compare(seen.c, 5000)
        compare(Fuzzy.fresh(apps, seen, {}, 6000, day).map(app => app.id), ["c"])
    }

    function test_nothingChangesWhenEveryAppIsKnown() {
        const known = { a: 0, b: 0, c: 0 }
        verify(Fuzzy.noteSeen(apps, known, 5000) === known)
    }

    function test_aLaunchedAppIsNoLongerNew() {
        const seen = { a: 0, b: 0, c: 5000 }
        compare(Fuzzy.fresh(apps, seen, { c: { count: 1, last: 6000 } }, 7000, day).length, 0)
    }

    function test_anAppStopsBeingNewAfterTheWindow() {
        const seen = { a: 0, b: 0, c: 5000 }
        compare(Fuzzy.fresh(apps, seen, {}, 5000 + day + 1, day).length, 0)
    }

    function test_theNewestComesFirst() {
        const seen = { a: 100, b: 300, c: 200 }
        compare(Fuzzy.fresh(apps, seen, {}, 400, day).map(app => app.id), ["b", "c", "a"])
    }
}
