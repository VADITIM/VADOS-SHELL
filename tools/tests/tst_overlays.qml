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
        Overlays.phases = {}
        Overlays.swaps = {}
        gathers = 0
    }

    function test_screenIsHeldUntilItsLastOverlayHasLeft() {
        verify(!Overlays.isHolding("A"))
        Overlays.open("dashboard", "A")
        verify(Overlays.isHolding("A"))
        verify(!Overlays.isHolding("B"))
        Overlays.reportPhase("dashboard", "A", "active")
        Overlays.close("dashboard")
        Overlays.reportPhase("dashboard", "A", "leaving")
        verify(Overlays.isHolding("A"), "the screen stays held while the overlay leaves")
        Overlays.reportPhase("dashboard", "A", "idle")
        verify(!Overlays.isHolding("A"))
    }

    function test_taskbarDrawsItsOwnPartsUntilTheOverlayCarriesThem() {
        const first = Object.keys(Overlays.kinds)[0]
        Overlays.open(first, "A")
        verify(Overlays.isTaskbarAway("A"))
        verify(Overlays.isGathering("A"), "the taskbar keeps its liquid while its elements leave")
        compare(gathers, 1)
        Overlays.carryTaskbar("A")
        verify(!Overlays.isGathering("A"))
        compare(gathers, 2, "the parts are taken again as they are when the overlay takes them")
        Overlays.carryTaskbar("A")
        compare(gathers, 2, "a second overlay on the screen does not take the parts again")
        Overlays.close(first)
        Overlays.reportPhase(first, "A", "idle")
        verify(!Overlays.isTaskbarAway("A"))
    }

    function test_aGatherThatIsNeverCarriedEndsWithTheReturn() {
        const first = Object.keys(Overlays.kinds)[0]
        Overlays.open(first, "A")
        Overlays.close(first)
        Overlays.returnTaskbar("A")
        verify(!Overlays.isGathering("A"))
        verify(!Overlays.isTaskbarAway("A"))
    }

    function test_surfaceIsWantedFromOpenUntilItsLeaveHasLanded() {
        verify(!Overlays.isWanted("search", "A"), "an overlay nobody opened has no surface")
        Overlays.open("search", "A")
        verify(Overlays.isWanted("search", "A"))
        verify(!Overlays.isWanted("search", "B"), "only the screen it opened on builds it")
        verify(!Overlays.isWanted("dashboard", "A"))
        Overlays.reportPhase("search", "A", "active")
        Overlays.close("search")
        Overlays.reportPhase("search", "A", "exiting")
        verify(Overlays.isWanted("search", "A"), "the surface stays while it leaves")
        Overlays.reportPhase("search", "A", "idle")
        verify(!Overlays.isWanted("search", "A"), "an idle, closed overlay is released")
    }

    function test_waitingOverlayIsWantedBeforeItShows() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "active")
        Overlays.open("search", "A")
        verify(Overlays.isWaiting("search", "A"))
        verify(Overlays.isWanted("search", "A"), "built while it waits for the circle")
        verify(Overlays.isWanted("dashboard", "A"), "the displaced overlay stays until it has left")
        Overlays.reportPhase("dashboard", "A", "idle")
        verify(!Overlays.isWanted("dashboard", "A"))
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

    function test_switchWaitsForTheFirstToHandOverItsCircle() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "active")
        Overlays.open("search", "A")
        verify(Overlays.isWaiting("search", "A"))
        verify(Overlays.hasCircle("search", "A"), "known before the overlay shows, so its burst never starts from the taskbar parts")
        verify(Overlays.isHandingOver("dashboard", "A"))
        verify(!Overlays.isHandingOver("search", "A"))
        Overlays.settleSwap("A")
        verify(!Overlays.isWaiting("search", "A"))
        verify(Overlays.hasCircle("search", "A"))
        Overlays.reportPhase("dashboard", "A", "idle")
        verify(Overlays.isTaskbarAway("A"), "the taskbar stays away between two overlays")
        Overlays.reportPhase("search", "A", "active")
        verify(!Overlays.hasCircle("search", "A"))
    }

    function test_taskbarStaysAwayWhenTheFirstOverlayReactsToBeingClosed() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "active")
        const reaction = Qt.createQmlObject("import QtQuick; import qs.state; Item { Connections { target: Overlays; function onScreensChanged() { if (!Overlays.screenOf('dashboard')) Overlays.returnTaskbar('A') } } }", this)
        Overlays.open("search", "A")
        verify(Overlays.isTaskbarAway("A"), "closing the first overlay must not return the taskbar while the second is arriving")
        reaction.destroy()
        Overlays.swaps = {}
    }

    function test_leavingOverlayKnowsItHandsOverBeforeItIsClosed() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "active")
        let isHandingOverBeforeClose = false
        const watcher = Qt.createQmlObject("import QtQuick; import qs.state; Item { id: watcher; signal swapped(); Connections { target: Overlays; function onSwapsChanged() { watcher.swapped() } } }", this)
        watcher.swapped.connect(() => {
            if (Overlays.isOpen("dashboard", "A"))
                isHandingOverBeforeClose = Overlays.isHandingOver("dashboard", "A")
        })
        Overlays.open("search", "A")
        verify(isHandingOverBeforeClose, "the leave must not start as a release that streams the taskbar parts home")
        watcher.destroy()
        Overlays.swaps = {}
    }

    function test_closingTheWaitingOverlayEndsTheSwap() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "active")
        Overlays.open("search", "A")
        Overlays.close("search")
        verify(!Overlays.isWaiting("search", "A"))
        Overlays.swaps = {}
    }

    function test_openingOverAnIdleSurfaceIsNoSwap() {
        Overlays.open("dashboard", "A")
        Overlays.open("search", "A")
        verify(!Overlays.isWaiting("search", "A"))
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

    function test_taskbarReturnsWhenTheLastSurfaceIsIdle() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "preparing")
        Overlays.reportPhase("dashboard", "A", "active")
        verify(Overlays.isSettled("A"))
        Overlays.close("dashboard")
        Overlays.reportPhase("dashboard", "A", "exiting")
        compare(Overlays.phaseOf("dashboard", "A"), "exiting")
        verify(!Overlays.isSettled("A"))
        verify(Overlays.isTaskbarAway("A"), "a leave that never landed still holds the taskbar")
        Overlays.reportPhase("dashboard", "A", "idle")
        compare(Overlays.phaseOf("dashboard", "A"), "idle")
        verify(!Overlays.isTaskbarAway("A"), "an idle screen always gets its taskbar back")
    }

    function test_idleSurfaceKeepsTaskbarForTheNextOverlay() {
        Overlays.open("dashboard", "A")
        Overlays.reportPhase("dashboard", "A", "active")
        Overlays.open("search", "A")
        Overlays.reportPhase("dashboard", "A", "exiting")
        Overlays.reportPhase("dashboard", "A", "idle")
        verify(Overlays.isTaskbarAway("A"))
        compare(gathers, 1)
    }

    function test_lostScreenLeavesNothingBehind() {
        Overlays.open("search", "B")
        Overlays.placeTaskbarParts("B", [{ x: 1 }])
        Overlays.placeVisitor("search", "B", { x: 1 })
        Overlays.reportPhase("search", "B", "entering")
        Overlays.keepScreens(["A"])
        verify(!Overlays.isAnyOpen())
        compare(Overlays.top, "")
        verify(!Overlays.isTaskbarAway("B"))
        compare(Overlays.taskbarParts["B"], undefined)
        compare(Overlays.visitorOn("B"), null)
        compare(Overlays.phaseOf("search", "B"), "idle")
    }

    function test_closeTopAndUnknownKeys() {
        Overlays.open("settings", "A")
        Overlays.closeTop()
        verify(!Overlays.isAnyOpen())
        Overlays.toggle("nonsense", "A")
        verify(!Overlays.isAnyOpen())
    }
}
