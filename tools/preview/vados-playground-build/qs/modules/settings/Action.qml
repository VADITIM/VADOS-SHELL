import "../../utils/Tint.js" as Tint
import QtQuick
import qs.config
import qs.components

Item {
    id: action

    property string label
    property bool isPrimary: false
    property bool isArmed: false
    property bool isAvailable: true
    property color tint: "transparent"
    readonly property bool hasTint: tint.a > 0
    readonly property var look: Appearance.settings.action
    readonly property bool isFilled: isPrimary && isAvailable && !isArmed
    readonly property color ink: isArmed ? Appearance.color.danger : hasTint ? tint : isFilled ? (Tint.isLight(Appearance.color.accent) ? Appearance.color.ground : Appearance.color.text) : area.containsMouse && isAvailable ? Appearance.color.text : Appearance.color.textBody

    signal clicked

    implicitWidth: name.implicitWidth + look.padding * 2
    implicitHeight: look.height
    opacity: isAvailable ? 1 : Appearance.settings.section.disabled

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.pace(Motion.hoverIn)
            easing.type: Easing.OutQuad
        }
    }

    Item {
        id: face
        anchors.fill: parent

        Press {
            target: face
            isPressed: area.pressed && action.isAvailable
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: action.isArmed ? Qt.alpha(Appearance.color.danger, action.look.armedFill) : action.hasTint ? Qt.alpha(action.tint, area.containsMouse && action.isAvailable ? action.look.tintHover : action.look.tintFill) : action.isFilled ? Appearance.color.accent : area.containsMouse && action.isAvailable ? Appearance.color.wash : "transparent"
            border.width: action.isFilled ? 0 : action.look.ring
            border.color: action.isArmed ? Appearance.color.danger : action.hasTint ? Qt.alpha(action.tint, action.look.tintRing) : area.containsMouse && action.isAvailable ? Appearance.color.textMuted : Appearance.color.hairline

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.hoverIn)
                }
            }
        }

        Text {
            id: name
            anchors.centerIn: parent
            text: action.label
            color: action.ink
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
        cursorShape: action.isAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (action.isAvailable)
                action.clicked()
        }
    }
}
