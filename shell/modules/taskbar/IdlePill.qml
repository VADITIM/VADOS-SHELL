import QtQuick
import QtQuick.Shapes
import qs.config
import qs.components

Item {
    id: idle

    required property Item host
    required property Item origin
    required property string idleKey
    property int order: 0
    property bool isAvailable: true
    property string glyphName
    property real glyphLevel: 1
    property bool isCharging: false
    property color glyphColor: Appearance.color.textBody
    property real ringLevel: -1
    property color ringColor: Appearance.color.accent
    property real ringCap: -1
    property bool canExpand: true
    property string extensionKey: ""
    property bool isKeptCompact: false
    default property alias expansion: expansionHolder.data

    readonly property real size: Appearance.taskbar.idleSize
    readonly property real circleX: (Appearance.taskbar.thickness - size) / 2
    readonly property bool isPresent: isAvailable && (isKeptCompact || !host.isCompact)
    readonly property bool isExtended: extensionKey.length > 0 && host.extensionKey === extensionKey && isShown
    readonly property bool isHeldOpen: isExtended || lift > 0.001 || widen > 0.001
    readonly property bool isCovered: host.isUnderExtension(idle, circleTop, circleTop + size)
    readonly property bool isExpanded: (host.expandedIdle === idleKey || isHeldOpen) && isShown
    readonly property bool isShown: host.isRevealed && !host.isEaten && !host.swallows(circleTop, circleTop + size) && isPresent && room > 0.5
    readonly property bool isUnfolded: isExpanded && !isHeldOpen && stretch > 0.55
    readonly property real liftHeight: Math.min(host.height - Appearance.taskbar.margin * 2, host.height * Appearance.extension.heightShare)
    readonly property real liftTop: Math.max(Appearance.taskbar.margin, host.clockTop - Appearance.extension.clockGap - liftHeight)
    readonly property real bodyTop: circleTop + (liftTop - circleTop) * lift
    readonly property real bodyHeight: size + (liftHeight - size) * lift
    property bool hasLifted: false
    property real lift: isExtended && stretch > 0.999 ? 1 : 0
    property real widen: isExtended && stretch > 0.999 ? 1 : 0
    readonly property real expandedWidth: size + expansionHolder.childrenRect.width + Appearance.taskbar.idleGap * 2
    property real heldWidth: size
    readonly property real reachWidth: isExpanded ? expandedWidth : heldWidth
    readonly property real shellWidth: size + (reachWidth - size) * stretch + (Appearance.extension.width - expandedWidth) * widen + swell
    readonly property real reachRight: origin.x + x + circleX + shellWidth * popScale
    property real room: isPresent ? 1 : 0
    readonly property real popScale: mutate.pop
    readonly property bool isGlyphShown: mutate.isInnerShown && !hasLifted
    property bool isFolding: false
    property real stretch: isExpanded || isFolding ? 1 : 0
    readonly property real circleTop: origin.y + y + (height - size) / 2
    property real swell: Math.max(area.containsMouse && !isExpanded && !canExpand ? Appearance.taskbar.hoverSwell : 0, host.touchOf(origin.x + x + circleX + size / 2, circleTop, circleTop + size, size / 2) * Appearance.taskbar.visitSwell)

    readonly property bool isHoverIntent: area.containsMouse && !area.pressed && canExpand && isShown && !isHeldOpen

    signal activated()
    signal scrolled(real steps)
    signal middleClicked()

    width: Appearance.taskbar.thickness
    height: (size + Appearance.taskbar.idleGap) * room

    Behavior on room {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on stretch {
        NumberAnimation {
            duration: Motion.pace(Motion.pill.sizeFollow)
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on swell {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.OutBack
        }
    }

    Behavior on lift {
        SequentialAnimation {
            PauseAnimation {
                duration: Motion.pace(idle.isExtended ? 0 : Motion.extension.narrow)
            }
            NumberAnimation {
                duration: Motion.pace(idle.isExtended ? Motion.extension.lift : Motion.extension.lower)
                easing.type: idle.isExtended ? Easing.OutBack : Easing.InOutCubic
                easing.overshoot: Motion.extension.bounce
            }
        }
    }

    Behavior on widen {
        NumberAnimation {
            duration: Motion.pace(idle.isExtended ? Motion.extension.lift : Motion.extension.narrow)
            easing.type: idle.isExtended ? Easing.OutBack : Easing.InOutCubic
            easing.overshoot: Motion.extension.bounce
        }
    }

    function extend() {
        host.extensionRequested(extensionKey)
    }

    function bodyRect() {
        return Qt.rect(origin.x + x + circleX, bodyTop, shellWidth, bodyHeight)
    }

    onIsExtendedChanged: {
        if (isExtended)
            hasLifted = true
    }
    onIsHeldOpenChanged: {
        if (!isHeldOpen && stretch < 0.01)
            hasLifted = false
    }
    onIsUnfoldedChanged: {
        if (isUnfolded)
            hasLifted = false
    }
    onStretchChanged: {
        if (stretch < 0.01 && !isHeldOpen)
            hasLifted = false
    }

    onIsHoverIntentChanged: host.hoverIdle(idle, isHoverIntent)
    onExpandedWidthChanged: if (isExpanded) heldWidth = expandedWidth

    onIsExpandedChanged: {
        if (isExpanded) {
            heldWidth = expandedWidth
            fold.stop()
            isFolding = false
        } else if (stretch > 0.01 && !hasLifted) {
            isFolding = true
            fold.restart()
        }
    }

    Timer {
        id: fold
        interval: Motion.pill.fold
        onTriggered: idle.isFolding = false
    }

    Mutate {
        id: mutate
        label: "idle pill"
        isShown: idle.isShown
        isArriving: idle.host.isArriving
        hasArrived: idle.host.hasArrivedAt(idle.origin.y + idle.y + idle.height / 2)
        hasSpread: false
        hasArrivalPop: true
        enterDelay: idle.host.isArriving ? (idle.order - 1) * Motion.reveal.arrivalStagger : idle.order * Motion.reveal.stagger
        isHolding: idle.host.isHoldingParts
        leaveDelay: idle.stretch > 0.01 ? Motion.pill.fold + Motion.pill.sizeFollow : Motion.pill.sling
        popDuration: Motion.stateDuration
        character: Motion.liquid.circle
    }

    EdgeFuse {
        readonly property real body: (idle.bodyHeight + idle.swell) * idle.popScale
        parent: idle.host.liquidShapes
        reach: idle.origin.x + idle.x + idle.circleX + idle.size / 2
        bodyTop: idle.bodyTop + (idle.bodyHeight - body) / 2
        length: body
        share: idle.host.fuse
    }

    LiquidShape {
        parent: idle.host.liquidShapes
        width: idle.shellWidth
        height: idle.bodyHeight + idle.swell
        x: idle.origin.x + idle.x + idle.circleX - idle.swell / 2
        y: idle.bodyTop - idle.swell / 2
        radius: Math.min(Math.min(width, height) / 2, Appearance.extension.radius)
        transform: Scale {
            origin.x: (idle.size + idle.swell) / 2
            origin.y: (idle.size + idle.swell) / 2
            xScale: idle.popScale
            yScale: idle.popScale
        }
    }

    Turn {
        id: glyphTurn
        x: idle.circleX + (idle.size - width) / 2
        y: (idle.height - height) / 2
        width: Appearance.taskbar.glyph
        height: Appearance.taskbar.glyph
        isShown: idle.isGlyphShown
        visible: !idle.isCovered
        isSlung: true
        leaveWindow: Motion.pill.leaveWindow / 2

        Press {
            target: glyphTurn
            isPressed: area.pressed
            depth: Motion.press.glyph
        }

        Shape {
            id: chargeRing
            readonly property real ring: Appearance.taskbar.chargeRing
            readonly property real stroke: Appearance.taskbar.chargeStroke
            property real level: Math.max(0, Math.min(1, idle.ringLevel))
            x: (glyphTurn.width - ring) / 2
            y: (glyphTurn.height - ring) / 2
            width: ring
            height: ring
            visible: idle.ringLevel >= 0
            preferredRendererType: Shape.CurveRenderer
            transform: Upright {
                isMirrored: idle.host.isMirrored
                axis: Appearance.taskbar.chargeRing / 2
            }

            Behavior on level {
                NumberAnimation {
                    duration: Motion.pace(Motion.stateDuration)
                    easing.type: Easing.InOutCubic
                }
            }

            ShapePath {
                strokeColor: Qt.alpha(idle.ringColor, Appearance.taskbar.chargeTrack)
                strokeWidth: chargeRing.stroke
                fillColor: "transparent"
                PathAngleArc {
                    centerX: Appearance.taskbar.chargeRing / 2
                    centerY: Appearance.taskbar.chargeRing / 2
                    radiusX: (Appearance.taskbar.chargeRing - Appearance.taskbar.chargeStroke) / 2
                    radiusY: radiusX
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                strokeColor: idle.ringColor
                strokeWidth: chargeRing.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: Appearance.taskbar.chargeRing / 2
                    centerY: Appearance.taskbar.chargeRing / 2
                    radiusX: (Appearance.taskbar.chargeRing - Appearance.taskbar.chargeStroke) / 2
                    radiusY: radiusX
                    startAngle: -90
                    sweepAngle: 360 * chargeRing.level
                }
            }

            ShapePath {
                strokeColor: idle.ringCap > 0 && idle.ringCap < 1 ? Appearance.color.text : "transparent"
                strokeWidth: chargeRing.stroke
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathAngleArc {
                    centerX: Appearance.taskbar.chargeRing / 2
                    centerY: Appearance.taskbar.chargeRing / 2
                    radiusX: (Appearance.taskbar.chargeRing - Appearance.taskbar.chargeStroke) / 2
                    radiusY: radiusX
                    startAngle: idle.ringCap * 360 - 90 + Appearance.taskbar.chargeGap
                    sweepAngle: 360 * (1 - idle.ringCap) - Appearance.taskbar.chargeGap * 2
                }
            }
        }

        Glyph {
            anchors.fill: parent
            name: idle.glyphName
            level: idle.glyphLevel
            isCharging: idle.isCharging
            color: idle.isExpanded ? Appearance.color.accent : idle.glyphColor
            transform: Upright {
                isMirrored: idle.host.isMirrored
                axis: Appearance.taskbar.glyph / 2
            }
        }
    }

    Item {
        x: idle.circleX + idle.size
        y: (idle.height - height) / 2
        width: Math.max(0, idle.shellWidth - idle.size - idle.swell)
        height: idle.size
        clip: true
        visible: idle.stretch > 0.001

        Item {
            id: expansionHolder
            width: childrenRect.width
            height: idle.size
            transform: Upright {
                isMirrored: idle.host.isMirrored
                axis: expansionHolder.width / 2
            }
        }
    }

    FoldDrag {
        id: area
        host: idle.host
        x: idle.circleX
        y: (idle.height - idle.size) / 2
        width: idle.size
        height: idle.size
        enabled: idle.isShown && !idle.isCovered
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onTapped: mouse => {
            if (mouse.button === Qt.MiddleButton)
                idle.middleClicked()
            else if (idle.extensionKey.length > 0)
                idle.extend()
            else if (idle.canExpand)
                idle.host.toggleIdle(idle.idleKey)
            else
                idle.activated()
        }
        onWheel: wheel => idle.scrolled(wheel.angleDelta.y / 120)
    }
}
