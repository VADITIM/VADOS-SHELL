import QtQuick
import qs.config

Column {
    id: field

    property string label
    property string value
    property string placeholder
    property real fieldWidth: 220

    signal edited(string value)

    spacing: Appearance.unit.small

    Piece {
        Text {
            text: field.label
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Piece {
        Rectangle {
            width: field.fieldWidth
            height: Appearance.settings.field
            radius: height / 2
            color: Appearance.color.wash
            border.width: 1
            border.color: input.activeFocus ? Appearance.color.accent : "transparent"

            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                x: Appearance.settings.fieldPadding
                width: parent.width - x * 2
                clip: true
                text: field.value
                color: Appearance.color.text
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.settings.hexText
                onTextEdited: field.edited(text)
                Keys.onEscapePressed: event => event.accepted = false
            }

            Text {
                x: input.x
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: field.placeholder
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.settings.hexText
            }
        }
    }
}
