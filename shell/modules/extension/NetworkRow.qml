import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: row

    required property var modelData
    required property int index
    property bool isShown: false
    property bool isSettled: false
    readonly property bool isActive: modelData.isActive
    readonly property bool isKnown: Network.known.indexOf(modelData.ssid) >= 0
    readonly property bool isJoining: Network.joining === modelData.ssid
    property bool isForgetting: false

    width: ListView.view.width
    height: Appearance.extension.row + Appearance.extension.rowGap

    Component.onCompleted: {
        if (isSettled)
            turn.snap(1)
    }

    Turn {
        id: turn
        width: row.width
        height: Appearance.extension.row
        isShown: row.isShown
        enterDelay: Math.min(row.index, 8) * Motion.reveal.stagger

        Press {
            target: face
            isPressed: area.pressed
        }

        Item {
            id: face
            anchors.fill: parent

            Sweep {
                anchors.fill: parent
                isOn: rowHover.hovered
                fill: Appearance.extension.hoverWash
            }

            Sweep {
                anchors.fill: parent
                isOn: row.isActive
            }

            Glyph {
                x: Appearance.extension.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.extension.glyph
                height: Appearance.extension.glyph
                name: "wifi"
                level: row.modelData.strength
                color: row.isActive || row.isJoining ? Appearance.color.accent : rowHover.hovered ? Appearance.color.text : Appearance.color.textBody
            }

            Text {
                x: Appearance.extension.rowPadding * 2 + Appearance.extension.glyph
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - Appearance.extension.rowPadding * 2 - Appearance.extension.lock
                elide: Text.ElideRight
                text: row.modelData.ssid.toUpperCase()
                color: row.isActive || rowHover.hovered ? Appearance.color.text : Appearance.color.textBody
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }

            Glyph {
                anchors.right: parent.right
                anchors.rightMargin: Appearance.extension.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.extension.lock
                height: Appearance.extension.lock
                visible: row.modelData.isSecured && !row.isForgetting
                name: "lock"
                color: Appearance.color.textMuted
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        row.isForgetting = row.isKnown && !row.isForgetting
                    else
                        Network.connectTo(row.modelData.ssid, false)
                }
            }

            HoverHandler {
                id: rowHover
                onHoveredChanged: {
                    if (!hovered)
                        row.isForgetting = false
                }
            }

            Turn {
                anchors.right: parent.right
                anchors.rightMargin: Appearance.extension.rowPadding / 2
                anchors.verticalCenter: parent.verticalCenter
                visible: presence > 0
                isShown: row.isForgetting
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    label: "FORGET"
                    isArmed: true
                    onClicked: {
                        row.isForgetting = false
                        Network.forget(row.modelData.ssid)
                    }
                }
            }
        }
    }
}
