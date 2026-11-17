import QtQuick
import qs.config
import qs.components
import "../../utils/Tint.js" as Tint

Item {
    id: key

    required property string label
    required property string kind
    property bool isShown: false
    property bool isHeld: false
    property int enterDelay: 0
    readonly property var look: Appearance.calculator
    readonly property bool isEquals: kind === "equals"
    readonly property bool isOperator: kind === "operator"
    readonly property color ink: isEquals ? (Tint.isLight(Appearance.color.accent) ? Appearance.color.ground : Appearance.color.text) : isOperator ? Appearance.color.accent : kind === "action" ? Appearance.color.textMuted : Appearance.color.text

    signal tapped()

    Turn {
        id: turn
        anchors.fill: parent
        isShown: key.isShown
        isFlipping: false
        enterDelay: key.enterDelay
        enterDuration: Motion.calculator.pop
        enterEasing: Easing.OutBack
        leaveWindow: 0
        leaveDuration: Motion.calculator.leave

        Item {
            id: face
            width: turn.width
            height: turn.height

            Press {
                target: face
                isPressed: gesture.pressed || key.isHeld
                isRaised: gesture.containsMouse
            }

            Squircle {
                anchors.fill: parent
                corner: key.look.corner
                color: key.isEquals ? Appearance.color.accent : Qt.alpha(key.isOperator ? Appearance.color.accent : Appearance.color.text, key.isHeld || gesture.pressed ? key.look.flashFill : key.isOperator ? key.look.operatorFill : key.look.keyFill)
                strokeColor: Appearance.color.hairline
                strokeWidth: key.isEquals ? 0 : 1

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.calculator.flash)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: key.label
                color: key.ink
                font.family: Appearance.font.mono
                font.pixelSize: key.look.key
                font.bold: key.isEquals || key.isOperator
            }
        }
    }

    Gesture {
        id: gesture
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onTapped: key.tapped()
    }
}
