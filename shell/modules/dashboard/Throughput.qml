import QtQuick
import QtQuick.Shapes
import qs.config
import qs.components

Item {
    id: throughput

    property real download: 0
    property real upload: 0
    property var downloads: []
    property var uploads: []
    property real ping: 0
    property real jitter: 0
    property bool hasPing: false
    property bool isShown: false
    property int enterDelay: 0
    property real drawn: isPresent ? 1 : 0
    readonly property var look: Appearance.dashboard.traffic
    readonly property bool isPresent: turn.presence > 0.5
    readonly property real graphTop: look.header + look.graphGap
    readonly property real graphHeight: height - graphTop
    readonly property real peak: Math.max(look.floor, ...downloads, ...uploads) * look.headroom

    function rate(bytes) {
        const bits = bytes * 8
        if (bits >= 1e9)
            return { value: (bits / 1e9).toFixed(1), unit: "Gbps" }
        if (bits >= 1e6)
            return { value: (bits / 1e6).toFixed(1), unit: "Mbps" }
        return { value: String(Math.round(bits / 1e3)), unit: "Kbps" }
    }

    function pointX(index, count) {
        return width * (Motion.dashboard.trafficSamples - count + index) / (Motion.dashboard.trafficSamples - 1)
    }

    function pointY(value) {
        return graphTop + graphHeight * (1 - value / peak * drawn)
    }

    function linePoints(history) {
        return history.map((value, index) => Qt.point(pointX(index, history.length), pointY(value)))
    }

    function areaPoints(history) {
        if (history.length === 0)
            return []
        const bottom = graphTop + graphHeight
        return linePoints(history).concat([Qt.point(width, bottom), Qt.point(pointX(0, history.length), bottom)])
    }

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.level)
            easing.type: Easing.OutCubic
        }
    }

    Turn {
        id: turn
        width: throughput.width
        height: throughput.height
        isShown: throughput.isShown
        enterDelay: throughput.enterDelay
        enterDuration: Motion.search.tileEnter

        Row {
            spacing: throughput.look.columnGap

            Repeater {
                model: [
                    { arrow: "↓", bytes: throughput.download, tint: Appearance.color.levelCool },
                    { arrow: "↑", bytes: throughput.upload, tint: Appearance.color.levelWarm }
                ]

                Row {
                    required property var modelData
                    readonly property var shownRate: throughput.rate(modelData.bytes)

                    spacing: throughput.look.valueGap

                    Text {
                        anchors.baseline: amount.baseline
                        text: parent.modelData.arrow
                        color: parent.modelData.tint
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                    }

                    TypedText {
                        id: amount
                        target: parent.shownRate.value
                        isShown: throughput.isPresent
                        holdsWidth: true
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.reading
                        font.bold: true
                    }

                    Text {
                        anchors.baseline: amount.baseline
                        text: parent.shownRate.unit
                        color: Appearance.color.textMuted
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                    }
                }
            }
        }

        TypedText {
            x: throughput.width - fullWidth
            y: (throughput.look.header - height) / 2
            target: throughput.hasPing ? "PING " + Math.round(throughput.ping) + "ms  JITTER " + Math.round(throughput.jitter) + "ms" : "PING --ms  JITTER --ms"
            isShown: throughput.isPresent
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing / 2
        }

        Text {
            y: throughput.graphTop
            text: throughput.rate(throughput.peak).value
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            opacity: throughput.drawn
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    y1: throughput.graphTop
                    y2: throughput.graphTop + throughput.graphHeight
                    GradientStop { position: 0; color: Qt.alpha(Appearance.color.levelCool, throughput.look.fillAlpha) }
                    GradientStop { position: 1; color: Qt.alpha(Appearance.color.levelCool, 0) }
                }

                PathPolyline { path: throughput.areaPoints(throughput.downloads) }
            }

            ShapePath {
                strokeColor: Appearance.color.levelCool
                strokeWidth: throughput.look.line
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.RoundCap

                PathPolyline { path: throughput.linePoints(throughput.downloads) }
            }

            ShapePath {
                strokeColor: Appearance.color.levelWarm
                strokeWidth: throughput.look.line
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.RoundCap

                PathPolyline { path: throughput.linePoints(throughput.uploads) }
            }
        }

        Rectangle {
            visible: throughput.downloads.length > 0
            x: throughput.width - width / 2
            y: throughput.pointY(throughput.download) - height / 2
            width: throughput.look.dot
            height: throughput.look.dot
            radius: width / 2
            color: Appearance.color.levelCool
        }
    }
}
