import QtQuick
import qs.config

Item {
    id: turn

    property bool isShown: false
    property int enterDelay: 0
    property int enterWindow: 0
    property int enterDuration: Motion.pill.element
    property int leaveDelay: 0
    property int leaveWindow: Motion.pill.leaveWindow
    property int leaveDuration: Motion.pill.leaveElement
    property int enterEasing: Easing.OutQuad
    property real presence: 0
    property bool isFlipping: true
    property real flipAngle: -90
    property real spinAngle: 0
    property bool isSlung: false
    readonly property real shape: isFlipping || isSlung ? presence : 1

    signal departed()

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    opacity: Math.min(1, shape * 1.6)
    transform: [
        Rotation {
            origin.x: turn.width / 2
            origin.y: turn.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: turn.isSlung ? 0 : turn.flipAngle * (1 - turn.shape)
        },
        Rotation {
            origin.x: turn.width / 2
            origin.y: turn.height / 2
            angle: (turn.isSlung ? Motion.pill.slingSpin : turn.spinAngle) * (1 - turn.shape)
        },
        Scale {
            origin.x: turn.width / 2
            origin.y: turn.height / 2
            xScale: Math.max(0.001, turn.shape)
            yScale: Math.max(0.001, turn.shape)
        }
    ]

    function play() {
        if (isShown) {
            departure.stop()
            if (presence >= 1)
                return
            arrivalPause.duration = Motion.pace(enterDelay + Math.random() * enterWindow)
            arrival.restart()
            return
        }
        arrival.stop()
        if (presence <= 0) {
            departed()
            return
        }
        departurePause.duration = Motion.pace(leaveDelay + Math.random() * leaveWindow)
        departure.restart()
    }

    function snap(value) {
        arrival.stop()
        departure.stop()
        presence = value
    }

    onIsShownChanged: play()
    Component.onCompleted: if (isShown) play()
    Component.onDestruction: {
        arrival.stop()
        departure.stop()
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: arrival
        PauseAnimation { id: arrivalPause }
        NumberAnimation {
            target: turn
            property: "presence"
            to: 1
            duration: Motion.pace(turn.isSlung ? Motion.pill.slingIn : turn.enterDuration)
            easing.type: turn.isSlung ? Easing.OutBack : turn.enterEasing
            easing.overshoot: Motion.pill.slingBack
        }
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: departure
        PauseAnimation { id: departurePause }
        NumberAnimation {
            target: turn
            property: "presence"
            to: 0
            duration: Motion.pace(turn.isSlung ? Motion.pill.sling : turn.leaveDuration)
            easing.type: turn.isSlung ? Easing.InBack : Easing.InQuad
            easing.overshoot: Motion.pill.slingBack
        }
        ScriptAction { script: turn.departed() }
    }
}
