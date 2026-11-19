import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services
import qs.components

Item {
    id: view

    required property Item host
    required property Item pill
    property bool isShown: false
    property real expansion: 0

    readonly property var look: Appearance.activity.media
    readonly property size bodySize: Qt.size(look.width, look.height)
    readonly property real headSize: look.head * Math.min(1.1, expansion) * pill.popScale
    readonly property real detailsLeft: look.height / 2 + look.ring / 2 + Appearance.activity.expanded.detailGap

    width: look.width
    height: look.height

    LiquidShape {
        parent: view.host.liquidShapes
        visible: view.headSize > 0.5
        width: view.headSize
        height: view.headSize
        x: view.pill.x + view.pill.expandedLeft + view.pill.bodyHeight / 2 - width / 2
        y: view.pill.y - height / 2
    }

    Turn {
        id: artTurn
        x: view.look.height / 2 - width / 2
        y: view.look.height / 2 - height / 2
        width: view.look.ring
        height: view.look.ring
        isShown: view.isShown
        enterDuration: Motion.activity.faceEnter
        leaveDuration: Motion.activity.faceLeave
        leaveDelay: Motion.activity.leaveStagger * 3
        leaveWindow: 0

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transform: Upright {
                isMirrored: view.host.isMirrored
                axis: view.look.ring / 2
            }

            ShapePath {
                strokeColor: Appearance.color.hairline
                strokeWidth: view.look.ringStroke
                fillColor: "transparent"
                PathAngleArc {
                    centerX: view.look.ring / 2
                    centerY: view.look.ring / 2
                    radiusX: (view.look.ring - view.look.ringStroke) / 2
                    radiusY: radiusX
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                strokeColor: Appearance.color.accent
                strokeWidth: view.look.ringStroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: view.look.ring / 2
                    centerY: view.look.ring / 2
                    radiusX: (view.look.ring - view.look.ringStroke) / 2
                    radiusY: radiusX
                    startAngle: -90
                    sweepAngle: 360 * Activities.progress
                }
            }
        }

        Item {
            id: art
            x: (view.look.ring - width) / 2
            y: (view.look.ring - height) / 2
            width: view.look.art
            height: view.look.art
            transform: Upright {
                isMirrored: view.host.isMirrored
                axis: view.look.art / 2
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Appearance.color.wash
                visible: cover.status !== Image.Ready

                Glyph {
                    anchors.centerIn: parent
                    width: Appearance.activity.expanded.glyph * 1.6
                    height: width
                    name: "music"
                    color: Appearance.color.textMuted
                }
            }

            Masked {
                anchors.fill: parent
                visible: cover.status === Image.Ready
                mask: Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: Activities.artUrl
                    sourceSize.width: view.look.art * 2
                    sourceSize.height: view.look.art * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }
        }
    }

    Item {
        id: details
        x: view.detailsLeft
        y: view.look.padding
        width: view.look.width - view.detailsLeft - view.look.padding
        height: view.look.height - view.look.padding * 2
        transform: Upright {
            isMirrored: view.host.isMirrored
            axis: details.width / 2
        }

        Masked {
            id: lines
            width: details.width
            height: details.height
            visible: view.expansion > 0
            mask: Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: Math.max(0, 1 - Appearance.activity.expanded.fade / Math.max(1, lines.width)); color: "white" }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.activity.expanded.lineGap

                ScrambleText {
                    label: "activity media source"
                    target: Activities.mediaSource.toUpperCase()
                    isShown: view.isShown
                    color: Appearance.color.textMuted
                    pixelSize: Appearance.activity.expanded.smallLabel
                }

                ScrambleText {
                    label: "activity media title"
                    target: Activities.title.length > 0 ? Activities.title : "NOTHING PLAYING"
                    isShown: view.isShown
                    color: Appearance.color.text
                    pixelSize: Appearance.activity.expanded.smallBody
                    spacing: 0
                }

                ScrambleText {
                    label: "activity media artist"
                    target: Activities.artist
                    isShown: view.isShown
                    color: Appearance.color.textMuted
                    pixelSize: Appearance.activity.expanded.smallBody
                    isBold: false
                    spacing: 0
                }
            }
        }
    }

    ActivityBuds {
        host: view.host
        pill: view.pill
        x: -view.x
        y: -view.y
        side: -1
        label: "activity media controls"
        isShown: view.isShown
        items: [
            { key: "previous", glyph: "previous" },
            { key: "toggle", glyph: Activities.isPlaying ? "pause" : "play", isSelected: Activities.isPlaying },
            { key: "next", glyph: "next" }
        ]
        onChosen: key => {
            if (key === "toggle")
                Activities.togglePlaying()
            else if (key === "next")
                Activities.next()
            else
                Activities.previous()
        }
    }
}
