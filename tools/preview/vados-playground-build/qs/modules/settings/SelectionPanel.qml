import "../../utils/Tint.js" as Tint
import QtQuick
import qs.config
import qs.components

Section {
    id: panel

    readonly property var selection: Appearance.settings.selection
    readonly property bool isFollowingAccent: !Appearance.choice.isCustom

    signal styleRequested(string style)
    signal colorRequested(string style, string value)

    title: "SELECTION"
    icon: "palette"
    width: selection.width
    hasRule: false

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
            color: Appearance.choice.current
            onPicked: value => panel.colorRequested(Appearance.choice.style, value.toString())
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
                font.family: Appearance.font.mono
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
