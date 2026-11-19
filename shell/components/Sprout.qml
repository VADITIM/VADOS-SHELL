import QtQuick
import qs.config
import "../utils/Liquid.js" as Liquid
import "../utils/Geometry.js" as Geometry
import "../utils/Playing.js" as Playing

Item {
    id: sprout

    required property var look
    required property var pace
    property bool isShown: false
    property string label: "sprout"
    property int enterDelay: 0
    property int leaveWindow: 0
    property var character: Motion.liquid.snap
    property real riseTime: 0
    property real leaveFrom: 0
    property real leaveShare: 1
    property bool isLeaving: false
    readonly property real presence: isLeaving ? leaveFrom * leaveShare
        : riseTime >= pace.enter ? 1
        : Liquid.rise(character, riseTime / 1000)
    readonly property real settled: Geometry.clampUnit(presence)
    readonly property string playing: arrival.running ? label + " enter" : departure.running ? label + " leave" : ""

    signal departed()

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    opacity: Math.min(1, settled * look.fade)
    transform: [
        Scale {
            origin.x: 0
            origin.y: sprout.height / 2
            xScale: Math.max(0.001, sprout.look.seed + (1 - sprout.look.seed) * sprout.presence)
            yScale: Math.max(0.001, sprout.look.seed + (1 - sprout.look.seed) * sprout.presence)
        },
        Translate {
            x: -sprout.look.reach * (1 - sprout.presence)
            y: sprout.look.rise * (1 - sprout.presence)
        }
    ]

    function play() {
        if (isShown) {
            departure.stop()
            if (isLeaving) {
                riseTime = timeAt(settled)
                isLeaving = false
            }
            if (presence >= 1 && riseTime >= pace.enter)
                return
            arrivalPause.duration = Motion.pace(enterDelay)
            arrival.restart()
            return
        }
        arrival.stop()
        if (isLeaving || presence <= 0) {
            if (presence <= 0)
                departed()
            return
        }
        leaveFrom = settled
        leaveShare = 1
        isLeaving = true
        departurePause.duration = Motion.pace(Math.random() * leaveWindow)
        departure.restart()
    }

    function timeAt(value) {
        const peak = Liquid.arrival(character) * 1000
        let time = 0
        while (time < peak && Liquid.rise(character, time / 1000) < value)
            time += pace.probe
        return Math.min(time, pace.enter)
    }

    function snap(value) {
        arrival.stop()
        departure.stop()
        isLeaving = value <= 0
        leaveFrom = 0
        riseTime = value > 0 ? pace.enter : 0
    }

    onIsShownChanged: play()
    Component.onCompleted: {
        Playing.enlist(sprout)
        if (isShown)
            play()
    }
    Component.onDestruction: {
        arrival.stop()
        departure.stop()
        Playing.delist(sprout)
    }

    SequentialAnimation {
        id: arrival
        paused: Motion.isHeld && running
        PauseAnimation { id: arrivalPause }
        NumberAnimation {
            target: sprout
            property: "riseTime"
            to: sprout.pace.enter
            duration: Motion.pace(Math.max(1, sprout.pace.enter - sprout.riseTime))
        }
    }

    SequentialAnimation {
        id: departure
        paused: Motion.isHeld && running
        PauseAnimation { id: departurePause }
        NumberAnimation {
            target: sprout
            property: "leaveShare"
            to: 0
            duration: Motion.pace(sprout.pace.leave)
            easing.type: Easing.InBack
        }
        ScriptAction {
            script: {
                sprout.riseTime = 0
                sprout.departed()
            }
        }
    }
}
