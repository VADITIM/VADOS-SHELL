import QtQuick
import qs.config
import qs.components

Turn {
    id: button

    required property var look
    property string text: ""
    property bool isSelected: false
    property bool isFilled: false
    property bool isEnabled: true

    signal tapped()

    height: look.buttonHeight
    enterEasing: Easing.OutBack

    Press {
        target: button
        isPressed: tap.pressed
        isRaised: hover.hovered || button.isSelected
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: button.isFilled && button.isEnabled ? Appearance.color.accent : "transparent"
        border.width: button.look.caret
        border.color: button.isSelected || hover.hovered ? Appearance.color.accent : Appearance.color.hairline
        opacity: button.isEnabled ? 1 : button.look.disabled
    }

    Text {
        anchors.centerIn: parent
        text: button.text
        color: button.isFilled && button.isEnabled ? Appearance.color.panel : Appearance.color.text
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
        font.bold: true
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        id: tap
        enabled: button.isEnabled
        onTapped: button.tapped()
    }
}
