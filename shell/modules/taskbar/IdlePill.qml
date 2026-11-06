import QtQuick
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
    property bool canExpand: true
    property bool isKeptCompact: false
    default property alias expansion: expansionHolder.data

    readonly property real size: Appearance.taskbar.idleSize
    readonly property real circleX: (Appearance.taskbar.thickness - size) / 2
    readonly property bool isPresent: isAvailable && (isKeptCompact || !host.isCompact)
    readonly property bool isExpanded: host.expandedIdle === idleKey && isShown
    readonly property bool isShown: host.isRevealed && !host.isEaten && isPresent && room > 0.5
    readonly property bool isUnfolded: isExpanded && stretch > 0.55
    readonly property real expandedWidth: size + expansionHolder.childrenRect.width + Appearance.taskbar.idleGap * 2
    readonly property real shellWidth: size + (expandedWidth - size) * stretch + swell
    readonly property real reachRight: origin.x + x + circleX + shellWidth * popScale
    property real room: isPresent ? 1 : 0
    readonly property real popScale: mutate.pop
    readonly property bool isGlyphShown: mutate.isInnerShown
    property bool isFolding: false
    property real stretch: isExpanded || isFolding ? 1 : 0
    readonly property real circleTop: origin.y + y + (height - size) / 2
    property real swell: Math.max(area.containsMouse && !isExpanded ? Appearance.taskbar.hoverSwell : 0, host.touchOf(origin.x + x + circleX + size / 2, circleTop, circleTop + size, size / 2) * Appearance.taskbar.visitSwell)

    readonly property bool isHoverIntent: area.containsMouse && !area.pressed && canExpand && isShown

    signal activated()
    signal scrolled(real steps)
    signal middleClicked()

    width: Appearance.taskbar.thickness
    height: (size + Appearance.taskbar.idleGap) * room

    Behavior on room {
        NumberAnimation {
            duration: Motion.stateDuration
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on stretch {
        NumberAnimation {
            duration: Motion.pill.sizeFollow
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on swell {
        NumberAnimation {
            duration: Motion.stateDuration
            easing.type: Easing.OutBack
        }
    }

    function bodyRect() {
        return Qt.rect(origin.x + x + circleX, origin.y + y + (height - size) / 2, shellWidth, size)
    }

    onIsHoverIntentChanged: host.hoverIdle(idle, isHoverIntent)

    onIsExpandedChanged: {
        if (isExpanded) {
            fold.stop()
            isFolding = false
        } else if (stretch > 0.01) {
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
        isShown: idle.isShown
        hasSpread: false
        enterDelay: idle.order * Motion.reveal.stagger
        leaveDelay: idle.stretch > 0.01 ? Motion.pill.fold + Motion.pill.sizeFollow : Motion.pill.leaveElement
        popDuration: Motion.stateDuration
        character: Motion.liquid.circle
    }

    EdgeFuse {
        readonly property real body: (idle.size + idle.swell) * idle.popScale
        parent: idle.host.liquidShapes
        reach: idle.origin.x + idle.x + idle.circleX + idle.size / 2
        bodyTop: idle.origin.y + idle.y + (idle.height - body) / 2
        length: body
        share: idle.host.fuse
    }

    LiquidShape {
        parent: idle.host.liquidShapes
        width: idle.shellWidth
        height: idle.size + idle.swell
        x: idle.origin.x + idle.x + idle.circleX - idle.swell / 2
        y: idle.origin.y + idle.y + (idle.height - height) / 2
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
        enterDuration: Motion.stateDuration
        leaveDuration: Motion.pill.leaveElement
        leaveWindow: 0

        Press {
            target: glyphTurn
            isPressed: area.pressed
            depth: Motion.press.glyph
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
        enabled: idle.isShown
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (hasFolded)
                return
            if (mouse.button === Qt.MiddleButton)
                idle.middleClicked()
            else if (idle.canExpand)
                idle.host.toggleIdle(idle.idleKey)
            else
                idle.activated()
        }
        onWheel: wheel => idle.scrolled(wheel.angleDelta.y / 120)
    }
}
