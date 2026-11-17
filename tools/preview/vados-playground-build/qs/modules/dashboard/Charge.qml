import QtQuick
import qs.config
import qs.components

Item {
    id: charge

    property real level: 0
    property bool isCharging: false
    property bool isShown: false
    property int enterDelay: 0
    property real drawn: isPresent ? Math.max(0, Math.min(1, level)) : 0
    readonly property var look: Appearance.dashboard.battery
    readonly property bool isPresent: turn.presence > 0.5
    readonly property color levelColor: Appearance.chargeColor(level, isCharging)

    width: look.width
    height: look.capHeight + look.height + look.gap + percent.height

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.level)
            easing.type: Easing.OutCubic
        }
    }

    Turn {
        id: turn
        width: charge.width
        height: charge.height
        isShown: charge.isShown
        enterDelay: charge.enterDelay
        enterDuration: Motion.search.tileEnter

        Rectangle {
            x: (charge.width - width) / 2
            width: charge.look.cap
            height: charge.look.capHeight + Appearance.dashboard.iconStroke
            radius: charge.look.corner / 3
            color: charge.levelColor
        }

        Rectangle {
            id: shell
            y: charge.look.capHeight
            width: charge.width
            height: charge.look.height
            radius: charge.look.corner
            color: "transparent"
            border.width: Appearance.dashboard.iconStroke
            border.color: charge.levelColor

            Rectangle {
                readonly property real room: shell.height - charge.look.inset * 2
                x: charge.look.inset
                y: shell.height - charge.look.inset - height
                width: shell.width - charge.look.inset * 2
                height: room * charge.drawn
                radius: charge.look.corner - charge.look.inset
                color: charge.levelColor
            }

            Glyph {
                anchors.centerIn: parent
                visible: charge.isCharging
                width: charge.look.bolt
                height: charge.look.bolt
                name: "bolt"
                stroke: Appearance.dashboard.iconStroke * 24 / width
                color: Appearance.color.text
            }
        }

        TypedText {
            id: percent
            x: (charge.width - fullWidth) / 2
            y: charge.look.capHeight + charge.look.height + charge.look.gap
            target: Math.round(charge.level * 100) + "%"
            isShown: charge.isPresent
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: charge.levelColor
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
        }
    }
}
