import QtQuick
import qs.config

Item {
    id: edgePull

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
        readonly property real reach: Math.max(edgePull.pull, edgePull.dwell * Motion.reveal.beadReach)
        parent: edgePull.shapes
        height: Appearance.taskbar.bead + Math.min(Appearance.taskbar.bead, reach * Appearance.taskbar.beadGrowth)
        width: reach + height
        x: -height
        y: edgePull.beadY - height / 2
    }

    Item {
        width: Appearance.taskbar.edgeStrip
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

        MouseArea {
            property real startX: 0

            anchors.fill: parent
            enabled: edgePull.isEnabled
            onPressed: mouse => {
                startX = mouse.x
                edgePull.beadY = mouse.y
                pullRelease.stop()
            }
            onPositionChanged: mouse => {
                const distance = Math.max(0, mouse.x - startX)
                edgePull.pull = Math.min(Motion.reveal.pullLimit, distance)
                edgePull.beadY = mouse.y
                if (distance >= Motion.reveal.pullThreshold)
                    edgePull.summoned()
            }
            onReleased: pullRelease.restart()
            onCanceled: pullRelease.restart()
        }
    }

    NumberAnimation {
        id: dwellCharge
        target: edgePull
        property: "dwell"
        to: 1
        duration: Motion.reveal.dwell
        easing.type: Easing.InOutSine
        onFinished: edgePull.summoned()
    }

    NumberAnimation {
        id: dwellRelease
        target: edgePull
        property: "dwell"
        to: 0
        duration: Motion.hoverOut
        easing.type: Easing.InQuad
    }

    NumberAnimation {
        id: pullRelease
        target: edgePull
        property: "pull"
        to: 0
        duration: Motion.stateDuration
        easing.type: Easing.InBack
    }
}
