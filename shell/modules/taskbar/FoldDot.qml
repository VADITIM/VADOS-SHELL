import QtQuick
import qs.config
import qs.components

Item {
    id: dot

    required property Item host
    required property Item origin
    property int order: 0

    readonly property string idleKey: "fold"
    readonly property real size: Appearance.taskbar.foldDot
    readonly property real circleX: (Appearance.taskbar.thickness - size) / 2
    readonly property bool isShown: host.isRevealed && !host.isEaten && host.isCompact && room > 0.5
    readonly property real shellWidth: size + swell
    readonly property real reachRight: origin.x + x + circleX + shellWidth * popScale
    readonly property real popScale: mutate.pop
    property real room: host.isCompact ? 1 : 0
    property real swell: area.containsMouse ? Appearance.taskbar.hoverSwell : 0

    width: Appearance.taskbar.thickness
    height: (size + Appearance.taskbar.idleGap) * room

    Behavior on room {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on swell {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.OutBack
        }
    }

    Mutate {
        id: mutate
        label: "fold dot"
        isShown: dot.isShown
        isArriving: dot.host.isArriving
        hasArrived: dot.host.hasArrivedAt(dot.origin.y + dot.y + dot.height / 2)
        hasSpread: false
        enterDelay: Motion.fold.dotDelay
        isHolding: dot.host.isHoldingParts
        leaveDelay: 0
        popDuration: Motion.stateDuration
        character: Motion.liquid.circle
    }

    EdgeFuse {
        readonly property real body: (dot.size + dot.swell) * dot.popScale
        parent: dot.host.liquidShapes
        reach: dot.origin.x + dot.x + dot.circleX + dot.size / 2
        bodyTop: dot.origin.y + dot.y + (dot.height - body) / 2
        length: body
        share: dot.host.fuse
    }

    LiquidShape {
        parent: dot.host.liquidShapes
        width: dot.size + dot.swell
        height: width
        x: dot.origin.x + dot.x + dot.circleX - dot.swell / 2
        y: dot.origin.y + dot.y + (dot.height - height) / 2
        transform: Scale {
            origin.x: (dot.size + dot.swell) / 2
            origin.y: (dot.size + dot.swell) / 2
            xScale: dot.popScale
            yScale: dot.popScale
        }
    }

    Turn {
        id: specks
        x: dot.circleX + (dot.size - width) / 2
        y: (dot.height - height) / 2
        width: Appearance.taskbar.foldSpeck
        height: Appearance.taskbar.foldSpeck * 3 + Appearance.taskbar.foldSpeckGap * 2
        isShown: mutate.isInnerShown
        isSlung: true
        leaveWindow: Motion.pill.leaveWindow / 2

        Press {
            target: specks
            isPressed: area.pressed
            depth: Motion.press.glyph
        }

        Column {
            spacing: Appearance.taskbar.foldSpeckGap

            Repeater {
                model: 3

                Rectangle {
                    width: Appearance.taskbar.foldSpeck
                    height: width
                    radius: width / 2
                    color: area.containsMouse ? Appearance.color.accent : Appearance.color.textMuted

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.hoverIn)
                        }
                    }
                }
            }
        }
    }

    FoldDrag {
        id: area
        host: dot.host
        width: dot.width
        height: dot.height
        enabled: dot.isShown
        onTapped: dot.host.foldIdles(false)
    }
}
