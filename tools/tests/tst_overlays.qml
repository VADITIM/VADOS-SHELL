import QtQuick
import QtTest
import qs.state

TestCase {
    name: "Overlays"

    property int gathers: 0

    Connections {
        target: Overlays

        function onTaskbarGathering(screenName) {
            gathers++
        }
    }

    function cleanup() {
        for (const key of Overlays.stack.slice())
            Overlays.close(key)
        Overlays.returnTaskbar("A")
        Overlays.returnTaskbar("B")
        gathers = 0
    }

    function test_switchKeepsTaskbarParts() {
        Overlays.open("dashboard", "A")
        Overlays.open("search", "A")
        verify(Overlays.isOpen("search", "A"))
        verify(!Overlays.isOpen("dashboard", "A"))
        compare(gathers, 1, "the second overlay reuses the parts of the first gather")
        verify(Overlays.ownsKeyboard("search", "A"))
        verify(!Overlays.ownsKeyboard("dashboard", "A"))
    }

    function test_taskbarReturnsPerScreen() {
        Overlays.open("search", "A")
        Overlays.returnTaskbar("A")
        verify(Overlays.isTaskbarAway("A"), "stays away while an overlay is open on it")
        Overlays.open("settings", "B")
        Overlays.returnTaskbar("A")
        verify(!Overlays.isTaskbarAway("A"))
        verify(Overlays.isTaskbarAway("B"))
    }

    function test_visitorsDoNotOverwriteEachOther() {
        Overlays.placeVisitor("search", "A", { x: 1 })
        Overlays.placeVisitor("dashboard", "A", { x: 2 })
        Overlays.placeVisitor("dashboard", "A", null)
        compare(Overlays.visitorOn("A").x, 1)
        Overlays.placeVisitor("search", "A", null)
        compare(Overlays.visitorOn("A"), null)
    }

    function test_closeTopAndUnknownKeys() {
        Overlays.open("settings", "A")
        Overlays.closeTop()
        verify(!Overlays.isAnyOpen())
        Overlays.toggle("nonsense", "A")
        verify(!Overlays.isAnyOpen())
    }
}
