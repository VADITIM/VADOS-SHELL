import QtQuick
import qs.config
import qs.components

Item {
    id: row

    property var app: null
    property bool isSelected: false
    property bool isFavorite: false
    property bool isShown: false
    property int enterDelay: 0
    property real room: width
    property bool isMirrored: false
    property real fade: 1

    readonly property var look: Appearance.search

    signal activated()
    signal pinToggled()
    signal pointed()

    height: look.row
    opacity: fade
    scale: 1 - (1 - fade) * look.rowShrink
    transformOrigin: isMirrored ? Item.Right : Item.Left

    Turn {
        id: face
        x: row.isMirrored ? row.width - width : 0
        y: row.look.rowGap / 2
        width: Math.max(height, Math.min(row.width, row.room))
        height: row.height - row.look.rowGap
        isShown: row.isShown
        enterDelay: row.enterDelay
        enterDuration: Motion.search.tileEnter
        enterEasing: Easing.OutBack
        leaveWindow: Motion.pill.leaveWindow / 2

        Press {
            target: face
            isPressed: area.pressed
            isRaised: row.isSelected
            depth: Motion.press.card
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Appearance.color.wash
            opacity: row.isSelected || area.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(row.isSelected || area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                    easing.type: Easing.OutQuad
                }
            }
        }

        AppIcon {
            x: (parent.height - size) / 2
            anchors.verticalCenter: parent.verticalCenter
            app: row.app
            size: row.look.rowIcon
        }

        Text {
            x: parent.height + row.look.rowTextGap
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - parent.height / 2
            elide: Text.ElideRight
            opacity: Math.max(0, row.fade * 2 - 1)
            text: row.app?.name ?? ""
            color: row.isSelected ? Appearance.color.accent : Appearance.color.textBody
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.body

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.hoverIn)
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: parent.height / 2
            anchors.verticalCenter: parent.verticalCenter
            width: row.look.pinDot
            height: width
            radius: width / 2
            color: Appearance.color.accent
            visible: row.isFavorite
        }
    }

    MouseArea {
        id: area
        x: face.x
        width: face.width
        height: row.height
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: row.pointed()
        onClicked: mouse => mouse.button === Qt.RightButton ? row.pinToggled() : row.activated()
    }
}
