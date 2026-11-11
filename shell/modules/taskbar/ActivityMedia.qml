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
    readonly property real detailsLeft: look.height / 2 + look.ring / 2 + Appearance.activity.detailGap

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
                    width: Appearance.activity.glyph * 1.6
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

        TypedText {
            id: sourceLabel
            width: Math.min(implicitWidth, details.width)
            elide: Text.ElideRight
            target: Activities.mediaSource.toUpperCase()
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true
        }

        TypedText {
            id: title
            y: sourceLabel.height + Appearance.activity.lineGap
            width: Math.min(implicitWidth, details.width)
            elide: Text.ElideRight
            target: Activities.title.length > 0 ? Activities.title : "NOTHING PLAYING"
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.body
            font.bold: true
        }

        TypedText {
            y: title.y + title.height + Appearance.activity.lineGap
            width: Math.min(implicitWidth, details.width)
            elide: Text.ElideRight
            target: Activities.artist
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.body
        }

        Row {
            y: details.height - Appearance.activity.control
            spacing: Appearance.activity.controlGap

            Repeater {
                model: ["previous", "toggle", "next"]

                Turn {
                    id: control
                    required property string modelData
                    required property int index
                    width: Appearance.activity.control
                    height: Appearance.activity.control
                    isShown: view.isShown
                    enterDelay: (index + 1) * Motion.activity.stagger
                    enterDuration: Motion.activity.faceEnter
                    leaveDuration: Motion.activity.faceLeave
                    leaveWindow: 0

                    GlyphButton {
                        anchors.fill: parent
                        glyphName: control.modelData === "toggle" ? (Activities.isPlaying ? "pause" : "play") : control.modelData
                        isSelected: control.modelData === "toggle" && Activities.isPlaying
                        onClicked: {
                            if (control.modelData === "toggle")
                                Activities.togglePlaying()
                            else if (control.modelData === "next")
                                Activities.next()
                            else
                                Activities.previous()
                        }
                    }
                }
            }
        }
    }
}
