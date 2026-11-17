import QtQuick
import qs.config

Rectangle {
    id: field

    property string placeholder
    property bool isSecret: false
    property bool isRevealed: false
    property alias text: input.text
    property alias input: input

    signal submitted()
    signal canceled()

    height: Appearance.extension.field
    radius: height / 2
    color: Appearance.color.wash
    border.width: 1
    border.color: input.activeFocus ? Appearance.color.accent : "transparent"

    TextInput {
        id: input
        anchors.verticalCenter: parent.verticalCenter
        x: Appearance.extension.fieldPadding
        width: parent.width - x * 2
        clip: true
        echoMode: field.isSecret && !field.isRevealed ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"
        color: Appearance.color.text
        selectionColor: Appearance.color.accent
        selectedTextColor: Appearance.color.ground
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.label
        inputMethodHints: field.isSecret ? Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase : Qt.ImhNoAutoUppercase
        Keys.onReturnPressed: field.submitted()
        Keys.onEnterPressed: field.submitted()
        Keys.onEscapePressed: field.canceled()
    }

    Text {
        x: input.x
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length === 0
        text: field.placeholder
        color: Appearance.color.textFaint
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: mouse => {
            input.forceActiveFocus()
            mouse.accepted = false
        }
    }
}
