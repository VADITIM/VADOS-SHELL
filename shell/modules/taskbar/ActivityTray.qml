import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: view

    required property Item host
    required property Item pill
    property bool isShown: false
    property real expansion: 0

    readonly property var look: Appearance.activity.tray
    readonly property var items: Activities.trayItems.slice(0, look.columns)
    readonly property bool hasAny: items.length > 0
    readonly property real iconsLeft: look.height / 2 + look.badge / 2 + Appearance.activity.detailGap
    readonly property real fullWidth: iconsLeft + items.length * look.cell + look.height / 2 - (look.cell - look.icon) / 2
    readonly property size bodySize: Qt.size(Math.max(look.minimum, fullWidth), look.height)

    width: bodySize.width
    height: look.height

    function openItem(item, anchor, isMenu) {
        const point = anchor.mapToItem(null, anchor.width / 2, anchor.height / 2)
        if (isMenu)
            Tray.openMenu(item, view.host.hostWindow, point.x, point.y)
        else
            Tray.open(item, view.host.hostWindow, point.x, point.y)
    }

    Turn {
        x: view.look.height / 2 - width / 2
        y: view.look.height / 2 - height / 2
        width: view.look.badge
        height: view.look.badge
        isShown: view.isShown
        enterDuration: Motion.activity.faceEnter
        leaveDuration: Motion.activity.faceLeave
        leaveWindow: 0

        Rectangle {
            width: view.look.badge
            height: view.look.badge
            radius: width / 2
            color: Appearance.color.wash

            Glyph {
                anchors.centerIn: parent
                width: Appearance.activity.glyph
                height: width
                name: "dots"
                color: view.hasAny ? Appearance.color.accent : Appearance.color.textMuted
            }
        }
    }

    Item {
        id: emptyLine
        x: view.iconsLeft
        y: (view.look.height - height) / 2
        width: view.width - x - view.look.height / 4
        height: emptyText.height
        visible: !view.hasAny
        transform: Upright {
            isMirrored: view.host.isMirrored
            axis: emptyLine.width / 2
        }

        TypedText {
            id: emptyText
            target: view.hasAny ? "" : "NO TRAY ITEMS"
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            leaveBudget: Motion.activity.faceLeave
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true
        }
    }

    Repeater {
        model: view.items

        Turn {
            id: cell
            required property var modelData
            required property int index
            readonly property bool hasIcon: (modelData.icon ?? "").length > 0 && icon.status !== Image.Error
            x: view.iconsLeft + index * view.look.cell + (view.look.cell - width) / 2
            y: (view.look.height - height) / 2
            width: view.look.icon
            height: view.look.icon
            isShown: view.isShown
            enterDelay: (index + 1) * Motion.activity.stagger
            enterDuration: Motion.activity.faceEnter
            leaveDuration: Motion.activity.faceLeave
            leaveWindow: 0

            Press {
                target: cell
                isPressed: cellArea.pressed
                depth: Motion.press.glyph
            }

            Item {
                anchors.fill: parent
                transform: Upright {
                    isMirrored: view.host.isMirrored
                    axis: view.look.icon / 2
                }

                Image {
                    id: icon
                    anchors.fill: parent
                    visible: cell.hasIcon
                    source: cell.modelData.icon ?? ""
                    sourceSize.width: view.look.icon
                    sourceSize.height: view.look.icon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !cell.hasIcon
                    radius: width / 2
                    color: cellArea.containsMouse ? Appearance.color.accent : Appearance.color.wash

                    Text {
                        anchors.centerIn: parent
                        text: (cell.modelData.title ?? cell.modelData.id ?? "?").charAt(0).toUpperCase()
                        color: cellArea.containsMouse ? Appearance.color.ground : Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.bold: true
                    }
                }
            }

            MouseArea {
                id: cellArea
                anchors.centerIn: parent
                width: view.look.cell
                height: view.look.cell
                enabled: view.isShown
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => view.openItem(cell.modelData, cell, mouse.button === Qt.RightButton)
            }
        }
    }
}
