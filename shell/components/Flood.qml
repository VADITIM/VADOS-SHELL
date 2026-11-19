import QtQuick
import qs.config
import "../utils/Playing.js" as Playing

QtObject {
    id: flood

    property string label: "flood"
    property bool isShown: false
    property real share: 0
    property real presence: 0
    readonly property string playing: across.running || away.running ? label : ""

    readonly property ParallelAnimation across: ParallelAnimation {
        paused: Motion.isHeld && running

        NumberAnimation {
            target: flood
            property: "share"
            to: 1
            duration: Motion.pace(Motion.pill.floodIn)
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: flood
            property: "presence"
            to: 1
            duration: Motion.pace(Motion.pill.floodFade)
            easing.type: Easing.OutQuad
        }
    }

    readonly property NumberAnimation away: NumberAnimation {
        paused: Motion.isHeld && running
        target: flood
        property: "presence"
        to: 0
        duration: Motion.pace(Motion.pill.floodLeave)
        easing.type: Easing.InQuad
    }

    onIsShownChanged: {
        if (isShown) {
            away.stop()
            if (presence < 0.01)
                share = 0
            across.restart()
            return
        }
        across.stop()
        away.restart()
    }
    Component.onCompleted: Playing.enlist(flood)
    Component.onDestruction: {
        across.stop()
        away.stop()
        Playing.delist(flood)
    }
}
