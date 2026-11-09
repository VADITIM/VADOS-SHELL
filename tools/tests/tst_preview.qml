import QtQuick
import QtTest
import qs.state

TestCase {
    name: "Preview"

    property var window: null

    function initTestCase() {
        failOnWarning(/.*/)
        const component = Qt.createComponent(Qt.resolvedUrl("../preview/play.qml"))
        compare(component.status, Component.Ready, component.errorString())
        window = component.createObject(null)
        verify(window !== null)
        wait(800)
    }

    function cleanupTestCase() {
        window.destroy()
    }

    function test_wholeShellLoadsWithoutWarnings() {
        verify(window !== null)
    }

    function overlayModule(propertyName) {
        const scene = window.contentItem.children[0]
        for (const child of scene.children) {
            if (child[propertyName] !== undefined && child.isOpen !== undefined)
                return child
        }
        return null
    }

    function test_switchingFromTheDashboardToSearchNeverShowsTheTaskbar() {
        failOnWarning(/.*/)
        const search = overlayModule("favoriteIds")
        verify(search !== null)
        Overlays.open("dashboard", window.screenName)
        tryCompare(Overlays, "top", "dashboard")
        tryVerify(() => Overlays.phaseOf("dashboard", window.screenName) === "active", 5000, "the preview reports overlay phases")
        Overlays.open("search", window.screenName)
        verify(!search.isOpen, "search waits for the dashboard's circle instead of gathering the taskbar parts again")
        tryVerify(() => {
            verify(Overlays.isTaskbarAway(window.screenName), "the taskbar showed during the swap")
            return Overlays.phaseOf("search", window.screenName) === "active"
        }, 10000)
        Overlays.close("search")
        tryVerify(() => !Overlays.isTaskbarAway(window.screenName), 10000)
    }

    function test_frameDebuggerOwnsTheKeyboardOverTheSearchField() {
        failOnWarning(/.*/)
        Overlays.toggle("search", window.screenName)
        tryVerify(() => window.activeFocusItem !== null && window.activeFocusItem.toString().startsWith("QQuickTextInput"), 2000)
        const field = window.activeFocusItem
        FrameDebug.toggle(window.screenName)
        tryVerify(() => window.activeFocusItem !== field, 1000)
        FrameDebug.close()
        tryCompare(window, "activeFocusItem", field)
        Overlays.close("search")
        tryVerify(() => !Overlays.isTaskbarAway(window.screenName), 10000)
    }
}
