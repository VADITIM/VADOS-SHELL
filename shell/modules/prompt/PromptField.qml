import QtQuick
import qs.config
import qs.components

Turn {
    id: field

    required property var look
    property string label: ""
    property bool isEcho: false
    property bool isChecking: false
    property bool isError: false
    property bool isSelected: false
    property alias text: input.text
    readonly property color edge: isError ? Appearance.color.danger : isSelected || input.text.length > 0 ? Appearance.color.accent : Appearance.color.hairline

    signal pointed()

    function focusInput() {
        input.forceActiveFocus()
    }

    height: caption.implicitHeight + look.rowGap / 2 + look.fieldHeight
    enterEasing: Easing.OutBack

    Text {
        id: caption
        text: field.label.toUpperCase()
        color: Appearance.color.textMuted
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
    }

    Rectangle {
        id: pill
        y: caption.implicitHeight + field.look.rowGap / 2
        width: field.width
        height: field.look.fieldHeight
        radius: height / 2
        color: Appearance.color.raised
        border.width: field.look.caret
        border.color: field.edge

        Behavior on border.color {
            ColorAnimation {
                duration: Motion.pace(Motion.stateDuration)
            }
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: field.look.fieldHeight / 2
            anchors.rightMargin: field.look.fieldHeight / 2
            verticalAlignment: TextInput.AlignVCenter
            echoMode: field.isEcho ? TextInput.Normal : TextInput.NoEcho
            readOnly: field.isChecking
            opacity: 0
            cursorVisible: false
            color: Appearance.color.text
            selectionColor: Appearance.color.accent
            font.family: Appearance.font.sans
            font.pixelSize: Appearance.font.body
            onActiveFocusChanged: if (activeFocus) field.pointed()
        }

        Row {
            anchors.centerIn: parent
            spacing: field.look.caretGap

            ScrambleText {
                anchors.verticalCenter: parent.verticalCenter
                label: "prompt field"
                isShown: field.isShown
                target: field.isEcho ? input.text : field.look.mask.repeat(Math.min(input.text.length, field.look.dotLimit))
                color: field.isChecking ? Appearance.color.textMuted : Appearance.color.text
                family: Appearance.font.sans
                pixelSize: Appearance.font.body
                isBold: false
                spacing: field.isEcho ? 0 : field.look.dotGap
            }

            Rectangle {
                id: caret
                anchors.verticalCenter: parent.verticalCenter
                width: field.look.caret
                height: field.look.caretHeight
                radius: width / 2
                color: Appearance.color.accent
                visible: input.activeFocus && !field.isChecking

                SequentialAnimation on opacity {
                    running: caret.visible && !Motion.isReduced
                    paused: Motion.isHeld && running
                    loops: Animation.Infinite
                    onRunningChanged: if (!running) caret.opacity = 1

                    NumberAnimation { to: 1; duration: Motion.pace(0) }
                    PauseAnimation { duration: Motion.pace(Motion.prompt.blink) }
                    NumberAnimation { to: 0; duration: Motion.pace(0) }
                    PauseAnimation { duration: Motion.pace(Motion.prompt.blink) }
                }
            }
        }

        TapHandler {
            onTapped: input.forceActiveFocus()
        }
    }
}
