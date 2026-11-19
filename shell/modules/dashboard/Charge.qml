import QtQuick
import qs.config
import qs.components

Item {
    id: charge

    property real level: 0
    property bool isCharging: false
    property real cap: -1
    property bool isShown: false
    property int enterDelay: 0
    readonly property var look: Appearance.dashboard.battery
    readonly property bool isPresent: turn.presence > 0.5
    readonly property color levelColor: Appearance.chargeColor(level, isCharging)

    width: look.width
    height: percent.height + look.gap + look.height + look.gap + look.bolt

    Turn {
        id: turn
        width: charge.width
        height: charge.height
        isShown: charge.isShown
        enterDelay: charge.enterDelay
        enterDuration: Motion.search.tileEnter

        TypedText {
            id: percent
            x: (charge.width - fullWidth) / 2
            target: Math.round(charge.level * 100) + "%"
            isShown: charge.isPresent
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: charge.levelColor
            font.family: Appearance.font.mono
            font.pixelSize: charge.look.percent
            font.bold: true
        }

        LevelBar {
            id: bar
            x: (charge.width - width) / 2
            y: percent.height + charge.look.gap
            width: charge.look.bar
            height: charge.look.height
            color: Qt.alpha(Appearance.color.textFaint, Appearance.dashboard.gauge.usageTrack)
            isShown: charge.isPresent
            level: charge.level
            fill: charge.levelColor

            Rectangle {
                readonly property real capY: (1 - charge.cap) * bar.height
                x: 0
                y: 0
                width: bar.width
                height: Math.max(0, capY - charge.look.capGap)
                radius: width / 2
                visible: charge.cap > 0 && charge.cap < 1 && height > 0
                opacity: bar.drawn > 0 ? 1 : 0
                color: Appearance.color.text

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }
            }
        }

        Glyph {
            x: (charge.width - width) / 2
            y: bar.y + bar.height + charge.look.gap
            width: charge.look.bolt
            height: charge.look.bolt
            opacity: charge.isCharging ? 1 : 0
            name: "bolt"
            stroke: Appearance.dashboard.iconStroke * 24 / width
            color: charge.levelColor

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(Motion.stateDuration)
                }
            }
        }
    }
}
