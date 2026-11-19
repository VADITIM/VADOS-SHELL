import QtQuick
import qs.config
import qs.components

Turn {
    id: card

    required property var style
    property string label: ""
    property string corner: ""
    property string title: ""
    property string detail: ""
    property string stamp: ""

    signal opened()

    enterDuration: Motion.settings.pieceEnter
    enterEasing: Easing.OutBack
    leaveWindow: 0
    leaveDuration: Motion.settings.cellLeave

    Item {
        id: face
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radius.medium
            color: Appearance.color.raised
            opacity: area.containsMouse ? 1 : card.style.rowRest
            border.width: area.containsMouse ? card.style.underline : 0
            border.color: Appearance.color.accent

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                }
            }
        }

        Text {
            x: card.style.rowPadding
            y: card.style.rowPadding
            width: parent.width - card.style.rowPadding * 2 - cornerText.width
            elide: Text.ElideRight
            text: card.label
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.chip
            font.letterSpacing: Appearance.font.labelSpacing
        }

        Text {
            id: cornerText
            x: parent.width - card.style.rowPadding - width
            y: card.style.rowPadding
            text: card.corner
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.chip
            font.letterSpacing: Appearance.font.labelSpacing
        }

        Text {
            x: card.style.rowPadding
            y: card.style.rowPadding * 2 + Appearance.font.chip
            width: parent.width - card.style.rowPadding * 2
            height: parent.height - y - card.style.rowPadding * 2 - stampText.height
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            text: card.detail.length > 0 ? card.title + "\n" + card.detail : card.title
            color: Appearance.color.text
            font.family: Appearance.font.sans
            font.pixelSize: Appearance.font.label
        }

        Text {
            id: stampText
            x: card.style.rowPadding
            anchors.bottom: parent.bottom
            anchors.bottomMargin: card.style.rowPadding
            text: card.stamp
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.chip
            font.letterSpacing: Appearance.font.labelSpacing
        }

        Press {
            target: face
            isPressed: area.pressed
            isRaised: area.containsMouse
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.opened()
        }
    }
}
