import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: trayIdle

    readonly property var items: Tray.items.slice(0, Appearance.taskbar.trayLimit)

    idleKey: "tray"
    isAvailable: items.length > 0
    isKeptCompact: true
    glyphName: "dots"

    function openItem(item, anchor, isMenu) {
        const point = anchor.mapToItem(null, anchor.width / 2, anchor.height / 2)
        if (isMenu)
            Tray.openMenu(item, trayIdle.host.hostWindow, point.x, point.y)
        else
            Tray.open(item, trayIdle.host.hostWindow, point.x, point.y)
    }

    Row {
        height: Appearance.taskbar.idleSize

        Repeater {
            model: trayIdle.items

            Turn {
                id: cell

                required property var modelData
                required property int index
                readonly property bool hasIcon: (modelData.icon ?? "").length > 0 && icon.status !== Image.Error
                readonly property string hoverName: (modelData.tooltipTitle || modelData.title || modelData.id || "").toUpperCase()

                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.taskbar.trayCell
                height: Appearance.taskbar.trayCell
                isShown: trayIdle.isUnfolded
                enterDelay: (index + 1) * Motion.pill.elementStagger
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                Press {
                    target: cell
                    isPressed: cellArea.pressed
                    isRaised: cellArea.containsMouse
                    depth: Motion.press.glyph
                }

                Image {
                    id: icon
                    anchors.centerIn: parent
                    width: Appearance.taskbar.trayIcon
                    height: Appearance.taskbar.trayIcon
                    visible: cell.hasIcon
                    source: cell.modelData.icon ?? ""
                    sourceSize.width: Appearance.taskbar.trayIcon
                    sourceSize.height: Appearance.taskbar.trayIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Appearance.taskbar.trayIcon
                    height: Appearance.taskbar.trayIcon
                    visible: !cell.hasIcon
                    radius: width / 2
                    color: cellArea.containsMouse ? Appearance.color.accent : Appearance.color.wash

                    Text {
                        anchors.centerIn: parent
                        text: (cell.modelData.title || cell.modelData.id || "?").charAt(0).toUpperCase()
                        color: cellArea.containsMouse ? Appearance.color.ground : Appearance.color.text
                        font.family: Appearance.font.sans
                        font.pixelSize: Appearance.font.chip
                        font.bold: true
                    }
                }

                MouseArea {
                    id: cellArea
                    anchors.fill: parent
                    enabled: trayIdle.isUnfolded
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => trayIdle.openItem(cell.modelData, cell, mouse.button === Qt.RightButton)
                }
            }
        }
    }
}
