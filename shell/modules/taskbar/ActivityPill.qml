import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: pill

    required property Item host
    property string mode: "idle"
    property string leadKey: "media"
    property var liveKeys: []

    readonly property real thickness: Appearance.taskbar.thickness
    readonly property real spineX: thickness / 2
    readonly property string face: mode === "hidden" ? "idle" : mode
    readonly property bool isShown: host.isRevealed && !host.isEaten && mode !== "hidden"
    readonly property size expandedSize: leadKey === "call"
        ? Qt.size(Appearance.activity.call.width, Appearance.activity.call.height)
        : Qt.size(Appearance.activity.media.width, Appearance.activity.media.height)
    readonly property real targetWidth: face === "expanded" ? expandedSize.width : face === "active" ? Appearance.activity.width : Appearance.activity.bead
    readonly property real targetHeight: face === "expanded" ? expandedSize.height : face === "active" ? Appearance.activity.length : Appearance.activity.bead
    readonly property real popScale: mutate.pop
    readonly property real bodyWidth: reshape.width
    readonly property real bodyHeight: reshape.height
    readonly property real bodyLeft: spineX - Math.min(bodyWidth, Appearance.activity.width) / 2
    readonly property real expandedLeft: spineX - Appearance.activity.width / 2
    readonly property real expansion: Math.max(0, (bodyWidth - Appearance.activity.width) / Math.max(1, expandedSize.width - Appearance.activity.width))
    readonly property bool isFaceShown: mutate.isInnerShown && reshape.isArrived
    readonly property var satellites: liveKeys.filter(key => key !== leadKey)
    readonly property real satellitePitch: Appearance.activity.satellite + Appearance.activity.satelliteGap
    readonly property bool areSatellitesShown: face === "active" && isShown
    readonly property real extent: Appearance.activity.length / 2 + satellites.length * satellitePitch
    readonly property real reachRight: x + bodyLeft + Math.max(bodyWidth, Appearance.activity.media.head * Math.min(1, expansion)) * popScale + Appearance.taskbar.idleGap

    signal modeRequested(string mode)
    signal leadRequested(int direction)

    width: thickness
    height: 0

    function bodyRect() {
        const width = bodyWidth * popScale
        const height = bodyHeight * popScale
        return Qt.rect(x + bodyLeft + bodyWidth * (1 - popScale) / 2, y - height / 2, width, height)
    }

    Mutate {
        id: mutate
        isShown: pill.isShown
        hasSpread: false
        enterDelay: Motion.reveal.stagger
        leaveDelay: Motion.activity.faceLeave
        popDuration: Motion.stateDuration
    }

    Reshape {
        id: reshape
        targetWidth: pill.targetWidth
        targetHeight: pill.targetHeight
        growDuration: Motion.pace(pill.face === "expanded" ? Motion.activity.expand : Motion.activity.spread)
        shrinkDuration: Motion.pace(Motion.activity.shrink)
        shrinkDelay: Motion.pace(Motion.activity.shrinkDelay)
        lag: Motion.pace(Motion.activity.lag)
        overshoot: Motion.activity.overshoot
        arriveShare: Motion.activity.arriveShare
    }

    EdgeFuse {
        readonly property real body: pill.bodyHeight * pill.popScale
        parent: pill.host.liquidShapes
        reach: pill.x + pill.spineX
        bodyTop: pill.y - body / 2
        length: body
        share: pill.host.fuse
    }

    LiquidShape {
        parent: pill.host.liquidShapes
        width: pill.bodyWidth
        height: pill.bodyHeight
        x: pill.x + pill.bodyLeft
        y: pill.y - height / 2
        transform: Scale {
            origin.x: pill.bodyWidth / 2
            origin.y: pill.bodyHeight / 2
            xScale: pill.popScale
            yScale: pill.popScale
        }
    }

    Repeater {
        parent: pill.host.liquidShapes
        model: pill.satellites.length

        LiquidShape {
            id: satellite
            required property int index
            readonly property real size: Appearance.activity.satellite * satellitePop.pop * pill.popScale
            visible: size > 0.5
            width: size
            height: size
            x: pill.x + pill.spineX - size / 2
            y: pill.y + pill.bodyHeight / 2 + Appearance.activity.satelliteGap + Appearance.activity.satellite / 2 + index * pill.satellitePitch - size / 2

            Mutate {
                id: satellitePop
                isShown: pill.areSatellitesShown && reshape.isArrived
                hasSpread: false
                enterDelay: (satellite.index + 1) * Motion.activity.stagger
                leaveDelay: 0
                popDuration: Motion.activity.satelliteEnter
            }
        }
    }

    MouseArea {
        id: area
        x: pill.bodyLeft
        y: -pill.bodyHeight / 2
        width: pill.bodyWidth
        height: pill.bodyHeight
        enabled: pill.isShown
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.modeRequested(pill.face === "idle" ? "active" : pill.face === "active" ? "expanded" : "active")
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0)
                pill.leadRequested(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Turn {
        x: pill.spineX - width / 2
        y: -height / 2
        width: Appearance.activity.speck
        height: Appearance.activity.speck
        isShown: pill.isFaceShown && pill.face === "idle"
        enterDuration: Motion.activity.faceEnter
        leaveDuration: Motion.activity.faceLeave
        leaveWindow: 0

        Rectangle {
            width: Appearance.activity.speck
            height: width
            radius: width / 2
            color: area.containsMouse ? Appearance.color.accent : Appearance.color.textMuted
        }
    }

    Repeater {
        model: Activities.keys

        ActivityGlance {
            required property string modelData
            key: modelData
            isMirrored: pill.host.isMirrored
            x: pill.spineX - width / 2
            y: -height / 2
            isShown: pill.isFaceShown && pill.face === "active" && pill.leadKey === modelData
            isPressed: area.pressed
        }
    }

    ActivityMedia {
        host: pill.host
        pill: pill
        x: pill.expandedLeft
        y: -height / 2
        expansion: pill.leadKey === "media" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "media"
    }

    ActivityCall {
        host: pill.host
        pill: pill
        x: pill.expandedLeft
        y: -height / 2
        expansion: pill.leadKey === "call" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "call"
    }
}
