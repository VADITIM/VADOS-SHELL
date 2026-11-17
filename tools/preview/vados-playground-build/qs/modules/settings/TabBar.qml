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
    property color labelFill: fill
    property bool isMirrored: false
    property var shownTabs: []
    property bool isSwapping: false
    property real glyphFlip: -90
    property real glyphSpin: 0
    readonly property var look: Appearance.settings.navigation
    readonly property int currentIndex: shownTabs.findIndex(tab => tab.key === currentKey)
    readonly property bool hasCurrent: currentIndex >= 0

    signal picked(string key)

    function keysOf(list) {
        return list.map(tab => tab.key).join("\n")
    }

    function mutate() {
        if (tabs.length === 0)
            return
        if (keysOf(tabs) === keysOf(shownTabs)) {
            shownTabs = tabs
            return
        }
        if (barTurn.presence <= 0 || shownTabs.length === 0) {
            swap.stop()
            isSwapping = false
            shownTabs = tabs
            return
        }
        isSwapping = true
        swap.restart()
    }

    width: look.width
    height: shownTabs.length * look.item + Math.max(0, shownTabs.length - 1) * look.itemGap + look.padding * 2

    onTabsChanged: mutate()
    Component.onCompleted: shownTabs = tabs

    Behavior on height {
        enabled: barTurn.presence > 0
        NumberAnimation {
            duration: Motion.pace(Motion.settings.subReshape)
            easing.type: Easing.OutBack
        }
    }

    Timer {
        id: swap
        interval: Motion.pace(Motion.settings.subLeave)
        onTriggered: {
            if (bar.tabs.length > 0)
                bar.shownTabs = bar.tabs
            bar.isSwapping = false
        }
    }

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
            isShown: bar.isShown && bar.hasCurrent && !bar.isSwapping
            enterDelay: bar.shownTabs.length * Motion.pill.elementStagger
            leaveWindow: 0
        }
    }

    Repeater {
        model: bar.shownTabs

        Item {
            id: entry

            required property var modelData
            required property int index
            readonly property bool isCurrent: bar.currentKey === modelData.key

            x: (bar.width - bar.look.item) / 2
            y: bar.look.padding + index * (bar.look.item + bar.look.itemGap)
            z: area.containsMouse ? 1 : 0
            width: bar.look.item
            height: bar.look.item

            Turn {
                id: tabGlyph
                x: (entry.width - width) / 2
                y: (entry.height - height) / 2
                width: bar.look.glyph
                height: bar.look.glyph
                isShown: bar.isShown && !bar.isSwapping
                enterDelay: entry.index * Motion.pill.elementStagger
                enterEasing: Easing.OutBack
                flipAngle: bar.glyphFlip
                spinAngle: bar.glyphSpin
                leaveWindow: 0
                leaveDuration: Motion.settings.subLeave

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

            Turn {
                id: tip
                x: bar.isMirrored ? -width - bar.look.labelGap : entry.width + bar.look.labelGap
                y: (entry.height - height) / 2
                width: tipText.implicitWidth + bar.look.labelPadding * 2
                height: bar.look.label
                isShown: bar.isShown && area.containsMouse
                enterEasing: Easing.OutBack
                leaveWindow: 0

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: bar.labelFill
                }

                Text {
                    id: tipText
                    anchors.centerIn: parent
                    text: entry.modelData.label
                    color: bar.ink
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                enabled: bar.isShown && !bar.isSwapping
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.picked(entry.modelData.key)
            }
        }
    }
}
