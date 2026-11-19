import QtQuick
import qs.config
import qs.components

Column {
    id: fader

    property string label
    property real value: 0
    property real resetValue: 0
    property real trackWidth: 220

    signal moved(real value)

    spacing: Appearance.unit.small

    Item {
        width: fader.trackWidth
        height: Math.max(name.implicitHeight, reset.height)

        Piece {
            role: "label"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: name
                text: fader.label
                color: Appearance.color.textBody
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }

        Piece {
            id: reset
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Action {
                label: "RESET"
                tint: Appearance.color.danger
                isAvailable: Math.abs(fader.value - fader.resetValue) > 0.001
                onClicked: fader.moved(fader.resetValue)
            }
        }

        Piece {
            role: "label"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: Math.round(fader.value * 100) + "%"
                color: Appearance.color.accent
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }
        }
    }

    Item {
        width: fader.trackWidth
        height: Math.max(less.height, slider.implicitHeight)

        Piece {
            id: less
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Action {
                label: "−"
                tint: Appearance.color.textMuted
                isAvailable: fader.value > 0
                onClicked: slider.nudge(-1)
            }
        }

        Piece {
            anchors.left: less.right
            anchors.right: more.left
            anchors.leftMargin: Appearance.unit.small
            anchors.rightMargin: Appearance.unit.small
            anchors.verticalCenter: parent.verticalCenter

            Slider {
                id: slider
                width: parent.width
                value: fader.value
                look: ({
                    track: Appearance.settings.slider,
                    grab: Appearance.settings.sliderGrab,
                    step: Appearance.settings.sliderStep
                })
                pace: ({
                    settle: Motion.settings.sliderSettle,
                    thicken: Motion.settings.trackHeld
                })
                onMoved: value => fader.moved(value)
            }
        }

        Piece {
            id: more
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Action {
                label: "+"
                tint: Appearance.color.textMuted
                isAvailable: fader.value < 1
                onClicked: slider.nudge(1)
            }
        }
    }
}
