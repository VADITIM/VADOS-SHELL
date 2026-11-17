import QtQuick
import QtTest
import qs.config
import qs.modules.lock

Item {
    id: scene

    width: 1600
    height: 900

    property int spills: 0
    property int landings: 0

    LockScreen {
        id: lockScreen
        anchors.fill: parent
        visible: isPresent
        layout: []
        parts: [Qt.rect(6, 20, 40, 220), Qt.rect(6, 760, 40, 40)]
        origin: Qt.point(26, 780)
        profileName: "Vadim"
    }

    Component {
        id: leaveComponent

        LockLeave {
            anchors.fill: parent
            layout: []
            parts: [Qt.rect(6, 20, 40, 220), Qt.rect(6, 760, 40, 40)]
            onSpilled: scene.spills += 1
            onLanded: scene.landings += 1
        }
    }

    TestCase {
        name: "LockScreen"
        when: windowShown

        function cleanup() {
            Config.setReducedMotion(false)
            lockScreen.isBlank = false
            lockScreen.isMain = true
            lockScreen.isLocked = false
            tryCompare(lockScreen, "phase", "idle", 3000)
            scene.spills = 0
            scene.landings = 0
        }

        function moduleItems() {
            const found = []
            const queue = [lockScreen]
            while (queue.length > 0) {
                const next = queue.shift()
                if (next.host !== undefined && next.isShown !== undefined && next !== lockScreen)
                    found.push(next)
                for (const child of next.children)
                    queue.push(child)
            }
            return found
        }

        function test_emptyLayoutStillOpensTheCoreModules() {
            lockScreen.isLocked = true
            tryCompare(lockScreen, "phase", "active", 3000)
            compare(lockScreen.placements.map(placement => placement.key).sort(), ["clock", "login", "profile"])
            const modules = moduleItems()
            compare(modules.length, 3, "every placement loads its catalogue file")
            verify(modules.every(module => module.host === lockScreen && module.isShown))
        }

        function test_rapidTogglingEndsInValidPhase() {
            for (let round = 0; round < 9; round++) {
                lockScreen.isLocked = !lockScreen.isLocked
                wait(round * 13)
            }
            verify(lockScreen.isLocked)
            tryCompare(lockScreen, "phase", "active", 3000)
            verify(lockScreen.isReady)
            lockScreen.isLocked = false
            lockScreen.isLocked = true
            lockScreen.isLocked = false
            tryCompare(lockScreen, "phase", "idle", 3000)
            verify(!lockScreen.isReady)
        }

        function test_reducedMotionShowsTheModulesAtOnce() {
            Config.setReducedMotion(true)
            lockScreen.isLocked = true
            tryCompare(lockScreen, "isReady", true, 200)
            tryCompare(lockScreen, "phase", "active", 200)
        }

        function test_otherScreensShowOnlyTheBackground() {
            lockScreen.isMain = false
            lockScreen.isLocked = true
            tryCompare(lockScreen, "phase", "active", 3000)
            compare(lockScreen.placements.length, 0)
            compare(moduleItems().length, 0)
            verify(lockScreen.isReady)
        }

        function test_blankCoversEverythingAndStopsTheLiquid() {
            lockScreen.isLocked = true
            tryCompare(lockScreen, "phase", "active", 3000)
            lockScreen.isBlank = true
            tryCompare(lockScreen, "isDark", true, 3000)
            const passes = findChild(lockScreen, "passes")
            verify(passes !== null)
            verify(!passes.parent.visible, "the liquid stops rendering behind a black screen")
            lockScreen.isBlank = false
            tryCompare(lockScreen, "isDark", false, 3000)
            verify(passes.parent.visible)
        }

        function test_theLeaveSpillsAndLandsOnce() {
            const leave = createTemporaryObject(leaveComponent, scene)
            verify(leave !== null)
            tryCompare(leave, "phase", "idle", 5000)
            wait(300)
            compare(leave.phase, "idle", "a landed leave never starts again by itself")
            compare(scene.spills, 1, "the taskbar is given back once")
            compare(scene.landings, 1, "the leave lands exactly once")
        }

        function test_theLeaveOnOtherScreensOnlySpills() {
            const leave = createTemporaryObject(leaveComponent, scene, { isMain: false })
            compare(leave.frames.length, 0)
            tryCompare(leave, "phase", "idle", 5000)
            compare(scene.spills, 1)
            compare(scene.landings, 1)
        }
    }
}
