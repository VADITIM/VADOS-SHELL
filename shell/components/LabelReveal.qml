import QtQuick
import qs.config
import "../utils/Playing.js" as Playing

Item {
    id: reveal

    property bool isShown: false
    property string label: "label"
    property real sweepWidth: width
    property int leaveDuration: Motion.sweep.leave
    property color barColor: Appearance.color.accent
    property real openShare: 0
    property real barShare: 0
    property bool isBarLeading: true
    default property alias content: clipper.data
    readonly property string playing: sweep.running ? label + " enter" : reopening.running ? label + " enter" : closing.running ? label + " leave" : ""

    function play() {
        if (isShown) {
            closing.stop()
            if (openShare >= 1)
                return
            if (openShare > 0) {
                reopening.restart()
                return
            }
            sweep.restart()
            return
        }
        sweep.stop()
        reopening.stop()
        barShare = 0
        if (openShare <= 0)
            return
        closing.restart()
    }

    onIsShownChanged: play()
    Component.onCompleted: {
        Playing.enlist(reveal)
        if (isShown)
            play()
    }
    Component.onDestruction: Playing.delist(reveal)

    Item {
        id: clipper
        width: reveal.width * reveal.openShare
        height: reveal.height
        clip: true
    }

    Rectangle {
        x: reveal.isBarLeading ? 0 : reveal.sweepWidth * (1 - reveal.barShare)
        y: -reveal.height * 0.06
        width: reveal.sweepWidth * reveal.barShare
        height: reveal.height * 1.12
        visible: reveal.barShare > 0
        color: reveal.barColor
    }

    SequentialAnimation {
        id: sweep
        paused: Motion.isHeld && running
        ScriptAction {
            script: {
                reveal.openShare = 0
                reveal.isBarLeading = true
            }
        }
        NumberAnimation {
            target: reveal
            property: "barShare"
            from: 0
            to: 1
            duration: Motion.pace(Motion.sweep.grow)
            easing.type: Easing.InOutCubic
        }
        ScriptAction {
            script: {
                reveal.openShare = 1
                reveal.isBarLeading = false
            }
        }
        NumberAnimation {
            target: reveal
            property: "barShare"
            to: 0
            duration: Motion.pace(Motion.sweep.retract)
            easing.type: Easing.InOutCubic
        }
    }

    NumberAnimation {
        id: reopening
        paused: Motion.isHeld && running
        target: reveal
        property: "openShare"
        to: 1
        duration: Motion.pace(Motion.sweep.leave)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closing
        paused: Motion.isHeld && running
        target: reveal
        property: "openShare"
        to: 0
        duration: Motion.pace(reveal.leaveDuration)
        easing.type: Easing.InCubic
    }
}
