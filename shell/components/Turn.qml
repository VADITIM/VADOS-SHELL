import QtQuick
import qs.config

Item {
    id: turn

    property bool isShown: false
    property int enterDelay: 0
    property int enterWindow: 0
    property int enterDuration: Motion.pill.element
    property int leaveWindow: Motion.pill.leaveWindow
    property int leaveDuration: Motion.pill.leaveElement
    property int enterEasing: Easing.OutQuad
    property real presence: 0

    signal departed()

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    opacity: Math.min(1, presence * 1.6)
    transform: [
        Rotation {
            origin.x: turn.width / 2
            origin.y: turn.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: -90 * (1 - turn.presence)
        },
        Scale {
            origin.x: turn.width / 2
            origin.y: turn.height / 2
            xScale: Math.max(0.001, turn.presence)
            yScale: Math.max(0.001, turn.presence)
        }
    ]

    function play() {
        if (isShown) {
            departure.stop()
            if (presence >= 1)
                return
            arrivalPause.duration = enterDelay + Math.random() * enterWindow
            arrival.restart()
            return
        }
        arrival.stop()
        if (presence <= 0) {
            departed()
            return
        }
        departurePause.duration = Math.random() * leaveWindow
        departure.restart()
    }

    function snap(value) {
        arrival.stop()
        departure.stop()
        presence = value
    }

    onIsShownChanged: play()
    Component.onCompleted: if (isShown) play()

    SequentialAnimation {
        id: arrival
        PauseAnimation { id: arrivalPause }
        NumberAnimation {
            target: turn
            property: "presence"
            to: 1
            duration: turn.enterDuration
            easing.type: turn.enterEasing
        }
    }

    SequentialAnimation {
        id: departure
        PauseAnimation { id: departurePause }
        NumberAnimation {
            target: turn
            property: "presence"
            to: 0
            duration: turn.leaveDuration
            easing.type: Easing.InQuad
        }
        ScriptAction { script: turn.departed() }
    }
}
