import "../../utils/Tint.js" as Tint
import QtQuick
import qs.config
import qs.components

Section {
    id: panel

    readonly property var selection: Appearance.settings.selection
    readonly property bool isFollowingAccent: !Appearance.choice.isCustom
    property color accent: Appearance.color.accent
    property bool isAccentPicked: false

    signal styleRequested(string style)
    signal colorRequested(string style, string value)
    signal accentRequested(color value)

    function hexOf(source) {
        return source.toString().toUpperCase()
    }

    title: "COLORS"
    icon: "palette"
    width: selection.width
    hasRule: false

    Piece {
        role: "label"

        Text {
            text: "ACCENT"
            color: Appearance.color.textBody
            font.family: Appearance.font.sans
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Piece {
        width: panel.selection.width
        height: Appearance.settings.swatch

        Item {
            anchors.fill: parent

            Rectangle {
                id: swatch
                width: Appearance.settings.swatch
                height: Appearance.settings.swatch
                radius: Appearance.radius.medium
                color: panel.accent
                border.width: panel.isAccentPicked ? Appearance.settings.choice.ring : 1
                border.color: panel.isAccentPicked ? Appearance.color.text : Appearance.color.hairline

                Press {
                    target: swatch
                    isPressed: swatchArea.pressed
                }

                MouseArea {
                    id: swatchArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.isAccentPicked = !panel.isAccentPicked
                }
            }

            Rectangle {
                x: swatch.width + panel.selection.swatchGap
                width: parent.width - x
                height: parent.height
                radius: height / 2
                color: Appearance.color.raised
                border.width: 1
                border.color: hexInput.activeFocus ? Appearance.color.accent : "transparent"

                TextInput {
                    id: hexInput
                    anchors.verticalCenter: parent.verticalCenter
                    x: Appearance.settings.fieldPadding
                    width: parent.width - x * 2
                    maximumLength: 7
                    text: panel.hexOf(panel.accent)
                    color: Appearance.color.text
                    selectionColor: Appearance.color.accent
                    selectedTextColor: Appearance.color.ground
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.settings.hexText
                    font.capitalization: Font.AllUppercase
                    onTextEdited: {
                        const candidate = (text.trim().startsWith("#") ? "" : "#") + text.trim()
                        if (/^#[0-9a-fA-F]{6}$/.test(candidate))
                            panel.accentRequested(Qt.color(candidate))
                    }
                    onEditingFinished: text = panel.hexOf(panel.accent)
                    Keys.onEscapePressed: event => {
                        hexInput.focus = false
                        event.accepted = true
                    }
                }
            }
        }
    }

    OptionGroup {
        label: "MARK"
        options: ["outline", "pill"]
        current: Appearance.choice.style
        onPicked: option => panel.styleRequested(option)
    }

    Piece {
        id: wheelPiece
        width: panel.selection.wheel
        height: wheel.height
        isFlipping: false

        ColorWheel {
            id: wheel
            look: Appearance.settings
            diameter: panel.selection.wheel
            wheelShare: wheelPiece.presence
            color: panel.isAccentPicked ? panel.accent : Appearance.choice.current
            onPicked: value => panel.isAccentPicked ? panel.accentRequested(value) : panel.colorRequested(Appearance.choice.style, value.toString())
        }
    }

    Piece {
        width: panel.selection.width
        height: Appearance.settings.choice.height

        Item {
            id: follow
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: panel.isFollowingAccent ? Appearance.color.accent : "transparent"
                border.width: panel.isFollowingAccent ? 0 : Appearance.settings.choice.ring
                border.color: followArea.containsMouse ? Appearance.color.text : Appearance.color.textMuted
            }

            Press {
                target: follow
                isPressed: followArea.pressed
            }

            Text {
                anchors.centerIn: parent
                text: panel.isFollowingAccent ? "FOLLOWS THE ACCENT" : "FOLLOW THE ACCENT"
                color: panel.isFollowingAccent ? (Tint.isLight(Appearance.color.accent) ? Appearance.color.ground : Appearance.color.text) : Appearance.color.text
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }

            MouseArea {
                id: followArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.colorRequested(Appearance.choice.style, "")
            }
        }
    }
}
