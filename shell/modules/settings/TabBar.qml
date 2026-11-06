import QtQuick
import qs.config
import qs.components

Item {
    id: bar

    property var tabs: []
    property string currentKey
    property bool isShown: false
    readonly property var look: Appearance.settings.tabBar
    readonly property int currentIndex: Math.max(0, tabs.findIndex(tab => tab.key === currentKey))

    signal picked(string key)

    width: look.width
    height: tabs.length * look.item + Math.max(0, tabs.length - 1) * look.itemGap + look.padding * 2

    Rectangle {
        x: bar.look.padding
        y: bar.look.padding + bar.currentIndex * (bar.look.item + bar.look.itemGap)
        width: bar.look.item
        height: bar.look.item
        radius: height / 2
        color: Appearance.color.wash
        scale: highlightTurn.presence

        Behavior on y {
            NumberAnimation {
                duration: Motion.highlight.slide
                easing.type: Easing.OutBack
            }
        }

        Turn {
            id: highlightTurn
            isShown: bar.isShown
            enterDelay: bar.tabs.length * Motion.pill.elementStagger
            leaveWindow: 0
        }
    }

    Repeater {
        model: bar.tabs

        Item {
            id: entry

            required property var modelData
            required property int index
            readonly property bool isCurrent: bar.currentKey === modelData.key

            x: bar.look.padding
            y: bar.look.padding + index * (bar.look.item + bar.look.itemGap)
            width: bar.look.item
            height: bar.look.item

            Turn {
                id: tabGlyph
                x: (entry.width - width) / 2
                y: (entry.height - height) / 2
                width: bar.look.glyph
                height: bar.look.glyph
                isShown: bar.isShown
                enterDelay: entry.index * Motion.pill.elementStagger
                enterEasing: Easing.OutBack

                Press {
                    target: tabGlyph
                    isPressed: area.pressed
                    depth: Motion.press.glyph
                }

                Glyph {
                    anchors.fill: parent
                    name: entry.modelData.glyph
                    color: entry.isCurrent ? Appearance.color.accent : area.containsMouse ? Appearance.color.text : Appearance.color.textMuted

                    Behavior on color {
                        ColorAnimation { duration: Motion.hoverIn }
                    }
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                enabled: bar.isShown
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.picked(entry.modelData.key)
            }
        }
    }
}
