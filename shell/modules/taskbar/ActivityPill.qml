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
    property bool isClipboardOpen: false
    property size clipboardSize: Qt.size(0, 0)
    property bool isClipboardBody: false

    readonly property real thickness: Appearance.taskbar.thickness
    readonly property real spineX: thickness / 2
    readonly property string face: isAlerting ? "alert" : isClipboardOpen ? "clipboard" : mode === "hidden" ? "idle" : mode
    readonly property bool isSummoned: isAlerting || isClipboardOpen
    readonly property bool isShown: (host.isRevealed || (isSummoned && !host.isAway)) && !host.isEaten && (mode !== "hidden" || isSummoned)
    readonly property var views: ({ recording: recordingView, media: mediaView, call: callView, tray: trayView })
    readonly property size expandedSize: (views[leadKey] ?? mediaView).bodySize
    readonly property size faceSize: face === "alert" ? alertSize
        : face === "clipboard" ? clipboardSize
        : face === "expanded" ? expandedSize
        : face === "active" ? Qt.size(Appearance.activity.width, Appearance.activity.length)
        : Qt.size(Appearance.activity.bead, Appearance.activity.bead)
    readonly property real targetWidth: isShown ? faceSize.width : Appearance.activity.bead
    readonly property real targetHeight: isShown ? faceSize.height : Appearance.activity.bead
    readonly property bool isSpreadBody: isAlertBody || isClipboardBody
    readonly property real popScale: mutate.pop
    readonly property real bodyWidth: reshape.width
    readonly property real bodyHeight: reshape.height
    readonly property real bodyLeft: spineX - Math.min(bodyWidth, Appearance.activity.width) / 2
    readonly property real expandedLeft: spineX - Appearance.activity.width / 2
    readonly property real expansion: isSpreadBody ? 0 : Math.max(0, (bodyWidth - Appearance.activity.width) / Math.max(1, expandedSize.width - Appearance.activity.width))
    readonly property real carry: Appearance.activity.carry * (1 - Math.min(1, expansion))
    readonly property bool isFaceShown: mutate.isInnerShown && reshape.isArrived
    property bool hasAlertArrived: false
    readonly property bool isAlertShown: face === "alert" && mutate.isInnerShown && (reshape.isArrived || hasAlertArrived)
    readonly property bool isClipboardShown: isFaceShown && face === "clipboard"
    readonly property rect spreadRect: Qt.rect(x + expandedLeft, y - bodyHeight / 2, bodyWidth, bodyHeight)
    readonly property var satellites: liveKeys.filter(key => key !== leadKey)
    readonly property real satellitePitch: Appearance.activity.satellite + Appearance.activity.satelliteGap
    readonly property bool areSatellitesShown: face === "active" && isShown
    readonly property real extent: Appearance.activity.length / 2 + satellites.length * satellitePitch
    readonly property bool hasBump: liveKeys.includes(leadKey)
    readonly property real bumpSize: Appearance.clipboard.bump * bumpPop.pop * popScale
    readonly property real bumpRestX: expandedLeft + bodyWidth - Appearance.clipboard.bumpOverlap + Appearance.clipboard.bump / 2
    readonly property real bumpCenterX: bumpRestX + bumpReach
    readonly property real bumpCenterY: -bodyHeight / 2 + Appearance.clipboard.padding + Appearance.clipboard.header / 2
    property real bumpReach: bumpArea.containsMouse ? Appearance.clipboard.bumpReach : 0
    readonly property bool isBumpHovered: bumpArea.containsMouse
    readonly property bool isRecordingLead: leadKey === "recording"
    property bool hasHoveredRecording: false
    readonly property real reachRight: x + bodyLeft + Math.max(bodyWidth, Appearance.activity.media.head * Math.min(1, expansion), bumpSize > 0.5 ? bumpCenterX - bodyLeft + bumpSize / 2 : 0) * popScale + Appearance.taskbar.idleGap

    signal modeRequested(string mode)
    signal leadRequested(int direction)

    width: thickness
    height: 0

    onFaceChanged: {
        if (face !== "expanded")
            hasHoveredRecording = false
        if (face !== "alert")
            hasAlertArrived = false
        if (face === "alert")
            isAlertBody = true
        if (face === "clipboard")
            isClipboardBody = true
    }

    Behavior on bumpReach {
        NumberAnimation {
            duration: Motion.pace(Motion.clipboard.bump)
            easing.type: Easing.OutBack
        }
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
        isHolding: pill.host.isHoldingParts
        leaveDelay: Motion.pill.sling
        popDuration: Motion.stateDuration
        onIsInnerShownChanged: {
            if (!isInnerShown)
                pill.hasAlertArrived = false
        }
    }

    Reshape {
        id: reshape
        targetWidth: pill.targetWidth
        targetHeight: pill.targetHeight
        growDuration: Motion.pace(pill.face === "alert" ? Motion.alerts.grow : pill.face === "clipboard" ? Motion.clipboard.grow : pill.face === "expanded" ? Motion.activity.expand : Motion.activity.spread)
        shrinkDuration: Motion.pace(pill.isAlertBody ? Motion.alerts.shrink : pill.isClipboardBody ? Motion.clipboard.shrink : Motion.activity.shrink)
        shrinkDelay: Motion.pace(pill.isAlertBody ? Motion.alerts.shrinkDelay : pill.isClipboardBody ? Motion.clipboard.shrinkDelay : Motion.activity.shrinkDelay)
        shrinkLag: Motion.pace(pill.isClipboardBody ? Motion.clipboard.shrinkLag : Motion.activity.shrinkLag)
        shrinkEasing: Easing.InBack
        windUp: Motion.activity.windUp
        shrinkArriveShare: 1
        lag: Motion.pace(pill.face === "alert" ? Motion.alerts.lag : pill.face === "clipboard" ? Motion.clipboard.lag : Motion.activity.lag)
        overshoot: pill.face === "alert" ? Motion.alerts.overshoot : pill.face === "clipboard" ? Motion.clipboard.overshoot : Motion.activity.overshoot
        arriveShare: pill.face === "alert" ? Motion.alerts.arriveShare : pill.face === "clipboard" ? Motion.clipboard.arriveShare : Motion.activity.arriveShare
        onIsArrivedChanged: {
            if (!isArrived)
                return
            pill.hasAlertArrived = pill.face === "alert" && mutate.isInnerShown
            if (pill.face !== "alert")
                pill.isAlertBody = false
            if (pill.face !== "clipboard")
                pill.isClipboardBody = false
        }
    }

    Gulp {
        id: gulp
        label: "activity pill gulp"
        isLanded: !reshape.motion.running && !reshape.isGrowing
        amplitude: Appearance.activity.gulp
        span: Motion.activity.gulp
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
        readonly property real swellWidth: gulp.swell
        readonly property real swellHeight: gulp.swell * Appearance.activity.gulpStretch
        parent: pill.host.liquidShapes
        width: pill.bodyWidth + swellWidth
        height: pill.bodyHeight + swellHeight
        radius: Math.min(Math.min(width, height) / 2, pill.isClipboardBody ? Appearance.clipboard.radius : pill.isAlertBody ? Appearance.alerts.radius : Infinity)
        x: pill.x + pill.bodyLeft - swellWidth / 2
        y: pill.y - height / 2
        transform: Scale {
            origin.x: (pill.bodyWidth + gulp.swell) / 2
            origin.y: (pill.bodyHeight + gulp.swell * Appearance.activity.gulpStretch) / 2
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

    LiquidShape {
        parent: pill.host.liquidShapes
        visible: pill.bumpSize > 0.5
        width: pill.bumpSize
        height: pill.bumpSize
        x: pill.x + pill.bumpCenterX - width / 2
        y: pill.y + pill.bumpCenterY - height / 2
    }

    Mutate {
        id: bumpPop
        label: "clipboard bump"
        isShown: pill.isClipboardShown && pill.hasBump
        hasSpread: false
        leaveDelay: 0
        popDuration: Motion.clipboard.bump
    }

    MouseArea {
        id: area
        x: pill.bodyLeft
        y: -pill.bodyHeight / 2
        width: pill.bodyWidth
        height: pill.bodyHeight
        enabled: pill.isShown && !pill.isSummoned
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (pill.face === "active" && pill.isRecordingLead && Capture.canPause) {
                Capture.togglePause()
                return
            }
            pill.modeRequested(pill.face === "idle" ? "active" : pill.face === "active" ? "expanded" : "active")
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0)
                pill.leadRequested(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Item {
        x: pill.bodyLeft
        y: -pill.bodyHeight / 2
        width: pill.bodyWidth
        height: pill.bodyHeight
        enabled: pill.isShown && !pill.isSummoned

        HoverHandler {
            id: bodyHover
            onHoveredChanged: {
                if (hovered && pill.isRecordingLead)
                    pill.hasHoveredRecording = true
            }
        }
    }

    Timer {
        interval: Motion.capture.dwell
        running: pill.isRecordingLead && pill.face === "active" && bodyHover.hovered
        onTriggered: {
            pill.hasHoveredRecording = true
            pill.modeRequested("expanded")
        }
    }

    Timer {
        interval: Motion.capture.linger
        running: pill.isRecordingLead && pill.face === "expanded" && pill.hasHoveredRecording && !bodyHover.hovered
        onTriggered: pill.modeRequested("active")
    }

    MouseArea {
        id: bumpArea
        x: pill.bumpRestX - Appearance.clipboard.bump / 2
        y: pill.bumpCenterY - height / 2
        width: Appearance.clipboard.bump + Appearance.clipboard.bumpReach
        height: Appearance.clipboard.bump
        enabled: pill.isClipboardShown && pill.hasBump
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.modeRequested("expanded")
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0)
                pill.leadRequested(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Turn {
        id: bumpFace
        x: pill.bumpCenterX - width / 2
        y: pill.bumpCenterY - height / 2
        width: Appearance.clipboard.bumpGlyph
        height: Appearance.clipboard.bumpGlyph
        isShown: pill.isClipboardShown && pill.hasBump
        enterDelay: Motion.clipboard.stagger
        isSlung: true
        leaveWindow: 0

        Press {
            target: bumpFace
            isPressed: bumpArea.pressed
            depth: Motion.press.glyph
        }

        Glyph {
            width: Appearance.clipboard.bumpGlyph
            height: width
            name: Appearance.activity.glyphs[pill.leadKey] ?? "music"
            color: bumpArea.containsMouse ? Appearance.color.accent : Appearance.color.textBody
            transform: Upright {
                isMirrored: pill.host.isMirrored
                axis: Appearance.clipboard.bumpGlyph / 2
            }
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

    ActivityRecording {
        id: recordingView
        host: pill.host
        pill: pill
        x: pill.expandedLeft - pill.carry
        y: -height / 2
        expansion: pill.leadKey === "recording" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "recording"
    }

    ActivityMedia {
        id: mediaView
        host: pill.host
        pill: pill
        x: pill.expandedLeft - pill.carry
        y: -height / 2
        expansion: pill.leadKey === "media" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "media"
    }

    ActivityCall {
        id: callView
        host: pill.host
        pill: pill
        x: pill.expandedLeft - pill.carry
        y: -height / 2
        expansion: pill.leadKey === "call" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "call"
    }

    ActivityTray {
        id: trayView
        host: pill.host
        pill: pill
        x: pill.expandedLeft - pill.carry
        y: -height / 2
        expansion: pill.leadKey === "tray" ? pill.expansion : 0
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey === "tray"
    }
}
