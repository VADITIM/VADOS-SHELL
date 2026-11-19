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
    property int order: 0
    property real slide: 0

    readonly property var look: Appearance.clipboard
    readonly property bool hasEntry: entry !== null && entry !== undefined
    readonly property string kind: hasEntry ? (entry.isSecret ? "secret" : entry.kind) : ""
    readonly property bool isPinned: hasEntry && entry.isPinned
    readonly property bool isTall: kind === "image"
    readonly property bool isImage: isTall && thumbnail.status === Image.Ready
    readonly property bool isArrived: face.isShown && face.presence > 0
    readonly property var glyphs: ({ text: "text", url: "link", file: "file", image: "image", secret: "lock" })
    readonly property color inkColor: kind === "url" ? Appearance.color.accent : kind === "secret" || kind === "image" ? Appearance.color.textMuted : Appearance.color.textBody

    signal pinRequested()

    Turn {
        id: face
        width: row.width
        height: row.height
        isShown: row.isShown && row.hasEntry
        isFlipping: false
        enterDelay: row.order * Motion.clipboard.stagger
        enterDuration: Motion.clipboard.rowEnter
        leaveDuration: Motion.clipboard.faceLeave
        leaveDelay: row.order * Motion.clipboard.leaveStagger
        leaveWindow: 0

        Item {
            id: inner
            x: row.slide
            width: row.width
            height: row.height
            opacity: 1 - Math.min(1, Math.abs(row.slide) / Math.max(1, row.width))

            Rectangle {
                anchors.fill: parent
                radius: row.look.rowRadius
                color: Appearance.color.wash
                opacity: (row.isHovered ? 1 : row.look.restShare) * Math.min(1, face.presence)

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(row.isHovered ? Motion.hoverIn : Motion.hoverOut)
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Turn {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: row.isTall ? row.look.imageInset : row.look.rowPadding
                anchors.verticalCenter: parent.verticalCenter
                width: row.isTall ? pinTurn.x - row.look.rowPadding / 2 - anchors.leftMargin : row.look.thumbnail
                height: row.isTall ? row.height - row.look.imageInset * 2 : row.look.thumbnail
                isShown: row.isArrived
                isFlipping: true
                flipAngle: 0
                spinAngle: row.isTall ? 0 : Motion.clipboard.iconSpin
                enterDuration: Motion.clipboard.iconEnter
                enterEasing: Easing.OutBack
                leaveDuration: Motion.clipboard.faceLeave
                leaveWindow: 0

                Glyph {
                    anchors.centerIn: parent
                    visible: !row.isImage
                    width: row.look.glyph
                    height: width
                    name: row.glyphs[row.kind] ?? "text"
                    color: row.kind === "url" ? Appearance.color.accent : row.kind === "secret" ? Appearance.color.textMuted : Appearance.color.textBody
                }

                Masked {
                    readonly property real fit: thumbnail.implicitWidth > 0 && thumbnail.implicitHeight > 0
                        ? Math.min(parent.width / thumbnail.implicitWidth, parent.height / thumbnail.implicitHeight)
                        : 0
                    anchors.centerIn: parent
                    width: thumbnail.implicitWidth * fit
                    height: thumbnail.implicitHeight * fit
                    visible: row.isTall
                    mask: Rectangle {
                        anchors.fill: parent
                        radius: row.look.rowRadius - row.look.imageInset
                    }

                    Image {
                        id: thumbnail
                        anchors.fill: parent
                        source: row.isTall ? "file://" + row.entry.path : ""
                        sourceSize.width: row.look.width
                        sourceSize.height: row.look.row * row.look.imageSpan
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                        smooth: true
                    }
                }
            }

            LabelReveal {
                id: labelBox
                anchors.left: icon.right
                anchors.leftMargin: row.look.iconGap
                anchors.right: pinTurn.left
                anchors.rightMargin: row.look.rowPadding / 2
                height: parent.height
                visible: !row.isTall
                label: "clipboard entry"
                sweepWidth: Math.min(label.implicitWidth, width)
                isShown: row.isArrived
                leaveDuration: Motion.clipboard.faceLeave
                barColor: row.inkColor

                Text {
                    id: label
                    width: labelBox.width
                    height: labelBox.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    maximumLineCount: row.look.maxLines
                    elide: Text.ElideRight
                    text: row.hasEntry ? Entries.labelOf(row.entry) : ""
                    color: row.inkColor
                    font.family: Appearance.font.sans
                    font.pixelSize: row.kind === "secret" ? row.look.label : row.look.text
                    font.letterSpacing: row.kind === "secret" ? Appearance.font.labelSpacing : 0
                }
            }

            Turn {
                id: pinTurn
                anchors.right: parent.right
                anchors.rightMargin: row.look.rowPadding / 2
                y: ((row.isTall ? row.look.row : row.height) - row.look.action) / 2
                width: row.look.action
                height: row.look.action
                isShown: row.isArrived
                enterDelay: Motion.clipboard.stagger
                enterDuration: Motion.clipboard.faceEnter
                leaveDuration: Motion.clipboard.faceLeave
                leaveWindow: 0

                GlyphButton {
                    id: pin
                    anchors.fill: parent
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
}
