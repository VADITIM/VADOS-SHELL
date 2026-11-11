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
    property bool isAlerting: false
    property size alertSize: Qt.size(0, 0)
    property bool isAlertBody: false

    readonly property real thickness: Appearance.taskbar.thickness
    readonly property real spineX: thickness / 2
    readonly property string face: isAlerting ? "alert" : mode === "hidden" ? "idle" : mode
    readonly property bool isShown: (host.isRevealed || (isAlerting && !host.isAway)) && !host.isEaten && (mode !== "hidden" || isAlerting)
    readonly property var views: ({ media: mediaView, call: callView, tray: trayView })
    readonly property size expandedSize: (views[leadKey] ?? mediaView).bodySize
    readonly property real targetWidth: !isShown ? Appearance.activity.bead : face === "alert" ? alertSize.width : face === "expanded" ? expandedSize.width : face === "active" ? Appearance.activity.width : Appearance.activity.bead
    readonly property real targetHeight: !isShown ? Appearance.activity.bead : face === "alert" ? alertSize.height : face === "expanded" ? expandedSize.height : face === "active" ? Appearance.activity.length : Appearance.activity.bead
    readonly property real popScale: mutate.pop
    readonly property real bodyWidth: reshape.width
    readonly property real bodyHeight: reshape.height
    readonly property real bodyLeft: spineX - Math.min(bodyWidth, Appearance.activity.width) / 2
    readonly property real expandedLeft: spineX - Appearance.activity.width / 2
    readonly property real expansion: isAlertBody ? 0 : Math.max(0, (bodyWidth - Appearance.activity.width) / Math.max(1, expandedSize.width - Appearance.activity.width))
    readonly property bool isFaceShown: mutate.isInnerShown && reshape.isArrived
    readonly property bool isAlertShown: isFaceShown && face === "alert"
    readonly property rect alertRect: Qt.rect(x + expandedLeft, y - bodyHeight / 2, bodyWidth, bodyHeight)
    readonly property var satellites: liveKeys.filter(key => key !== leadKey)
    readonly property real satellitePitch: Appearance.activity.satellite + Appearance.activity.satelliteGap
    readonly property bool areSatellitesShown: face === "active" && isShown
    readonly property real extent: Appearance.activity.length / 2 + satellites.length * satellitePitch
    readonly property real reachRight: x + bodyLeft + Math.max(bodyWidth, Appearance.activity.media.head * Math.min(1, expansion)) * popScale + Appearance.taskbar.idleGap

    signal modeRequested(string mode)
    signal leadRequested(int direction)

    width: thickness
    height: 0

    onFaceChanged: {
        if (face === "alert")
            isAlertBody = true
    }

    function bodyRect() {
        const width = bodyWidth * popScale
        const height = bodyHeight * popScale
        return Qt.rect(x + bodyLeft + bodyWidth * (1 - popScale) / 2, y - height / 2, width, height)
    }

    Mutate {
        id: mutate
        label: "activity pill"
        isShown: pill.isShown
        isArriving: pill.host.isArriving
        hasArrived: pill.host.hasArrivedAt(pill.y)
        hasSpread: false
        enterDelay: Motion.reveal.stagger
        isHolding: pill.host.isGathering
        leaveDelay: Motion.pill.sling
        popDuration: Motion.stateDuration
    }

    Reshape {
        id: reshape
        targetWidth: pill.targetWidth
        targetHeight: pill.targetHeight
        growDuration: Motion.pace(pill.face === "alert" ? Motion.alerts.grow : pill.face === "expanded" ? Motion.activity.expand : Motion.activity.spread)
        shrinkDuration: Motion.pace(pill.isAlertBody ? Motion.alerts.shrink : Motion.activity.shrink)
        shrinkDelay: Motion.pace(pill.isAlertBody ? Motion.alerts.shrinkDelay : Motion.activity.shrinkDelay)
        lag: Motion.pace(pill.face === "alert" ? Motion.alerts.lag : Motion.activity.lag)
        overshoot: pill.face === "alert" ? Motion.alerts.overshoot : Motion.activity.overshoot
        arriveShare: pill.face === "alert" ? Motion.alerts.arriveShare : Motion.activity.arriveShare
        onIsArrivedChanged: {
            if (isArrived && pill.face !== "alert")
                pill.isAlertBody = false
        }
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
                label: "activity satellite"
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
        enabled: pill.isShown && pill.face !== "alert"
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
        isSlung: true
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
        id: mediaView
        host: pill.host
        pill: pill
        x: pill.expandedLeft
        y: -height / 2
        expansion: pill.leadKey === "media" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "media"
    }

    ActivityCall {
        id: callView
        host: pill.host
        pill: pill
        x: pill.expandedLeft
        y: -height / 2
        expansion: pill.leadKey === "call" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "call"
    }

    ActivityTray {
        id: trayView
        host: pill.host
        pill: pill
        x: pill.expandedLeft
        y: -height / 2
        expansion: pill.leadKey === "tray" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "tray"
    }
}
