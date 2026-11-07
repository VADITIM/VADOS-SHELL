import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    width: 1600
    height: 900

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
        }

        function test_openAndLeave() {
            launch.isShown = true
            tryCompare(launch, "phase", "active", 3000)
            verify(launch.isOpened)
            launch.isShown = false
            verify(launch.isLeaving)
            tryCompare(launch, "isActive", false, 3000)
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
