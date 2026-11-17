import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: profile

    property Item host: null
    property bool isShown: false
    readonly property var look: Appearance.lock
    readonly property string name: host?.profileName ?? ""
    readonly property string picture: host?.profilePicture ?? ""
    readonly property string bumpKey: host?.bumpKey ?? ""
    readonly property bool isBumpShown: (host?.hasBump ?? false) && isShown
    readonly property string bumpGlyph: ({ call: "headset", media: Activities.isPlaying ? "play" : "pause", recording: "record", notifications: "bell" })[bumpKey] ?? ""
    readonly property string bumpText: bumpKey === "media" ? Activities.title
        : bumpKey === "call" ? Activities.callSource.toUpperCase()
        : bumpKey === "recording" ? "REC"
        : bumpKey === "notifications" ? String(Activities.unreadCount)
        : ""

    anchors.fill: parent

    Turn {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -profile.look.bumpHeight + profile.look.bumpGap + (profile.look.bumpHeight - height) / 2
        isShown: profile.isBumpShown
        enterEasing: Easing.OutBack

        Row {
            spacing: Appearance.unit.small

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                width: profile.look.smallGlyph
                height: width
                name: profile.bumpGlyph
                color: Appearance.color.accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, profile.look.bumpText)
                text: profile.bumpText
                elide: Text.ElideRight
                color: Appearance.color.textBody
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.chip
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: profile.look.rowGap

        Turn {
            anchors.horizontalCenter: parent.horizontalCenter
            width: profile.look.avatar
            height: profile.look.avatar
            isShown: profile.isShown
            enterEasing: Easing.OutBack

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Appearance.color.wash
                border.width: profile.look.avatarRing
                border.color: Appearance.color.accent
            }

            Text {
                anchors.centerIn: parent
                visible: avatarImage.status !== Image.Ready
                text: profile.name.length > 0 ? profile.name.charAt(0).toUpperCase() : "?"
                color: Appearance.color.text
                font.family: Appearance.font.sans
                font.pixelSize: profile.look.initial
            }

            Masked {
                anchors.fill: parent
                anchors.margins: profile.look.avatarRing * 2
                visible: avatarImage.status === Image.Ready

                mask: Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                }

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: profile.picture.length === 0 ? "" : profile.picture.startsWith("/") ? "file://" + profile.picture : profile.picture
                    sourceSize: Qt.size(profile.look.avatar, profile.look.avatar)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        TypedText {
            anchors.horizontalCenter: parent.horizontalCenter
            target: profile.name.length > 0 ? profile.name : "LOCKED"
            isShown: profile.isShown
            color: Appearance.color.text
            font.family: Appearance.font.sans
            font.pixelSize: Appearance.font.body
        }
    }
}
