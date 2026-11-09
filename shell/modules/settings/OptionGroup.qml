import QtQuick
import qs.config
import qs.components

Column {
    id: group

    property string label
    property var options: []
    property string current

    signal picked(string option)

    spacing: Appearance.unit.medium

    Piece {
        Text {
            text: group.label
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Row {
        spacing: Appearance.settings.optionGap

        Repeater {
            model: group.options

            Piece {
                id: piece

                required property string modelData

                GlyphButton {
                    label: piece.modelData.toUpperCase()
                    implicitHeight: Appearance.settings.option
                    isSelected: group.current === piece.modelData
                    onClicked: group.picked(piece.modelData)
                }
            }
        }
    }
}
