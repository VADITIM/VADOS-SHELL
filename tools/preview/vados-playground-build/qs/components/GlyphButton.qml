import QtQuick
import qs.config

Item {
    id: button

    property string glyphName
    property string label
    property real glyphSize: 18
    property color color: Appearance.color.textBody
    property bool isArmed: false
    property bool isSelected: false
    readonly property color inkColor: isArmed ? Appearance.color.danger : isSelected ? Appearance.color.accent : color

    signal clicked()

    implicitWidth: label.length > 0 ? labelText.implicitWidth + 24 : 34
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: button.isArmed ? Qt.rgba(Appearance.color.danger.r, Appearance.color.danger.g, Appearance.color.danger.b, 0.14) : Appearance.color.wash
        border.width: button.isArmed ? 1.5 : 0
        border.color: Qt.rgba(Appearance.color.danger.r, Appearance.color.danger.g, Appearance.color.danger.b, 0.55)
        opacity: area.containsMouse || button.isArmed || button.isSelected ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.pace(area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                easing.type: Easing.OutQuad
            }
        }
    }

    Item {
        id: face
        anchors.fill: parent

        Press {
            target: face
            isPressed: area.pressed
        }

        Glyph {
            anchors.centerIn: parent
            width: button.glyphSize
            height: button.glyphSize
            visible: button.label.length === 0
            name: button.glyphName
            color: button.inkColor
        }

        Text {
            id: labelText
            anchors.centerIn: parent
            visible: button.label.length > 0
            text: button.label
            color: button.inkColor
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
