import QtQuick
import QtTest
import VadosTest
import "../../shell/utils/Locking.js" as Locking
import "../../shell/utils/Lock.js" as Lock

TestCase {
    name: "Locking"

    function keysOf(placements) {
        return placements.map(placement => placement.key).sort()
    }

    function test_sessionKeyNeedsBothParts() {
        compare(Locking.sessionKey("boot-one\n", " 2"), "boot-one:2")
        compare(Locking.sessionKey("", "2"), "")
        compare(Locking.sessionKey("boot-one", ""), "")
        compare(Locking.sessionKey(undefined, undefined), "")
    }

    function test_recoversOnlyTheSameLockedSession() {
        verify(Locking.shouldRecover({ isLocked: true, session: "boot-one:2" }, "boot-one:2"))
        verify(!Locking.shouldRecover({ isLocked: false, session: "boot-one:2" }, "boot-one:2"), "an unlocked marker never locks")
        verify(!Locking.shouldRecover({ isLocked: true, session: "boot-two:2" }, "boot-one:2"), "a lock from an earlier boot never locks a fresh login")
        verify(!Locking.shouldRecover({ isLocked: true, session: "boot-one:3" }, "boot-one:2"), "a lock from another session never locks this one")
        verify(!Locking.shouldRecover({ isLocked: true, session: "" }, ""), "without a session key nothing recovers")
        verify(!Locking.shouldRecover({ isLocked: "true", session: "boot-one:2" }, "boot-one:2"), "only a real true locks")
        verify(!Locking.shouldRecover(null, "boot-one:2"))
    }

    function test_typingBuildsThePasswordAndEnterHandsItOver() {
        let typed = Locking.typeInto("", Qt.Key_S, "s", Qt.NoModifier)
        compare(typed.draft, "s")
        typed = Locking.typeInto(typed.draft, Qt.Key_Exclam, "!", Qt.ShiftModifier)
        compare(typed.draft, "s!", "shifted characters type")
        compare(Locking.typeInto("s!", Qt.Key_Backspace, "\b", Qt.NoModifier).draft, "s")
        compare(Locking.typeInto("s!", Qt.Key_Backspace, "", Qt.ControlModifier).draft, "", "Ctrl+Backspace clears")
        compare(Locking.typeInto("s!", Qt.Key_Escape, "\u001b", Qt.NoModifier).draft, "")
        compare(Locking.typeInto("s!", Qt.Key_C, "c", Qt.ControlModifier).draft, "s!", "shortcuts never type")
        compare(Locking.typeInto("s!", Qt.Key_Tab, "\t", Qt.NoModifier).draft, "s!", "control characters never type")
        const entered = Locking.typeInto("s!", Qt.Key_Return, "\r", Qt.NoModifier)
        compare(entered.password, "s!")
        compare(entered.draft, "", "the field empties as the password leaves it")
        compare(Locking.typeInto("", Qt.Key_Enter, "\r", Qt.NoModifier).password, "", "an empty Enter submits nothing")
    }

    function test_failuresSayWhatHappened() {
        compare(Locking.failureOf("failed"), "WRONG PASSWORD")
        compare(Locking.failureOf("timedOut"), "AUTHENTICATION TIMED OUT")
        compare(Locking.failureOf("unknown"), "AUTHENTICATION FAILED")
    }

    function test_everyCatalogueModuleHasItsFile() {
        compare(Locking.fileOf("clock"), "ClockModule.qml")
        compare(Locking.fileOf("notifications"), "NotificationsModule.qml")
        compare(Locking.fileOf(""), "")
        for (const module of Lock.modules) {
            const file = String(Qt.resolvedUrl("../../shell/modules/lock/" + Locking.fileOf(module.key))).replace("file://", "")
            verify(Disk.read(file).length > 0, module.key + " has " + Locking.fileOf(module.key))
        }
    }

    function test_mainScreenFollowsHotplug() {
        compare(Locking.mainScreenOf(["DP-1", "HDMI-A-1"], "HDMI-A-1"), "HDMI-A-1")
        compare(Locking.mainScreenOf(["DP-1"], "HDMI-A-1"), "DP-1", "the modules move to a remaining screen when theirs goes away")
        compare(Locking.mainScreenOf([], "HDMI-A-1"), "")
    }

    function test_theLayoutAlwaysHoldsTheCoreModules() {
        const empty = Locking.layoutOf([])
        compare(keysOf(empty), ["clock", "login", "profile"], "a layout without them still has a login window")
        const placed = Locking.layoutOf(["clock:0:0", "weather:10:10"])
        compare(keysOf(placed), ["clock", "login", "profile", "weather"])
        for (const placement of placed) {
            verify(Lock.isInside(placement, placement.column, placement.row), placement.key + " stays on the grid")
            for (const other of placed) {
                if (other !== placement)
                    verify(!Lock.overlaps(other, placement, placement.column, placement.row), placement.key + " and " + other.key + " do not overlap")
            }
        }
    }

    function test_brokenLayoutsAreRepairedNotDropped() {
        const placed = Locking.layoutOf(["login:14:14", "login:0:0", "nothing:1:1", "profile:x:2"])
        compare(keysOf(placed), ["clock", "login", "profile"])
        const login = placed.find(placement => placement.key === "login")
        verify(Lock.isInside(login, login.column, login.row), "a login placed off the grid is pulled back onto it")
    }

    function test_rectsFillTheirCells() {
        const rect = Locking.rectOf({ column: 2, row: 4, columns: 4, rows: 2 }, 1600, 800, 10)
        compare(rect.x, 2 * 100 + 5)
        compare(rect.y, 4 * 50 + 5)
        compare(rect.width, 4 * 100 - 10)
        compare(rect.height, 2 * 50 - 10)
    }

    function test_delaysFormStaggeredPermutation() {
        let calls = 0
        const delays = Locking.delays(5, 20, () => [0.7, 0.1, 0.9, 0.3][calls++ % 4])
        compare(delays.length, 5)
        compare(delays.slice().sort((first, second) => first - second), [0, 20, 40, 60, 80], "every module gets its own slot")
        compare(Locking.delays(0, 20, Math.random).length, 0)
    }
}
