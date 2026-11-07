import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    width: 1600
    height: 900

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
