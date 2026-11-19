import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/ActivityTabs.js" as Tabs

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
    readonly property var tabSpan: Tabs.spanOf(Activities.tabs, leadKey)
    readonly property bool isCovered: !isSummoned && host.isUnderExtension(null, y - Appearance.activity.length / 2 - tabSpan.above * dotPitch, y + extent)
    readonly property bool isShown: (host.isRevealed || (isSummoned && !host.isAway)) && !host.isEaten && !isCovered && (mode !== "hidden" || isSummoned)
    readonly property var views: ({ recording: recordingView, media: mediaView, call: callView })
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
    readonly property var tabs: Activities.tabs
    readonly property bool hasLiveDot: tabs.some(key => key !== leadKey && Activities.liveKeys.includes(key))
    readonly property real dotPitch: (hasLiveDot ? Appearance.activity.liveDot : Appearance.activity.dot) + Appearance.activity.dotGap
    readonly property bool areDotsShown: (face === "active" || face === "idle") && isShown
    readonly property real extent: Appearance.activity.length / 2 + tabSpan.below * dotPitch
    readonly property bool isRecordingLead: leadKey === "recording"
    property bool hasHoveredRecording: false
    readonly property real reachRight: x + bodyLeft + Math.max(bodyWidth, Appearance.activity.media.head * Math.min(1, expansion)) * popScale + Appearance.taskbar.idleGap

    function innerRestOf(slot) {
        const inner = slot < 0 ? Math.round(slot) + 1 : Math.round(slot) - 1
        const key = tabs.find(tab => tab !== leadKey && Tabs.slotOf(tabs, leadKey, tab) === inner)
        return key !== undefined && Activities.liveKeys.includes(key) ? Appearance.activity.liveDot : Appearance.activity.dot
    }

    signal modeRequested(string mode)
    signal foldRequested

    onIsCoveredChanged: {
        if (isCovered && mode === "expanded")
            foldRequested()
    }
    signal leadRequested(int direction)
    signal tabRequested(string key)

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
        shrinkLag: Motion.pace(pill.isAlertBody ? Motion.alerts.shrinkLag : pill.isClipboardBody ? Motion.clipboard.shrinkLag : Motion.activity.shrinkLag)
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
        model: pill.tabs

        Item {
            id: dot
            required property string modelData
            required property int index
            property real slot: Tabs.slotOf(pill.tabs, pill.leadKey, dot.modelData)
            readonly property bool isLive: Activities.liveKeys.includes(dot.modelData)
            property real liveShare: dot.isLive ? 1 : 0
            readonly property real rest: Appearance.activity.dot + (Appearance.activity.liveDot - Appearance.activity.dot) * dot.liveShare
            readonly property real base: Math.max(pill.bodyHeight, Appearance.activity.bead) / 2 + Appearance.activity.dotGap + dot.rest / 2
            readonly property real offset: Tabs.distanceOf(dot.slot, dot.base, pill.innerRestOf(dot.slot) + Appearance.activity.dotGap)
            readonly property real size: dot.rest * Math.min(1, Math.abs(dot.slot)) * dotPop.pop * pill.popScale
            readonly property real reach: Math.max(Appearance.activity.bead, dot.size)
            x: pill.spineX - dot.reach / 2
            y: dot.offset - dot.reach / 2
            width: dot.reach
            height: dot.reach
            visible: dot.size > 0.5

            Behavior on liveShare {
                NumberAnimation {
                    duration: Motion.pace(Motion.activity.dotEnter)
                    easing.type: Easing.OutBack
                    easing.overshoot: Motion.activity.dotOvershoot
                }
            }

            Behavior on slot {
                NumberAnimation {
                    duration: Motion.pace(Motion.activity.dotTravel)
                    easing.type: Easing.OutBack
                    easing.overshoot: Motion.activity.dotOvershoot
                }
            }

            Mutate {
                id: dotPop
                label: "activity dot"
                isShown: pill.areDotsShown && reshape.isArrived
                hasSpread: false
                enterDelay: (Math.abs(Math.round(dot.slot)) + 1) * Motion.activity.stagger
                leaveDelay: 0
                popDuration: Motion.activity.dotEnter
            }

            LiquidShape {
                parent: pill.host.liquidShapes
                visible: dot.visible
                width: dot.size
                height: dot.size
                x: pill.x + pill.spineX - dot.size / 2
                y: pill.y + dot.offset - dot.size / 2
            }

            Rectangle {
                anchors.centerIn: parent
                width: dot.size * Appearance.activity.dotCore
                height: width
                radius: width / 2
                color: dotArea.containsMouse ? Appearance.color.accent : dot.isLive ? Appearance.color.textBody : Appearance.color.textFaint
                opacity: 1 - dot.liveShare
            }

            Turn {
                anchors.centerIn: parent
                width: Appearance.activity.liveGlyph
                height: width
                isShown: dot.isLive && dotPop.isInnerShown && Math.abs(dot.slot) >= 1
                isSlung: true
                leaveWindow: 0

                ActivityBars {
                    visible: dot.modelData === "media"
                    anchors.centerIn: parent
                    width: implicitWidth
                    height: implicitHeight
                    isRunning: Activities.isPlaying && dot.visible
                    color: dotArea.containsMouse || Activities.isPlaying ? Appearance.color.accent : Appearance.color.textFaint
                }

                Glyph {
                    visible: dot.modelData === "call"
                    anchors.fill: parent
                    name: Activities.isMicMuted ? "mic-off" : "mic"
                    color: Activities.isMicMuted ? Appearance.color.danger : Appearance.color.accent
                    transform: Upright {
                        isMirrored: pill.host.isMirrored
                        axis: Appearance.activity.liveGlyph / 2
                    }
                }

                Text {
                    visible: dot.modelData === "notifications"
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Activities.unreadCount > Appearance.activity.countLimit ? Appearance.activity.countLimit + "+" : Activities.unreadCount
                    color: Appearance.color.accent
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.chip
                    font.bold: true
                    transform: Upright {
                        isMirrored: pill.host.isMirrored
                        axis: Appearance.activity.liveGlyph / 2
                    }
                }
            }

            MouseArea {
                id: dotArea
                anchors.fill: parent
                enabled: pill.areDotsShown && !pill.isSummoned && Math.abs(dot.slot) >= 1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.tabRequested(dot.modelData)
            }
        }
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
                pill.leadRequested(wheel.angleDelta.y > 0 ? 1 : -1)
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

    ActivityBuds {
        host: pill.host
        pill: pill
        side: 1
        label: "activity tabs"
        isShown: pill.isFaceShown && pill.face === "expanded" && pill.leadKey !== "recording"
        items: pill.tabs.map(key => ({ key: key, glyph: Appearance.activity.glyphs[key] ?? "music", isSelected: key === pill.leadKey }))
        onChosen: key => pill.tabRequested(key)
    }
}
