import QtQuick
import qs.config

Item {
    id: edgePull

    required property var look
    required property var pace
    property bool isEnabled: true
    property Item shapes: null
    property real pull: 0
    property real dwell: 0
    property real beadY: height / 2

    signal summoned()

    onIsEnabledChanged: {
        if (!isEnabled) {
            dwellCharge.stop()
            dwellRelease.restart()
            pullRelease.restart()
        }
    }

    LiquidShape {
        readonly property real reach: Math.max(edgePull.pull, edgePull.dwell * edgePull.pace.beadReach)
        parent: edgePull.shapes
        height: edgePull.look.bead + Math.min(edgePull.look.bead, reach * edgePull.look.beadGrowth)
        width: reach + height
        x: -height
        y: edgePull.beadY - height / 2
    }

    Item {
        width: edgePull.look.edgeStrip
        height: parent.height

        HoverHandler {
            enabled: edgePull.isEnabled
            onPointChanged: edgePull.beadY = point.position.y
            onHoveredChanged: {
                if (hovered) {
                    dwellRelease.stop()
                    dwellCharge.restart()
                } else {
                    dwellCharge.stop()
                    dwellRelease.restart()
                }
            }
        }

        Gesture {
            anchors.fill: parent
            enabled: edgePull.isEnabled
            threshold: edgePull.pace.pullThreshold
            isVertical: false
            onPressed: mouse => {
                edgePull.beadY = mouse.y
                pullRelease.stop()
            }
            onMoved: (travelX, travelY) => {
                edgePull.pull = Math.min(edgePull.pace.pullLimit, Math.max(0, travelX))
                edgePull.beadY = pressPoint.y + travelY
            }
            onCrossed: (travelX, travelY) => {
                if (travelX > 0)
                    edgePull.summoned()
            }
            onEnded: pullRelease.restart()
        }
    }

    NumberAnimation {
        paused: Motion.isHeld && running
        id: dwellCharge
        target: edgePull
        property: "dwell"
        to: 1
        duration: edgePull.pace.dwell
        easing.type: Easing.InOutSine
        onFinished: edgePull.summoned()
    }

    NumberAnimation {
        paused: Motion.isHeld && running
        id: dwellRelease
        target: edgePull
        property: "dwell"
        to: 0
        duration: Motion.pace(Motion.hoverOut)
        easing.type: Easing.InQuad
    }

    NumberAnimation {
        paused: Motion.isHeld && running
        id: pullRelease
        target: edgePull
        property: "pull"
        to: 0
        duration: Motion.pace(Motion.stateDuration)
        easing.type: Easing.InBack
    }
}
