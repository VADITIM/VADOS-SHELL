import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    width: 1600
    height: 900

    SignalSpy {
        id: landings
        target: burst
        signalName: "landed"
    }

    Burst {
        id: burst
        rootX: 0
        seedX: 30
        seedY: 450
        formWidth: 600
        formHeight: 900
        leftCorner: 40
        rightCorner: 40
    }

    TestCase {
        name: "Burst"
        when: windowShown

        function cleanup() {
            burst.isShown = false
            tryCompare(burst, "isActive", false, 3000)
            Config.setReducedMotion(false)
            burst.lifecycle.watchdog.interval = Motion.lifecycle.stuck
            burst.seedY = 450
            burst.formHeight = 900
            landings.clear()
        }

        function test_reopenDuringLeaveRewinds() {
            burst.isShown = true
            tryCompare(burst, "isOpened", true, 3000)
            tryCompare(burst, "spread", 1, 3000)
            burst.isShown = false
            tryVerify(() => burst.exit > 0.05, 1000)
            verify(burst.canRewind)
            burst.isShown = true
            verify(burst.merge === 1, "does not converge from the taskbar again")
            tryCompare(burst, "isLeaving", false, 1000)
            verify(burst.spread > 0.99, "continues from the open form, not from an empty ball")
            verify(burst.isOpened)
        }

        function test_rapidTogglingEndsInAValidState() {
            for (let step = 0; step < 9; step++) {
                burst.isShown = !burst.isShown
                wait(step * 23)
            }
            verify(burst.isShown)
            tryCompare(burst, "phase", "active", 3000)
            verify(burst.isOpened)
            compare(burst.exit, 0)
            burst.isShown = false
            tryCompare(burst, "phase", "idle", 3000)
            verify(!burst.isActive, "no orphaned surface after the leave")
        }

        function test_stuckBurstSettles() {
            burst.lifecycle.watchdog.interval = 40
            burst.isShown = true
            ignoreWarning(new RegExp("vados: burst stuck in"))
            tryCompare(burst, "phase", "active", 1000)
            compare(burst.spread, 1)
            burst.lifecycle.watchdog.interval = Motion.lifecycle.stuck
        }

        function test_everyLeaveLandsOnce() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            landings.clear()
            burst.isShown = false
            tryCompare(burst, "phase", "idle", 3000)
            compare(landings.count, 1)
        }

        function test_stuckLeaveStillLands() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            landings.clear()
            burst.lifecycle.watchdog.interval = 20
            ignoreWarning(new RegExp("vados: burst stuck in exiting"))
            burst.isShown = false
            tryCompare(burst, "phase", "idle", 1000)
            compare(landings.count, 1, "a settled leave hands the taskbar back")
            wait(Motion.burst.leaveHold * 2)
            compare(landings.count, 1, "and only once")
        }

        function test_leaveFollowsScreenChanges() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            burst.isShown = false
            verify(burst.isLeaving)
            const before = burst.leaveFrom.height
            burst.seedY = 300
            burst.formHeight = 600
            fuzzyCompare(burst.leaveFrom.height, before * 600 / 900, 0.01)
            fuzzyCompare(burst.leaveFrom.y, 300, 0.01)
            tryCompare(burst, "phase", "idle", 3000)
        }

        function test_reducedMotionOpensAtOnce() {
            Config.setReducedMotion(true)
            burst.isShown = true
            tryCompare(burst, "isOpened", true, 200)
            verify(!burst.isSplashing, "no splashes or crests under reduced motion")
            burst.isShown = false
            tryCompare(burst, "isActive", false, 200)
        }
    }
}
