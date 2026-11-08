import QtQuick
import QtTest
import qs.components

Item {
    width: 400
    height: 400

    property var events: []

    Gesture {
        id: gesture
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        threshold: 20
        onPressed: mouse => {
            if (mouse.x > 350)
                mouse.accepted = false
        }
        onCrossed: events.push("crossed")
        onThrown: (travelX, travelY, velocityX) => events.push(velocityX > 0 ? "thrown forward" : "thrown")
        onTapped: mouse => events.push(mouse.button === Qt.MiddleButton ? "tapped middle" : "tapped")
        onEnded: events.push("ended")
    }

    TestCase {
        name: "Gesture"
        when: windowShown

        function init() {
            events = []
        }

        function test_tap() {
            mouseClick(gesture, 100, 100)
            compare(events, ["tapped", "ended"])
        }

        function test_dragIsNotATap() {
            mousePress(gesture, 100, 100)
            for (const x of [105, 112, 125, 160]) {
                wait(16)
                mouseMove(gesture, x, 100)
            }
            mouseRelease(gesture, 160, 100)
            compare(events, ["crossed", "thrown forward", "ended"])
        }

        function test_middleButtonNeverDrags() {
            mousePress(gesture, 100, 100, Qt.MiddleButton)
            mouseMove(gesture, 200, 100)
            mouseRelease(gesture, 200, 100, Qt.MiddleButton)
            compare(events, ["tapped middle", "ended"])
        }

        function test_rejectedPressDoesNothing() {
            mouseClick(gesture, 380, 100)
            compare(events, [])
        }
    }
}
