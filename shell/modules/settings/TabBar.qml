import QtQuick
import qs.config
import qs.components

Item {
    id: bar

    property var tabs: []
    property string currentKey
    property bool isShown: false
    property color fill: Appearance.color.accent
    property color ink: Appearance.color.ground
    readonly property var look: Appearance.settings.navigation
    readonly property int currentIndex: tabs.findIndex(tab => tab.key === currentKey)
    readonly property bool hasCurrent: currentIndex >= 0

    signal picked(string key)

    width: look.width
    height: tabs.length * look.item + Math.max(0, tabs.length - 1) * look.itemGap + look.padding * 2

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: bar.fill
        scale: barTurn.presence
        opacity: barTurn.presence

        Turn {
            id: barTurn
            isShown: bar.isShown
            enterEasing: Easing.OutBack
            leaveWindow: 0
        }
    }

    Rectangle {
        x: (bar.width - bar.look.item) / 2
        y: bar.look.padding + Math.max(0, bar.currentIndex) * (bar.look.item + bar.look.itemGap)
        width: bar.look.item
        height: bar.look.item
        radius: height / 2
        color: Qt.alpha(bar.ink, bar.look.selection)
        scale: highlightTurn.presence

        Behavior on y {
            NumberAnimation {
                duration: Motion.pace(Motion.highlight.slide)
                easing.type: Easing.OutBack
            }
        }

        Turn {
            id: highlightTurn
            isShown: bar.isShown && bar.hasCurrent
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

            x: (bar.width - bar.look.item) / 2
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
                    color: Qt.alpha(bar.ink, entry.isCurrent || area.containsMouse ? 1 : bar.look.resting)

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.hoverIn)
                        }
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
