import QtQuick
import qs.config

QtObject {
    id: reshape

    property real targetWidth: 0
    property real targetHeight: 0
    property int growDuration: 0
    property int shrinkDuration: 0
    property int shrinkDelay: 0
    property int lag: 0
    property real overshoot: 0
    property real arriveShare: 1
    property real width: 0
    property real height: 0
    property bool isArrived: true
    property bool isGrowing: false

    readonly property ParallelAnimation motion: ParallelAnimation {
        paused: Motion.isHeld && running
        SequentialAnimation {
            PauseAnimation { id: widthPause }
            NumberAnimation {
                id: widthMotion
                target: reshape
                property: "width"
            }
        }
        SequentialAnimation {
            PauseAnimation { id: heightPause }
            NumberAnimation {
                id: heightMotion
                target: reshape
                property: "height"
            }
        }
        SequentialAnimation {
            PauseAnimation { id: arrivePause }
            ScriptAction { script: reshape.isArrived = true }
        }
    }

    function changeOf(from, to) {
        return Math.abs(to - from) / Math.max(1, Math.max(from, to))
    }

    function play() {
        motion.stop()
        if (Math.abs(targetWidth - width) < 0.5 && Math.abs(targetHeight - height) < 0.5) {
            width = targetWidth
            height = targetHeight
            isArrived = true
            return
        }
        isGrowing = targetWidth * targetHeight >= width * height
        const isWidthLead = changeOf(width, targetWidth) >= changeOf(height, targetHeight)
        const duration = isGrowing ? growDuration : shrinkDuration
        const start = isGrowing ? 0 : shrinkDelay
        const trail = isGrowing ? lag : 0
        widthPause.duration = start + (isWidthLead ? 0 : trail)
        heightPause.duration = start + (isWidthLead ? trail : 0)
        for (const motionOf of [widthMotion, heightMotion]) {
            motionOf.duration = duration
            motionOf.easing.type = isGrowing ? Easing.OutBack : Easing.OutCubic
            motionOf.easing.overshoot = overshoot
        }
        widthMotion.to = targetWidth
        heightMotion.to = targetHeight
        arrivePause.duration = start + trail + duration * arriveShare
        isArrived = false
        motion.start()
    }

    onTargetWidthChanged: Qt.callLater(play)
    onTargetHeightChanged: Qt.callLater(play)
    Component.onCompleted: {
        width = targetWidth
        height = targetHeight
    }
}
