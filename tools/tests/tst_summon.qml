import QtQuick
import QtTest
import qs.config
import qs.modules.taskbar

Item {
    id: scene

    width: 600
    height: 900

    Taskbar {
        id: taskbar
        width: Appearance.taskbar.windowWidth
        height: scene.height
        isCovered: true
    }

    TestCase {
        name: "Summon"
        when: windowShown

        function cleanup() {
            taskbar.isEngaged = false
            taskbar.isCovered = true
            taskbar.isSummoned = false
        }

        function test_openSurfaceKeepsCoveredTaskbarSummoned() {
            taskbar.summon()
            verify(taskbar.isRevealed)
            taskbar.isEngaged = true
            wait(Motion.reveal.linger * 3)
            verify(taskbar.isRevealed, "a page grown out of the taskbar keeps it while the pointer is on the page")
            taskbar.isEngaged = false
            tryVerify(() => !taskbar.isRevealed, Motion.reveal.linger * 5, "once the page has gone the covered taskbar lingers and hides")
        }

        function test_focusFlickerKeepsOpenSurface() {
            taskbar.summon()
            taskbar.isEngaged = true
            taskbar.isCovered = false
            taskbar.isCovered = true
            verify(taskbar.isRevealed, "a field taking the keyboard and giving it back does not hide the taskbar under its page")
        }
    }
}
