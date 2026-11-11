import QtQuick
import qs.config

Item {
    id: edgePull

    required property var look
    required property var pace
    property bool isEnabled: true
    property Item shapes: null
    property real dwell: 0
    property real beadY: height / 2

    signal summoned()

    onIsEnabledChanged: {
        if (!isEnabled) {
            dwellCharge.stop()
            dwellRelease.restart()
        }
    }

    LiquidShape {
        readonly property real reach: edgePull.dwell * edgePull.pace.beadReach
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
}
