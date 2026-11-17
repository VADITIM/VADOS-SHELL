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
        height: name.implicitHeight

        Piece {
            role: "label"

            Text {
                id: name
                text: fader.label
                color: Appearance.color.textBody
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }

        Piece {
            role: "label"
            anchors.right: parent.right

            Text {
                text: Math.round(fader.value * 100) + "%"
                color: Appearance.color.accent
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }
        }
    }

    Piece {
        Slider {
            id: slider
            width: fader.trackWidth
            value: fader.value
            look: ({
                track: Appearance.settings.slider,
                knob: Appearance.settings.knob,
                ring: Appearance.settings.choice.ring,
                fillAlpha: Appearance.settings.sliderFill,
                step: Appearance.settings.sliderStep
            })
            pace: ({
                settle: Motion.settings.sliderSettle,
                held: Motion.settings.knobHeld,
                thicken: Motion.settings.trackHeld
            })
            onMoved: value => fader.moved(value)
        }
    }

    Item {
        width: fader.trackWidth
        height: steps.height

        Row {
            id: steps
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Appearance.unit.small

            Piece {
                Action {
                    label: "−"
                    tint: Appearance.color.accent
                    isAvailable: fader.value > 0
                    onClicked: slider.nudge(-1)
                }
            }

            Piece {
                Action {
                    label: "+"
                    tint: Appearance.color.accent
                    isAvailable: fader.value < 1
                    onClicked: slider.nudge(1)
                }
            }
        }

        Piece {
            anchors.right: parent.right

            Action {
                label: "RESET"
                tint: Appearance.color.danger
                isAvailable: Math.abs(fader.value - fader.resetValue) > 0.001
                onClicked: fader.moved(fader.resetValue)
            }
        }
    }
}
