import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    width: 1600
    height: 900

    SignalSpy {
        id: landings
        target: launch
        signalName: "landed"
    }

    Launch {
        id: launch
        seed: Qt.rect(10, 400, 40, 40)
        panelX: 500
        panelY: 200
    }

    TestCase {
        name: "Launch"
        when: windowShown

        function cleanup() {
            launch.isShown = false
            tryCompare(launch, "phase", "idle", 3000)
            launch.lifecycle.watchdog.interval = Motion.lifecycle.stuck
            launch.panelX = 500
            launch.panelY = 200
            landings.clear()
        }

        function test_openAndLeave() {
            launch.isShown = true
            tryCompare(launch, "phase", "active", 3000)
            verify(launch.isOpened)
            launch.isShown = false
            verify(launch.isLeaving)
            tryCompare(launch, "isActive", false, 3000)
        }

        function test_stuckLeaveStillLands() {
            launch.isShown = true
            tryCompare(launch, "phase", "active", 3000)
            landings.clear()
            launch.lifecycle.watchdog.interval = 20
            ignoreWarning(new RegExp("vados: launch stuck in exiting"))
            launch.isShown = false
            tryCompare(launch, "phase", "idle", 1000)
            compare(landings.count, 1)
        }

        function test_leaveFollowsThePanel() {
            launch.isShown = true
            tryCompare(launch, "phase", "active", 3000)
            launch.isShown = false
            const before = launch.leaveFrom.x
            launch.panelX = 300
            fuzzyCompare(launch.leaveFrom.x, before - 200, 0.01)
            tryCompare(launch, "phase", "idle", 3000)
        }

        function test_rapidTogglingEndsInAValidState() {
            for (let step = 0; step < 7; step++) {
                launch.isShown = !launch.isShown
                wait(step * 31)
            }
            verify(launch.isShown)
            tryCompare(launch, "phase", "active", 3000)
            verify(launch.isOpened)
            verify(!launch.isLeaving)
        }
    }
}
