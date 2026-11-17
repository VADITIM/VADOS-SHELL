import QtQuick
import qs.config
import qs.components
import "../../utils/Locking.js" as Locking
import "../../utils/Geometry.js" as Geometry

Item {
    id: leave

    property bool isMain: true
    property var layout: []
    property var parts: []
    property bool isMirrored: false
    property bool hasLanded: false

    readonly property var look: Appearance.lock
    readonly property var pace: Motion.lock
    readonly property string phase: lifecycle.phase
    readonly property bool isPresent: lifecycle.isPresent
    readonly property var frames: isMain ? Locking.layoutOf(layout).map(placement => Locking.rectOf(placement, width, height, look.gap)) : []
    readonly property var delays: Locking.delays(frames.length, pace.convergeStagger, Math.random)
    readonly property int longestDelay: delays.reduce((longest, delay) => Math.max(longest, delay), 0)
    readonly property int convergeSpan: frames.length > 0 ? pace.converge + longestDelay : 0
    readonly property real spineEdge: parts.length > 0 ? parts[0].x + parts[0].width / 2 : Appearance.taskbar.margin + Appearance.taskbar.thickness / 2
    readonly property real spineX: isMirrored ? width - spineEdge : spineEdge
    readonly property real spillTop: parts.length > 0 ? Math.min(...parts.map(part => part.y)) : Appearance.taskbar.margin
    readonly property real spillBottom: parts.length > 0 ? Math.max(...parts.map(part => part.y + part.height)) : height - Appearance.taskbar.margin
    readonly property point sink: Qt.point(spineX, (spillTop + spillBottom) / 2)
    readonly property var emptyFrame: ({ x: 0, y: 0, width: 0, height: 0 })

    signal spilled()
    signal landed()

    function shareOf(index) {
        if (converge.isLanded)
            return 1
        return Geometry.clampUnit((converge.share * convergeSpan - (delays[index] ?? 0)) / pace.converge)
    }

    function land() {
        if (hasLanded)
            return
        hasLanded = true
        landed()
    }

    Lifecycle {
        id: lifecycle
        name: "unlock"
        onMoved: (from, to, event) => {
            if (to === "preparing")
                send("prepared")
            else if (to === "active")
                send("hide")
            else if (to === "exiting")
                leave.hasLanded = false
            else if (to === "idle")
                leave.land()
        }
    }

    Throw {
        id: converge
        label: "unlock converge"
        isThrown: leave.phase === "entering" || leave.phase === "active" || leave.phase === "exiting"
        span: leave.convergeSpan
        easing: Easing.Linear
        onIsLandedChanged: if (isLanded) Qt.callLater(lifecycle.send, "entered")
    }

    Throw {
        id: spill
        label: "unlock spill"
        isThrown: lifecycle.isLeaving
        span: leave.pace.spill
        easing: Easing.OutCubic
        onIsLandedChanged: if (isLanded) leave.spilled()
    }

    Throw {
        id: evaporate
        label: "unlock evaporate"
        isThrown: spill.isLanded
        span: leave.pace.evaporate
        easing: Easing.InQuad
        onIsLandedChanged: if (isLanded) Qt.callLater(lifecycle.send, "exited")
    }

    Component.onCompleted: lifecycle.send("show")

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: leave.isPresent
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: leave.look.melt
        opacity: 1 - evaporate.share

        Item {
            parent: liquid.shapes
            anchors.fill: parent

            Repeater {
                model: leave.frames.length

                Squircle {
                    required property int index
                    readonly property var frame: leave.frames[index] ?? leave.emptyFrame
                    readonly property real share: leave.shareOf(index)
                    readonly property real eased: share * share

                    visible: share < 1
                    color: "white"
                    corner: leave.look.corner
                    width: Math.max(1, Geometry.mix(frame.width, leave.look.drop, eased))
                    height: Math.max(1, Geometry.mix(frame.height, leave.look.drop, eased))
                    x: Geometry.mix(frame.x + frame.width / 2, leave.sink.x, eased) - width / 2
                    y: Geometry.mix(frame.y + frame.height / 2, leave.sink.y, eased) - height / 2
                }
            }

            LiquidShape {
                readonly property real gathered: leave.frames.length === 0 ? 1 : Geometry.clampUnit(converge.share * leave.look.dropGrowth)

                width: leave.look.spillWidth * (1 - evaporate.share)
                height: spill.isThrown ? Geometry.mix(leave.look.drop, leave.spillBottom - leave.spillTop, spill.share) : leave.look.drop * gathered
                x: leave.sink.x - width / 2
                y: leave.sink.y - height / 2
                visible: leave.isPresent && width > 0.5 && height > 0.5
            }
        }
    }
}
