import QtQuick
import QtTest
import qs.services

TestCase {
    name: "Occupancy"

    readonly property var covering: ({ id: 2, appId: "editor", screen: "play", x: 0, y: 0, width: 1600, height: 900, isFullscreen: false })
    readonly property var aside: ({ id: 3, appId: "player", screen: "play", x: 600, y: 100, width: 400, height: 300, isFullscreen: false })

    function cleanup() {
        Compositor.activeWindow = null
        Compositor.lastWindow = null
    }

    function test_theFocusedWindowCoversTheTaskbar() {
        Compositor.activeWindow = covering
        verify(Occupancy.isCovered("play", false))
        Compositor.activeWindow = aside
        verify(!Occupancy.isCovered("play", false), "a window away from the edge leaves the taskbar")
        verify(!Occupancy.isCovered("other", false), "a window on another screen leaves the taskbar")
    }

    function test_theLastWindowStillCoversWhileAnOverlayHoldsTheKeyboard() {
        Compositor.lastWindow = covering
        verify(Occupancy.isCovered("play", true), "the window that had focus before the overlay still covers the taskbar")
        verify(!Occupancy.isCovered("play", false), "without an overlay only the focused window hides the taskbar")
    }

    function test_theFocusedWindowWinsOverTheLastOne() {
        Compositor.lastWindow = covering
        Compositor.activeWindow = aside
        verify(!Occupancy.isCovered("play", true))
    }
}
