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

    function test_arrivingPillWithoutStaggerShowsItsInnerAtOnce() {
        plain.hasArrived = true
        compare(plain.pop, 1)
        compare(plain.isInnerShown, true)
    }
}
