import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    readonly property bool isTyping: input.activeFocus
    readonly property var look: Appearance.widgets

    function edit(x, y) {
        const point = input.mapFromItem(face, x, y)
        input.cursorPosition = input.positionAt(point.x, point.y)
        input.forceActiveFocus()
    }

    function finish() {
        input.focus = false
    }

    function follow() {
        const rect = input.cursorRectangle
        if (rect.y < view.contentY)
            drift.glideTo(rect.y)
        else if (rect.y + rect.height > view.contentY + view.height)
            drift.glideTo(rect.y + rect.height - view.height)
    }

    TypedText {
        id: title
        target: "NOTES"
        isShown: face.isShown
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        color: face.isTyping ? Appearance.color.accent : Appearance.color.textMuted
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
    }

    Turn {
        id: page
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.topMargin: face.look.noteGap
        anchors.bottom: parent.bottom
        isShown: face.isShown
        isFlipping: false
        enterDuration: Motion.widgets.leave
        leaveWindow: 0
        leaveDuration: Motion.widgets.leave

        Flickable {
            id: view
            width: page.width
            height: page.height
            clip: true
            contentWidth: width
            contentHeight: input.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Drift {
                id: drift
            }

            TextEdit {
                id: input
                width: view.width
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                selectByMouse: true
                persistentSelection: false
                cursorDelegate: Rectangle {
                    width: face.look.noteCaret
                    color: Appearance.color.accent
                    visible: input.activeFocus
                }
                color: Appearance.color.text
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.body
                onTextChanged: if (activeFocus) Notes.write(text)
                onCursorRectangleChanged: if (activeFocus) face.follow()
                Keys.onEscapePressed: face.finish()

                Binding on text {
                    when: !input.activeFocus
                    restoreMode: Binding.RestoreNone
                    value: Notes.text
                }
            }

            Text {
                visible: input.length === 0 && !input.activeFocus
                text: "TAP TO WRITE"
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.chip
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }
}
