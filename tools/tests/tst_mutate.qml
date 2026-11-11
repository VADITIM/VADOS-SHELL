import QtQuick
import QtTest
import qs.config
import qs.components

TestCase {
    name: "Mutate"

    Mutate {
        id: first
        isShown: true
        isArriving: true
        hasArrived: false
        hasSpread: false
        hasArrivalPop: true
        enterDelay: 0
    }

    Mutate {
        id: second
        isShown: true
        isArriving: true
        hasArrived: false
        hasSpread: false
        hasArrivalPop: true
        enterDelay: 400
    }

    Mutate {
        id: plain
        isShown: true
        isArriving: true
        hasArrived: false
        hasSpread: false
        enterDelay: 400
    }

    function test_arrivingPillsKeepTheirBodyAndShowTheirInnerOneAfterAnother() {
        compare(first.pop, 0)
        first.hasArrived = true
        second.hasArrived = true
        compare(first.pop, 1, "the released circle is the body, it never pops again")
        compare(second.pop, 1)
        compare(second.isInnerShown, false)
        tryCompare(first, "isInnerShown", true, 1000)
        compare(second.isInnerShown, false, "the second pill still waits for its turn")
        tryCompare(second, "isInnerShown", true, 2000)
    }

    Mutate {
        id: held
        isShown: true
        enterDelay: 0
    }

    Mutate {
        id: long
        isShown: true
        isArriving: true
        hasArrived: false
        enterDelay: 0
    }

    function test_aHeldPillRetractsToItsCircleAndPopsOnlyOnceLetGo() {
        tryCompare(held, "spread", 1, 2000)
        held.isHolding = true
        held.isShown = false
        compare(held.isInnerShown, false, "its elements leave at once")
        tryCompare(held, "isRetired", true, 2000)
        compare(held.spread, 0)
        wait(Motion.pill.leavePop * 2)
        compare(held.pop, 1, "the circle stays until the burst carries it")
        held.isHolding = false
        tryCompare(held, "pop", 0, 2000)
        held.isShown = true
        tryCompare(held, "spread", 1, 2000)
        compare(held.pop, 1)
    }

    function test_anArrivingPillExtendsOutOfItsReleasedCircle() {
        compare(long.pop, 0)
        long.hasArrived = true
        compare(long.pop, 1)
        compare(long.spread, 0, "the released circle is where it starts")
        compare(long.isInnerShown, false)
        tryCompare(long, "isInnerShown", true, 2000)
        tryCompare(long, "spread", 1, 2000)
        compare(long.pop, 1)
    }

    function test_arrivingPillWithoutStaggerShowsItsInnerAtOnce() {
        plain.hasArrived = true
        compare(plain.pop, 1)
        compare(plain.isInnerShown, true)
    }
}
