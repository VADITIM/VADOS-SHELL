import QtQuick
import qs.config
import qs.components

Item {
    id: tile

    property var app: null
    property bool isSelected: false
    property bool isFavorite: false
    property bool isShown: false
    property int enterDelay: 0

    readonly property var look: Appearance.search

    signal activated()
    signal pinToggled()
    signal pointed()

    width: look.tile + look.tileGap
    height: look.tile + look.label + look.tileGap

    Turn {
        id: face
        anchors.fill: parent
        anchors.margins: tile.look.tileGap / 2
        isShown: tile.isShown
        enterDelay: tile.enterDelay
        enterDuration: Motion.search.tileEnter
        enterEasing: Easing.OutBack
        leaveWindow: Motion.pill.leaveWindow / 2

        Press {
            target: face
            isPressed: area.pressed
            isRaised: tile.isSelected
            depth: Motion.press.tile
        }

        Item {
            anchors.fill: parent

            AppIcon {
                app: tile.app
                size: tile.look.tile
            }

            Text {
                y: tile.look.tile + tile.look.nameGap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: tile.app?.name ?? ""
                color: tile.isSelected ? Appearance.color.accent : Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: tile.look.name

                Behavior on color {
                    ColorAnimation { duration: Motion.pace(Motion.hoverIn) }
                }
            }

            Rectangle {
                x: tile.look.tile - width
                width: 6
                height: 6
                radius: 3
                color: Appearance.color.accent
                visible: tile.isFavorite
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: tile.look.tileGap / 2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: tile.pointed()
        onClicked: mouse => mouse.button === Qt.RightButton ? tile.pinToggled() : tile.activated()
    }
}
