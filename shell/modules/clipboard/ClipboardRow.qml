import QtQuick
import qs.config
import qs.components
import "../../utils/Clipboard.js" as Entries

Item {
    id: row

    property var entry: null
    property bool isShown: false
    property bool isMirrored: false
    property bool isHovered: false
    property int slot: 0
    property real slide: 0

    readonly property var look: Appearance.clipboard
    readonly property bool hasEntry: entry !== null && entry !== undefined
    readonly property string kind: hasEntry ? (entry.isSecret ? "secret" : entry.kind) : ""
    readonly property bool isPinned: hasEntry && entry.isPinned
    readonly property bool isImage: kind === "image" && thumbnail.status === Image.Ready
    readonly property var glyphs: ({ text: "text", url: "link", file: "file", image: "image", secret: "lock" })
    readonly property int centreRank: Math.floor(Math.abs(slot - (look.rows - 1) / 2))
    readonly property real fadeShare: look.fade / Math.max(1, labelBox.width)

    signal pinRequested()

    Turn {
        id: face
        width: row.width
        height: row.height
        isShown: row.isShown && row.hasEntry
        enterDelay: row.centreRank * Motion.clipboard.stagger
        enterDuration: Motion.clipboard.faceEnter
        leaveDuration: Motion.clipboard.faceLeave
        leaveDelay: Math.max(0, row.slot) * Motion.clipboard.leaveStagger
        leaveWindow: 0

        Item {
            id: inner
            x: row.slide
            width: row.width
            height: row.height
            opacity: 1 - Math.min(1, Math.abs(row.slide) / Math.max(1, row.width))

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.color.wash
                opacity: row.isHovered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(row.isHovered ? Motion.hoverIn : Motion.hoverOut)
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Item {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: row.look.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                width: row.look.thumbnail
                height: row.look.thumbnail

                Glyph {
                    anchors.centerIn: parent
                    visible: !row.isImage
                    width: row.look.glyph
                    height: width
                    name: row.glyphs[row.kind] ?? "text"
                    color: row.kind === "url" ? Appearance.color.accent : row.kind === "secret" ? Appearance.color.textMuted : Appearance.color.textBody
                }

                Masked {
                    anchors.fill: parent
                    visible: row.kind === "image"
                    mask: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.radius.small
                    }

                    Image {
                        id: thumbnail
                        anchors.fill: parent
                        source: row.kind === "image" ? "file://" + row.entry.path : ""
                        sourceSize.width: row.look.thumbnail * 2
                        sourceSize.height: row.look.thumbnail * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }
                }
            }

            Item {
                id: labelBox
                anchors.left: icon.right
                anchors.leftMargin: row.look.iconGap
                anchors.right: pin.left
                anchors.rightMargin: row.look.rowPadding / 2
                height: parent.height

                Text {
                    id: label
                    visible: !masked.visible
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignLeft
                    text: row.hasEntry ? Entries.labelOf(row.entry) : ""
                    color: row.kind === "url" ? Appearance.color.accent : row.kind === "secret" || row.kind === "image" ? Appearance.color.textMuted : Appearance.color.textBody
                    font.family: Appearance.font.mono
                    font.pixelSize: row.kind === "image" ? row.look.label : row.look.text
                    font.letterSpacing: row.kind === "secret" || row.kind === "image" ? Appearance.font.labelSpacing : 0
                    font.bold: row.kind === "image"
                }

                Masked {
                    id: masked
                    anchors.fill: parent
                    visible: label.implicitWidth > labelBox.width
                    mask: Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: row.isMirrored ? "transparent" : "white" }
                            GradientStop { position: row.isMirrored ? Math.min(1, row.fadeShare) : Math.max(0, 1 - row.fadeShare); color: "white" }
                            GradientStop { position: 1; color: row.isMirrored ? "white" : "transparent" }
                        }
                    }

                    Text {
                        width: labelBox.width
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignLeft
                        text: label.text
                        color: label.color
                        font: label.font
                    }
                }
            }

            GlyphButton {
                id: pin
                anchors.right: parent.right
                anchors.rightMargin: row.look.rowPadding / 2
                anchors.verticalCenter: parent.verticalCenter
                width: row.look.action
                height: row.look.action
                glyphName: "pin"
                glyphSize: row.look.actionGlyph
                isSelected: row.isPinned
                opacity: row.isPinned || row.isHovered ? 1 : 0
                enabled: row.isShown && row.hasEntry
                onClicked: row.pinRequested()

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(row.isHovered ? Motion.hoverIn : Motion.hoverOut)
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
