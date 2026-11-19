import QtQuick
import QtTest
import "../../shell/utils/PillOrder.js" as PillOrder

TestCase {
    name: "PillOrder"

    function test_aBrokenOrderIsRepaired() {
        compare(PillOrder.normalise(null), PillOrder.keys)
        compare(PillOrder.normalise(["power", "ghost", "power", "usb"]), ["power", "usb", "audio", "network", "fold", "battery", "settings"])
    }

    function test_anOrderSavedBeforeTheFoldGetsItBeforeTheLastTwoPills() {
        compare(PillOrder.normalise(["usb", "audio", "network", "battery", "settings", "power"]), PillOrder.keys)
    }

    function test_movingAPillShiftsTheOthers() {
        compare(PillOrder.move(PillOrder.keys, "power", 0), ["power", "usb", "audio", "network", "battery", "fold", "settings"])
        compare(PillOrder.move(PillOrder.keys, "usb", 99), ["audio", "network", "battery", "fold", "settings", "power", "usb"])
        compare(PillOrder.move(PillOrder.keys, "ghost", 0), PillOrder.keys)
    }

    function test_pillsUnderTheFoldStayWhenCompact() {
        verify(PillOrder.isKeptCompact(PillOrder.keys, "power"))
        verify(PillOrder.isKeptCompact(PillOrder.keys, "settings"))
        verify(!PillOrder.isKeptCompact(PillOrder.keys, "battery"))
        verify(PillOrder.isKeptCompact(PillOrder.move(PillOrder.keys, "fold", 0), "usb"))
    }

    function test_theSlotFollowsTheDragOverRowsOfEveryHeight() {
        const heights = { usb: 50, audio: 50, network: 50, battery: 50, fold: 20, settings: 50, power: 50 }
        compare(PillOrder.slotFor(PillOrder.keys, "power", -30, heights), 0)
        compare(PillOrder.slotFor(PillOrder.keys, "power", 205, heights), 4)
        compare(PillOrder.slotFor(PillOrder.keys, "power", 900, heights), 6)
        compare(PillOrder.keyAt(PillOrder.keys, heights, 210), "fold")
        compare(PillOrder.keyAt(PillOrder.keys, heights, 230), "settings")
    }

    function test_offsetsStackInOrderAndSkipHiddenPills() {
        const offsets = PillOrder.offsetsFor(["power", "usb"], { power: 10, usb: 0, audio: 5 })
        compare(offsets.power, 0)
        compare(offsets.usb, 10)
        compare(offsets.audio, 10)
        compare(offsets.network, 15)
        compare(offsets.total, 15)
    }
}
