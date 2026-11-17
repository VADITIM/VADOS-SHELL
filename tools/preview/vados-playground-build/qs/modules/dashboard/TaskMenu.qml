import QtQuick
import qs.config
import qs.components
import "../../utils/Processes.js" as ProcessTable

Item {
    id: menu

    property bool isOpen: false
    property bool canKill: true
    property int highlighted: 0
    readonly property var look: Appearance.dashboard.task
    readonly property var actions: ProcessTable.actions

    signal chosen(string key)

    function isEnabled(key) {
        return key !== "kill" || canKill
    }

    function moveHighlight(offset) {
        let next = highlighted
        for (let tries = 0; tries < actions.length; tries++) {
            next = (next + offset + actions.length) % actions.length
            if (isEnabled(actions[next].key))
                break
        }
        highlighted = next
    }

    function choose(index) {
        if (isEnabled(actions[index].key))
            chosen(actions[index].key)
    }

    width: look.menuWidth
    height: actions.length * look.menuItem + look.menuPadding * 2
    visible: pop.presence > 0
    scale: 0.6 + 0.4 * pop.presence
    opacity: pop.presence
    transformOrigin: Item.TopLeft

    onIsOpenChanged: if (isOpen) highlighted = canKill ? 0 : 1

    Turn {
        id: pop
        isShown: menu.isOpen
        isFlipping: false
        enterDuration: Motion.dashboard.menu
        enterEasing: Easing.OutBack
        leaveDuration: Motion.dashboard.menuOut
        leaveWindow: 0
    }

    Rectangle {
        anchors.fill: parent
        radius: menu.look.menuCorner
        color: Appearance.color.ground
        border.width: 1
        border.color: Appearance.color.hairline
    }

    Repeater {
        model: menu.actions

        Item {
            id: item

            required property var modelData
            required property int index
            readonly property bool isEnabled: menu.isEnabled(modelData.key)

            x: menu.look.menuPadding
            y: menu.look.menuPadding + index * menu.look.menuItem
            width: menu.width - menu.look.menuPadding * 2
            height: menu.look.menuItem

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.color.wash
                opacity: item.isEnabled && (menu.highlighted === item.index || itemArea.containsMouse) ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.hoverIn)
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Text {
                x: menu.look.cellPadding * 2
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.label
                color: !item.isEnabled ? Appearance.color.textFaint : item.modelData.key === "kill" ? Appearance.color.danger : Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: menu.look.font.menu
                font.letterSpacing: Appearance.font.labelSpacing
            }

            MouseArea {
                id: itemArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: menu.isOpen
                cursorShape: item.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: if (item.isEnabled) menu.highlighted = item.index
                onClicked: menu.choose(item.index)
            }
        }
    }
}
