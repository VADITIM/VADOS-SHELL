import QtQuick
import qs.config
import qs.components

Column {
    id: field

    property string label
    property string value
    property string placeholder
    property real fieldWidth: 220
    property string actionLabel: ""
    readonly property var look: Appearance.settings.textField

    signal edited(string value)
    signal actionTapped

    spacing: Appearance.unit.small

    Item {
        width: field.fieldWidth
        height: name.height

        Piece {
            id: name
            role: "label"
            isFlipping: false
            width: nameText.implicitWidth
            height: nameText.implicitHeight

            ScrambleText {
                id: nameText
                label: "field label"
                target: field.label
                isShown: name.isShown
                color: Appearance.color.textBody
                isBold: false
            }
        }

        Piece {
            id: find
            anchors.right: parent.right
            anchors.rightMargin: Appearance.settings.fieldPadding
            visible: field.actionLabel.length > 0
            isFlipping: false
            width: findText.implicitWidth
            height: findText.implicitHeight

            ScrambleText {
                id: findText
                label: "field action"
                target: field.actionLabel
                isShown: find.isShown && find.visible
                color: reach.containsMouse ? Appearance.color.accent : Appearance.color.textMuted
                family: Appearance.font.mono

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.hoverIn)
                    }
                }
            }

            MouseArea {
                id: reach
                anchors.fill: parent
                anchors.margins: -field.look.actionReach
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: field.actionTapped()
            }
        }
    }

    Piece {
        id: box
        isFlipping: false
        enterEasing: Easing.OutCubic
        enterDuration: Motion.settings.pieceEnter
        width: field.fieldWidth
        height: Appearance.settings.field

        Rectangle {
            readonly property real grown: Math.max(0, Math.min(1, box.presence))

            width: height + (field.fieldWidth - height) * grown
            height: parent.height
            radius: height / 2
            opacity: Math.min(1, box.presence * field.look.fadeLead)
            clip: true
            color: Appearance.color.raised
            border.width: Appearance.settings.action.ring
            border.color: input.activeFocus ? Appearance.color.accent : Appearance.color.hairline

            Behavior on border.color {
                ColorAnimation {
                    duration: Motion.pace(Motion.hoverIn)
                }
            }

            Item {
                width: field.fieldWidth
                height: parent.height
                opacity: Math.max(0, (box.presence - field.look.textFrom) / (1 - field.look.textFrom))

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
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.settings.hexText
                    onTextEdited: field.edited(text)
                    Keys.onEscapePressed: event => event.accepted = false
                }

                Text {
                    x: input.x
                    width: input.width
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: field.placeholder
                    color: Appearance.color.textFaint
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.settings.hexText
                }
            }
        }
    }
}
