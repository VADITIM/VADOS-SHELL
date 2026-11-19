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
        Capture.stop()
        Attention.dismissPeek()
        ActivityState.closeClipboard()
        Clipboard.isEnabled = true
        Overlays.close("notifications")
        Notifications.clear()
        Activities.isCalling = true
        Activities.hasMedia = true
        ActivityState.lead = ""
        ActivityState.mode = "idle"
    }

    function test_thePillHasThreeTabs() {
        compare(Activities.tabs, ["notifications", "media", "call"])
        verify(!Activities.keys.includes("tray"), "background apps live in their own pill")
    }

    function test_theWheelStepsThroughTheTabsAndStopsAtTheEnds() {
        quiet()
        ActivityState.pin("notifications")
        ActivityState.rotate(-1)
        compare(ActivityState.leadKey, "notifications", "the first tab never wraps to the last")
        ActivityState.rotate(1)
        compare(ActivityState.leadKey, "media", "scrolling up takes the tab below")
        ActivityState.rotate(1)
        compare(ActivityState.leadKey, "call")
        ActivityState.rotate(1)
        compare(ActivityState.leadKey, "call", "the last tab never wraps to the first")
        ActivityState.rotate(-1)
        compare(ActivityState.leadKey, "media")
    }

    function test_showingATabWhileExpandedKeepsItExpanded() {
        quiet()
        ActivityState.pin("media")
        ActivityState.toggle("screen")
        ActivityState.show("screen", "call")
        compare(ActivityState.mode, "expanded")
        compare(ActivityState.leadKey, "call")
        ActivityState.show("screen", "notifications")
        compare(Overlays.top, "notifications", "the bell tab opens the notifications menu")
        verify(ActivityState.mode !== "expanded")
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
        ActivityState.pin("call")
        compare(ActivityState.leadKey, "call")
        ActivityState.pin("nothing")
        compare(ActivityState.leadKey, "call", "an unknown key changes nothing")
        ActivityState.pin("tray")
        compare(ActivityState.leadKey, "call", "the tray is no tab")
    }

    function test_expandedKeepsItsLeadWhenAnActivityStarts() {
        quiet()
        ActivityState.pin("media")
        ActivityState.toggle("screen")
        Activities.isCalling = true
        compare(ActivityState.mode, "expanded")
        compare(ActivityState.leadKey, "media")
    }

    function test_clipboardOpensOnItsOwnScreen() {
        quiet()
        ActivityState.toggleClipboard("screen")
        verify(ActivityState.isClipboardOn("screen"))
        verify(!ActivityState.isClipboardOn("other"), "it opens only where it was asked")
        ActivityState.toggleClipboard("screen")
        verify(!ActivityState.isClipboardOn("screen"), "the same key closes it")
    }

    function test_clipboardOpensOverAMenu() {
        quiet()
        Overlays.open("notifications", "screen")
        ActivityState.toggleClipboard("screen")
        verify(ActivityState.isClipboardOn("screen"), "the clipboard opens over an open menu")
        ActivityState.toggleClipboard("screen")
        Overlays.close("notifications")
    }

    function test_clipboardAndExpandedTakeTurns() {
        quiet()
        Activities.hasMedia = true
        ActivityState.toggle("screen")
        compare(ActivityState.mode, "expanded")
        ActivityState.toggleClipboard("screen")
        verify(ActivityState.isClipboardOn("screen"))
        compare(ActivityState.mode, "active", "opening the clipboard folds the expanded activity")
        ActivityState.set("screen", "expanded")
        verify(!ActivityState.isClipboardOn("screen"), "expanding an activity closes the clipboard")
        compare(ActivityState.mode, "expanded")
    }

    function test_steppingClosesTheClipboardFirst() {
        quiet()
        ActivityState.toggleClipboard("screen")
        ActivityState.step("screen", 1)
        verify(!ActivityState.isClipboardOn("screen"))
        compare(ActivityState.mode, "idle", "the step only closed the clipboard")
    }

    function test_clipboardNeedsTheSetting() {
        quiet()
        Clipboard.isEnabled = false
        ActivityState.toggleClipboard("screen")
        verify(!ActivityState.isClipboardOn("screen"), "with clipboard.enabled off nothing opens")
        Clipboard.isEnabled = true
        ActivityState.toggleClipboard("screen")
        Clipboard.isEnabled = false
        verify(!ActivityState.isClipboardOn("screen"), "turning it off closes it")
    }
    function test_recordingLeadsAndAnnouncesItself() {
        quiet()
        Attention.dismissPeek()
        verify(!Activities.order.includes("recording"), "recording is never reached while nothing records")
        Capture.record("screen")
        compare(ActivityState.leadKey, "recording")
        compare(ActivityState.mode, "active")
        verify(Attention.peek !== null, "the pill peeks RECORDING NOW")
        compare(Attention.peek.notifications[0].summary, "RECORDING NOW")
        compare(Attention.peek.screen, "screen")
        tryCompare(Attention, "peek", null, 3000, "the notice gives way to the recording pill")
        Capture.stop()
        verify(ActivityState.leadKey !== "recording")
        compare(ActivityState.mode, "idle")
    }

    function test_recordingTakesTheLeadFromMedia() {
        quiet()
        Activities.hasMedia = true
        ActivityState.pin("media")
        compare(ActivityState.leadKey, "media")
        Capture.record("screen")
        compare(ActivityState.leadKey, "recording")
        Capture.stop()
        compare(ActivityState.leadKey, "media")
    }

    function test_noticeSurvivesNotificationChanges() {
        quiet()
        Capture.record("screen")
        Notifications.post("discord", "discord", "Mira", "are you there", 1)
        Notifications.clear()
        verify(Attention.peek !== null, "a shell notice is not a notification that can be dismissed from the list")
    }

    function test_stoppingFoldsAnExpandedRecording() {
        quiet()
        Capture.record("screen")
        ActivityState.set("screen", "expanded")
        compare(ActivityState.mode, "expanded")
        compare(ActivityState.lead, "recording")
        Capture.stop()
        compare(ActivityState.mode, "idle")
    }
}
