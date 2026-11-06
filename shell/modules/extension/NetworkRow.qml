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

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.color.wash
                opacity: area.containsMouse || row.isActive ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: area.containsMouse ? Motion.hoverIn : Motion.hoverOut
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Glyph {
                x: Appearance.extension.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.extension.glyph
                height: Appearance.extension.glyph
                name: "wifi"
                level: row.modelData.strength
                color: row.isActive ? Appearance.color.accent : Appearance.color.textBody
            }

            Text {
                x: Appearance.extension.rowPadding * 2 + Appearance.extension.glyph
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x - Appearance.extension.rowPadding * 2 - Appearance.extension.lock
                elide: Text.ElideRight
                text: row.modelData.ssid.toUpperCase()
                color: row.isActive ? Appearance.color.text : Appearance.color.textBody
                font.family: Appearance.font.mono
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
                visible: row.modelData.isSecured
                name: "lock"
                color: Appearance.color.textMuted
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Network.connectTo(row.modelData.ssid)
            }
        }
    }
}
