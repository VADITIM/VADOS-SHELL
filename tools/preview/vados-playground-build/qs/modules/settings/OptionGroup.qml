import QtQuick
import qs.config
import qs.components

Item {
    id: group

    property string label
    property var options: []
    property string current
    readonly property var look: Appearance.settings.choice
    readonly property int currentIndex: options.indexOf(current)
    readonly property Item currentEntry: currentIndex >= 0 && entries.count === options.length ? entries.itemAt(currentIndex) : null
    readonly property bool hasLabel: label.length > 0
    readonly property bool isInline: hasLabel && caption.implicitWidth + look.inlineGap + line.width <= width

    signal picked(string option)

    width: parent ? parent.width : implicitWidth
    implicitWidth: line.width
    height: hasLabel && !isInline ? caption.implicitHeight + look.labelGap + look.height : look.height

    Piece {
        role: "label"
        visible: group.hasLabel
        y: group.isInline ? Math.round((group.look.height - caption.implicitHeight) / 2) : 0

        Text {
            id: caption
            text: group.label
            color: Appearance.color.textBody
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Flickable {
        id: strip

        readonly property bool isOverflowing: line.width > group.width

        x: group.isInline ? group.width - line.width : 0
        y: group.height - group.look.height
        width: Math.min(line.width, group.width)
        height: group.look.height
        contentWidth: line.width
        contentHeight: group.look.height
        interactive: isOverflowing
        clip: isOverflowing
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds

        Drift {
            enabled: strip.isOverflowing
            isHorizontal: true
        }

        Piece {
            isCentered: true
            visible: group.currentEntry !== null
            x: group.currentEntry ? group.currentEntry.x + group.currentEntry.optionX : 0
            width: group.currentEntry ? group.currentEntry.optionWidth : 0
            height: group.look.height

            Behavior on x {
                NumberAnimation {
                    duration: Motion.pace(Motion.settings.marker)
                    easing.type: Easing.OutBack
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Motion.pace(Motion.settings.marker)
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.choice.isPill ? Appearance.choice.pill : "transparent"
                border.width: Appearance.choice.isPill ? 0 : group.look.ring
                border.color: Appearance.choice.outline
            }
        }

        Row {
            id: line

            Repeater {
                id: entries
                model: group.options

                Row {
                    id: entry

                    required property string modelData
                    required property int index
                    readonly property bool isCurrent: group.current === modelData
                    readonly property real optionX: divider.visible ? divider.width : 0
                    readonly property real optionWidth: option.width

                    Item {
                        id: divider
                        visible: entry.index > 0
                        width: group.look.gap * 2 + 1
                        height: group.look.height

                        Piece {
                            role: "hint"
                            anchors.centerIn: parent
                            width: 1
                            height: group.look.divider

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.color.hairline
                            }
                        }
                    }

                    Item {
                        id: option
                        width: name.implicitWidth + group.look.padding * 2
                        height: group.look.height

                        Piece {
                            id: face
                            anchors.fill: parent
                            isCentered: true

                            Item {
                                id: press
                                anchors.fill: parent

                                Press {
                                    target: press
                                    isPressed: area.pressed
                                }

                                Text {
                                    id: name
                                    anchors.centerIn: parent
                                    text: entry.modelData.toUpperCase()
                                    color: entry.isCurrent ? (Appearance.choice.isPill ? Appearance.choice.pillInk : Appearance.choice.outline) : area.containsMouse ? Appearance.color.text : Appearance.color.textMuted
                                    font.family: Appearance.font.mono
                                    font.pixelSize: group.look.text
                                    font.letterSpacing: group.look.spacing
                                    font.bold: true

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Motion.pace(Motion.hoverIn)
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: group.picked(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
