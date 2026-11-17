import QtQuick
import qs.config
import qs.components

Item {
    id: menu

    property bool isOpen: false
    property bool isFavorite: false
    property bool isHidden: false
    property int highlighted: 0
    readonly property var look: Appearance.search.menu
    readonly property var actions: [
        { key: "favorite", label: isFavorite ? "UNFAVORITE" : "FAVORITE" },
        { key: "hide", label: isHidden ? "UNHIDE" : "HIDE" }
    ]

    signal chosen(string key)

    function moveHighlight(offset) {
        highlighted = (highlighted + offset + actions.length) % actions.length
    }

    width: look.width
    height: actions.length * look.item + look.padding * 2
    visible: pop.presence > 0
    scale: look.from + (1 - look.from) * pop.presence
    opacity: pop.presence
    transformOrigin: Item.TopLeft

    onIsOpenChanged: if (isOpen) highlighted = 0

    Turn {
        id: pop
        isShown: menu.isOpen
        isFlipping: false
        enterDuration: Motion.search.menu
        enterEasing: Easing.OutBack
        leaveDuration: Motion.search.menuOut
        leaveWindow: 0
    }

    Rectangle {
        anchors.fill: parent
        radius: menu.look.corner
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

            x: menu.look.padding
            y: menu.look.padding + index * menu.look.item
            width: menu.width - menu.look.padding * 2
            height: menu.look.item

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.color.wash
                opacity: menu.highlighted === item.index ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.hoverIn)
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Text {
                x: menu.look.textPadding
                anchors.verticalCenter: parent.verticalCenter
                text: item.modelData.label
                color: menu.highlighted === item.index ? Appearance.color.accent : Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: menu.isOpen
                cursorShape: Qt.PointingHandCursor
                onEntered: menu.highlighted = item.index
                onClicked: menu.chosen(item.modelData.key)
            }
        }
    }
}
