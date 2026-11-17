import QtQuick

Rectangle {
    id: pill

    required property var look
    property string label: ""
    property color labelColor: look.tokens.color.text
    property bool isLit: false

    signal tapped()

    implicitHeight: look.tokens.login.button
    implicitWidth: Math.max(implicitHeight, caption.implicitWidth + look.tokens.login.padding * 2)
    radius: height / 2
    color: Qt.rgba(look.tokens.color.panel.r, look.tokens.color.panel.g, look.tokens.color.panel.b, look.tokens.login.panelAlpha)
    border.width: look.tokens.login.ring
    border.color: activeFocus || isLit ? look.accent : hover.hovered ? look.tokens.color.hairline : "transparent"
    activeFocusOnTab: true
    scale: press.pressed ? look.tokens.motion.pressDepth : 1

    Behavior on scale {
        NumberAnimation {
            duration: pill.look.pace(pill.look.tokens.motion.state)
            easing.type: Easing.OutBack
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: pill.look.pace(pill.look.tokens.motion.state)
        }
    }

    Text {
        id: caption

        anchors.centerIn: parent
        text: pill.label
        color: pill.labelColor
        font.family: pill.look.mono
        font.pixelSize: pill.look.tokens.font.label
        font.letterSpacing: pill.look.tokens.font.labelSpacing
        font.bold: true
    }

    HoverHandler {
        id: hover

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: press

        onTapped: pill.tapped()
    }

    Keys.onReturnPressed: pill.tapped()
    Keys.onEnterPressed: pill.tapped()
    Keys.onSpacePressed: pill.tapped()
}
