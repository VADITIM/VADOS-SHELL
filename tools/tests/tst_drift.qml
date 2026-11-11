import QtQuick
import QtTest
import qs.components
import qs.config

Item {
    width: 400
    height: 400

    Flickable {
        id: view
        width: 200
        height: 200
        contentWidth: 200
        contentHeight: 1000

        Drift {
            id: drift
        }
    }

    Flickable {
        id: across
        x: 200
        width: 200
        height: 200
        contentWidth: 1000
        contentHeight: 200
        flickableDirection: Flickable.HorizontalFlick

        Drift {
            id: acrossDrift
            isHorizontal: true
        }
    }

    TestCase {
        name: "Drift"
        when: windowShown

        function cleanup() {
            view.interactive = true
            drift.settle(0)
            acrossDrift.isReversed = false
            acrossDrift.settle(0)
        }

        function test_wheelGlidesInsteadOfJumping() {
            mouseWheel(view, 100, 100, 0, -120)
            verify(view.contentY < Motion.drift.notch)
            verify(drift.isDrifting)
            tryVerify(() => !drift.isDrifting)
            compare(view.contentY, Motion.drift.notch)
        }

        function test_quickNotchesAddUp() {
            mouseWheel(view, 100, 100, 0, -120)
            mouseWheel(view, 100, 100, 0, -120)
            mouseWheel(view, 100, 100, 0, -120)
            tryVerify(() => !drift.isDrifting)
            compare(view.contentY, Motion.drift.notch * 3)
        }

        function test_stopsAtTheEnds() {
            mouseWheel(view, 100, 100, 0, 120)
            tryVerify(() => !drift.isDrifting)
            compare(view.contentY, 0)
            for (let notch = 0; notch < 20; notch++)
                mouseWheel(view, 100, 100, 0, -120)
            tryVerify(() => !drift.isDrifting)
            compare(view.contentY, view.contentHeight - view.height)
        }

        function test_continuesFromAnOutsideMove() {
            view.contentY = 300
            mouseWheel(view, 100, 100, 0, -120)
            tryVerify(() => !drift.isDrifting)
            compare(view.contentY, 300 + Motion.drift.notch)
        }

        function test_glideAroundEasesJumps() {
            drift.glideAround(() => view.contentY = 500)
            verify(view.contentY < 500)
            tryVerify(() => !drift.isDrifting)
            compare(view.contentY, 500)
        }

        function test_touchpadFollowsAndGlidesOnRelease() {
            drift.follow(20)
            compare(view.contentY, 20)
            wait(16)
            drift.follow(20)
            compare(view.contentY, 40)
            drift.release()
            tryVerify(() => !drift.isDrifting)
            verify(view.contentY > 40)
        }

        function test_restingViewIgnoresTheWheel() {
            view.interactive = false
            mouseWheel(view, 100, 100, 0, -120)
            wait(50)
            compare(view.contentY, 0)
            verify(!drift.isDrifting)
        }

        function test_verticalWheelScrollsAcross() {
            mouseWheel(across, 100, 100, 0, -120)
            tryVerify(() => !acrossDrift.isDrifting)
            compare(across.contentX, Motion.drift.notch)
            acrossDrift.isReversed = true
            mouseWheel(across, 100, 100, 0, -120)
            tryVerify(() => !acrossDrift.isDrifting)
            compare(across.contentX, 0)
        }
    }
}
