import QtQuick
import QtTest
import qs.services
import qs.state

TestCase {
    name: "Activity"

    function quiet() {
        Activities.isCalling = false
        Activities.hasMedia = false
        Notifications.clear()
        ActivityState.lead = ""
        ActivityState.mode = "idle"
    }

    function cleanup() {
        Overlays.close("notifications")
        Notifications.clear()
        Activities.isCalling = true
        Activities.hasMedia = true
        ActivityState.lead = ""
        ActivityState.mode = "idle"
    }

    function test_catalogueHoldsNotificationsAndTray() {
        verify(Activities.keys.includes("notifications"))
        verify(Activities.keys.includes("tray"))
        verify(!Activities.isLive("tray"), "the tray is reachable but never makes the pill active by itself")
    }

    function test_unreadNotificationWakesThePill() {
        quiet()
        Notifications.post("discord", "discord", "Mira", "are you there", 1)
        verify(Activities.isLive("notifications"))
        compare(ActivityState.mode, "active")
        compare(ActivityState.leadKey, "notifications")
    }

    function test_expandingTheBellOpensTheMenu() {
        quiet()
        Notifications.post("discord", "discord", "Mira", "are you there", 1)
        compare(ActivityState.leadKey, "notifications")
        ActivityState.toggle("screen")
        compare(Overlays.top, "notifications", "the bell opens the notifications menu")
        verify(ActivityState.mode !== "expanded", "the pill itself does not expand")
        verify(ActivityState.isReading)
        compare(Notifications.unreadCount, 0, "opening the menu reads it")
        Notifications.post("telegram", "org.telegram.desktop", "Leon", "lunch?", 1)
        tryCompare(Notifications, "unreadCount", 0, 1000, "arrivals while the menu is open are read")
        Overlays.close("notifications")
        verify(!ActivityState.isReading)
        Notifications.post("telegram", "org.telegram.desktop", "Leon", "still there?", 1)
        compare(Notifications.unreadCount, 1, "with the menu closed they wait as unread")
    }

    function test_theWheelSkipsTheBellWhileExpanded() {
        quiet()
        Activities.hasMedia = true
        Activities.isCalling = true
        Notifications.post("discord", "discord", "Mira", "are you there", 1)
        ActivityState.pin("media")
        ActivityState.toggle("screen")
        compare(ActivityState.mode, "expanded")
        for (let step = 0; step < 6; step++) {
            ActivityState.rotate(1)
            verify(ActivityState.leadKey !== "notifications", "an expanded pill never turns into the bell")
        }
    }

    function test_pinningTheBellFoldsTheExpandedPill() {
        quiet()
        Activities.hasMedia = true
        ActivityState.toggle("screen")
        compare(ActivityState.mode, "expanded")
        ActivityState.pin("notifications")
        compare(ActivityState.mode, "active")
        compare(ActivityState.leadKey, "notifications")
    }

    function test_toggleFoldsBackToTheRightMode() {
        quiet()
        ActivityState.toggle("screen")
        compare(ActivityState.mode, "expanded")
        ActivityState.toggle("screen")
        compare(ActivityState.mode, "idle")
        Activities.hasMedia = true
        compare(ActivityState.mode, "active")
        ActivityState.toggle("screen")
        ActivityState.fold()
        compare(ActivityState.mode, "active")
    }

    function test_pinPicksTheLead() {
        quiet()
        ActivityState.pin("tray")
        compare(ActivityState.leadKey, "tray")
        ActivityState.pin("nothing")
        compare(ActivityState.leadKey, "tray", "an unknown key changes nothing")
    }

    function test_expandedKeepsItsLeadWhenAnActivityStarts() {
        quiet()
        ActivityState.pin("tray")
        ActivityState.toggle("screen")
        Activities.isCalling = true
        compare(ActivityState.mode, "expanded")
        compare(ActivityState.leadKey, "tray")
    }
}
