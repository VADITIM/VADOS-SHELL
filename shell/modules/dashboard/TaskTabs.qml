import QtQuick
import qs.config
import qs.components
import "../../utils/Processes.js" as ProcessTable

Item {
    id: tabs

    property bool isShown: false
    property bool isMirrored: false
    property string current: ""
    property Item shapes: null
    property real stackRight: 0
    property real centerY: 0
    readonly property var look: Appearance.dashboard.task
    readonly property real stackHeight: ProcessTable.tabs.length * look.tab + (ProcessTable.tabs.length - 1) * look.tabGap

    signal picked(string key)

    Repeater {
        model: ProcessTable.tabs

        Item {
            id: pill

            required property var modelData
            required property int index
            readonly property bool isCurrent: tabs.current === modelData.key
            readonly property real presence: turn.presence
            readonly property real baseLeft: tabs.stackRight - width + (1 - presence) * (width + tabs.look.tabOut)
            readonly property real baseTop: tabs.centerY - tabs.stackHeight / 2 + index * (tabs.look.tab + tabs.look.tabGap)

            visible: presence > 0.01
            x: tabs.isMirrored ? tabs.width - baseLeft - width : baseLeft
            y: baseTop
            width: tabs.look.tab
            height: tabs.look.tab

            Accessible.role: Accessible.PageTab
            Accessible.name: modelData.label

            Turn {
                id: turn
                isShown: tabs.isShown
                isFlipping: false
                enterDelay: pill.index * Motion.dashboard.taskTabStagger
                enterEasing: Easing.OutBack
                leaveDuration: Motion.dashboard.taskTabLeave
                leaveWindow: 0
            }

            LiquidShape {
                parent: tabs.shapes
                visible: pill.visible
                x: pill.baseLeft
                y: pill.baseTop
                width: pill.width
                height: pill.height
            }

            Item {
                id: face
                anchors.fill: parent
                opacity: tabs.isShown ? Math.min(1, pill.presence * 1.6) : 0

                Press {
                    target: face
                    isPressed: area.pressed
                    depth: Motion.press.glyph
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Appearance.color.accent
                    opacity: pill.isCurrent ? 1 : 0

                    Behavior on opacity {
                        enabled: tabs.isShown

                        NumberAnimation {
                            duration: Motion.pace(Motion.dashboard.taskTab)
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Appearance.color.wash
                    opacity: !pill.isCurrent && area.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.pace(area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Glyph {
                    anchors.centerIn: parent
                    width: tabs.look.tabGlyph
                    height: tabs.look.tabGlyph
                    name: pill.modelData.glyph
                    stroke: Appearance.dashboard.iconStroke * 24 / width
                    color: pill.isCurrent ? Appearance.color.ground : Appearance.color.textMuted
                    rotation: (1 - pill.presence) * Motion.dashboard.taskTabSpin

                    Behavior on color {
                        enabled: tabs.isShown

                        ColorAnimation {
                            duration: Motion.pace(Motion.dashboard.taskTab)
                        }
                    }
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                enabled: tabs.isShown
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tabs.picked(pill.modelData.key)
            }
        }
    }
}
