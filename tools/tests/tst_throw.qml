import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    id: scene

    Throw {
        id: flight
        label: "test throw"
        span: 200
    }

    Throw {
        id: bouncing
        label: "test bounce"
        span: 200
        easing: Easing.OutBack
        overshoot: 2
    }

    TestCase {
        name: "Throw"
        when: windowShown

        function cleanup() {
            flight.isThrown = false
        }

        function test_restsUntilThrown() {
            compare(flight.share, 0)
            verify(!flight.isLanded)
            compare(flight.playing, "")
        }

        function test_travelsOnceAndLands() {
            flight.isThrown = true
            compare(flight.playing, "test throw")
            tryVerify(() => flight.isLanded, 2000)
            compare(flight.share, 1)
            compare(flight.playing, "")
        }

        function test_aRecallMidFlightRestsAtTheStart() {
            flight.isThrown = true
            tryVerify(() => flight.share > 0.1, 2000)
            flight.isThrown = false
            compare(flight.share, 0)
            verify(!flight.travel.running)
        }

        function test_anOvershootRunsPastTheEndAndSettlesOnIt() {
            bouncing.isThrown = true
            tryVerify(() => bouncing.share > 1.02, 2000)
            tryVerify(() => !bouncing.travel.running, 2000)
            compare(bouncing.share, 1)
            verify(bouncing.isLanded)
            bouncing.isThrown = false
        }

        function test_reducedMotionLandsAtOnce() {
            Config.setReducedMotion(true)
            flight.isThrown = true
            tryVerify(() => flight.isLanded, 500)
            Config.setReducedMotion(false)
        }
    }
}
