import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: notifications

    property Item host: null
    property bool isShown: false
    readonly property var look: Appearance.lock
    readonly property var senders: {
        const counted = []
        for (const notification of Notifications.list) {
            const name = (notification.appName || "UNKNOWN").toUpperCase()
            const found = counted.find(entry => entry.name === name)
            if (found)
                found.count += 1
            else
                counted.push({ name: name, count: 1 })
        }
        return counted.slice(0, look.notificationRows)
    }

    anchors.fill: parent

    Column {
        anchors.fill: parent
        anchors.margins: notifications.look.padding
        spacing: notifications.look.rowGap

        Item {
            width: parent.width
            height: heading.height

            TypedText {
                id: heading
                target: "NOTIFICATIONS"
                isShown: notifications.isShown
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }

            TypedText {
                anchors.right: parent.right
                target: String(Notifications.list.length)
                isShown: notifications.isShown
                color: Appearance.color.accent
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
            }
        }

        TypedText {
            visible: notifications.senders.length === 0
            target: "NOTHING NEW"
            isShown: notifications.isShown && notifications.senders.length === 0
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }

        Repeater {
            model: notifications.senders

            Turn {
                id: sender

                required property var modelData
                required property int index

                width: parent.width
                isShown: notifications.isShown
                enterDelay: index * Motion.pill.elementStagger
                enterEasing: Easing.OutBack

                Item {
                    width: parent.width
                    height: Math.max(bell.height, name.implicitHeight)

                    Glyph {
                        id: bell
                        anchors.verticalCenter: parent.verticalCenter
                        width: notifications.look.smallGlyph
                        height: width
                        name: "bell"
                        color: Appearance.color.textMuted
                    }

                    Text {
                        id: name
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: bell.right
                        anchors.leftMargin: Appearance.unit.small
                        anchors.right: count.left
                        anchors.rightMargin: Appearance.unit.small
                        text: sender.modelData.name
                        elide: Text.ElideRight
                        color: Appearance.color.textBody
                        font.family: Appearance.font.sans
                        font.pixelSize: Appearance.font.label
                    }

                    Text {
                        id: count
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        text: String(sender.modelData.count)
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                    }
                }
            }
        }
    }
}
