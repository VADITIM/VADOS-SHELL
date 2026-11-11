import QtQuick
import QtTest
import qs.components
import qs.config

Item {
    width: 400
    height: 200

    Roll {
        id: roll
        target: "12:34:56"
        font.pixelSize: 20
    }

    TestCase {
        name: "Roll"
        when: windowShown

        function cleanup() {
            roll.isShown = true
            roll.target = "12:34:56"
            tryVerify(() => roll.isSettled)
            roll.align()
        }

        function test_typesInThenSettles() {
            tryVerify(() => roll.isSettled)
            compare(roll.text, "")
            compare(roll.cellAt(7).present, "6")
        }

        function test_onlyTheChangedDigitRolls() {
            tryVerify(() => roll.isSettled)
            roll.target = "12:34:57"
            compare(roll.cellAt(7).past, "6")
            compare(roll.cellAt(7).present, "7")
            compare(roll.cellAt(6).progress, 1)
            compare(roll.cellAt(0).progress, 1)
            verify(roll.cellAt(7).progress < 1)
            tryCompare(roll.cellAt(7), "progress", 1)
            compare(roll.shown, "12:34:57")
        }

        function test_carryRipplesFromTheSeconds() {
            tryVerify(() => roll.isSettled)
            roll.target = "12:59:59"
            roll.align()
            roll.target = "13:00:00"
            compare(roll.cellAt(7).delay, 0)
            compare(roll.cellAt(6).delay, Motion.roll.carry)
            compare(roll.cellAt(4).delay, Motion.roll.carry * 2)
            compare(roll.cellAt(3).delay, Motion.roll.carry * 3)
            compare(roll.cellAt(1).delay, Motion.roll.carry * 4)
            compare(roll.cellAt(0).progress, 1)
            tryCompare(roll.cellAt(1), "progress", 1)
            compare(roll.cellAt(1).present, "3")
        }

        function test_leaveUntypesTheCurrentTime() {
            tryVerify(() => roll.isSettled)
            roll.target = "12:34:58"
            roll.isShown = false
            verify(!roll.isSettled)
            verify("12:34:58".startsWith(roll.text))
            tryCompare(roll, "text", "")
        }

        function test_reentersWithTheTimeThatPassed() {
            tryVerify(() => roll.isSettled)
            roll.isShown = false
            tryCompare(roll, "shown", "")
            roll.target = "18:00:00"
            roll.isShown = true
            tryVerify(() => roll.isSettled)
            compare(roll.cellAt(0).present, "1")
            compare(roll.cellAt(1).present, "8")
            compare(roll.cellAt(1).progress, 1)
        }
    }
}
