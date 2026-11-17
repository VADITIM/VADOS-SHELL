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
    property int samples: 0
    property real ping: 0
    property real jitter: 0
    property bool hasPing: false
    property bool isShown: false
    property int enterDelay: 0
    property real drawn: isPresent ? 1 : 0
    property real flow: samples
    property real scale: peak
    readonly property var look: Appearance.dashboard.traffic
    readonly property bool isPresent: turn.presence > 0.5
    readonly property real graphTop: look.header + look.graphGap
    readonly property real graphHeight: height - graphTop
    readonly property real peak: Math.max(look.floor, ...downloads, ...uploads) * look.headroom
    readonly property real step: width / (Motion.dashboard.trafficSamples - 1)
    readonly property real lag: Math.max(0, Math.min(1, samples - flow))

    function rate(bytes) {
        const bits = bytes * 8
        if (bits >= 1e9)
            return { value: (bits / 1e9).toFixed(1), unit: "Gbps" }
        if (bits >= 1e6)
            return { value: (bits / 1e6).toFixed(1), unit: "Mbps" }
        return { value: String(Math.round(bits / 1e3)), unit: "Kbps" }
    }

    function millisecondsText(value) {
        const shown = throughput.hasPing ? String(Math.min(Math.round(value), look.pingCeiling)) : "--"
        return shown.padStart(String(look.pingCeiling).length, " ")
    }

    function pointX(index, count) {
        return width * (Motion.dashboard.trafficSamples - count + index) / (Motion.dashboard.trafficSamples - 1) + step * lag
    }

    function pointY(value) {
        return graphTop + graphHeight * (1 - value / scale * drawn)
    }

    function linePoints(history) {
        return history.map((value, index) => Qt.point(pointX(index, history.length), pointY(value)))
    }

    function areaPoints(history) {
        if (history.length === 0)
            return []
        const bottom = graphTop + graphHeight
        return linePoints(history).concat([Qt.point(pointX(history.length - 1, history.length), bottom), Qt.point(pointX(0, history.length), bottom)])
    }

    function leading(history) {
        if (history.length < 2)
            return history.length > 0 ? history[0] : 0
        const newest = history[history.length - 1]
        const before = history[history.length - 2]
        return before + (newest - before) * (1 - lag)
    }

    Behavior on flow {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.trafficPoll)
            easing.type: Easing.Linear
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.trafficPoll)
            easing.type: Easing.OutCubic
        }
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
                    { arrow: "↓", bytes: throughput.download, tint: Appearance.color.accent },
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
                        font.pixelSize: Appearance.dashboard.font.label
                    }

                    Roll {
                        id: amount
                        target: parent.shownRate.value.padStart(throughput.look.rateDigits, " ")
                        isShown: throughput.isPresent
                        holdsWidth: true
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.dashboard.font.reading
                        font.bold: true
                    }

                    Text {
                        anchors.baseline: amount.baseline
                        text: parent.shownRate.unit
                        color: Appearance.color.textMuted
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.dashboard.font.label
                    }
                }
            }
        }

        Row {
            x: throughput.width - width
            spacing: throughput.look.valueGap

            Repeater {
                model: [
                    { label: "PING", value: throughput.ping },
                    { label: "JITTER", value: throughput.jitter }
                ]

                Row {
                    required property var modelData
                    required property int index

                    leftPadding: index > 0 ? throughput.look.columnGap - throughput.look.valueGap : 0
                    spacing: throughput.look.valueGap

                    Text {
                        anchors.baseline: delay.baseline
                        text: parent.modelData.label
                        color: Appearance.color.textMuted
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.dashboard.font.label
                        font.letterSpacing: Appearance.font.labelSpacing / 2
                    }

                    Roll {
                        id: delay
                        target: throughput.millisecondsText(parent.modelData.value)
                        isShown: throughput.isPresent
                        holdsWidth: true
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.dashboard.font.reading
                        font.bold: true
                    }

                    Text {
                        anchors.baseline: delay.baseline
                        text: "ms"
                        color: Appearance.color.textMuted
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.dashboard.font.label
                    }
                }
            }
        }

        Text {
            y: throughput.graphTop
            text: throughput.rate(throughput.scale).value
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.dashboard.font.label
            opacity: throughput.drawn
        }

        Item {
            width: throughput.width + throughput.look.dot
            height: throughput.height
            clip: true

            Shape {
                width: throughput.width
                height: throughput.height
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        y1: throughput.graphTop
                        y2: throughput.graphTop + throughput.graphHeight
                        GradientStop { position: 0; color: Qt.alpha(Appearance.color.accent, throughput.look.fillAlpha) }
                        GradientStop { position: 1; color: Qt.alpha(Appearance.color.accent, 0) }
                    }

                    PathPolyline { path: throughput.areaPoints(throughput.downloads) }
                }

                ShapePath {
                    strokeColor: Appearance.color.accent
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
                y: throughput.pointY(throughput.leading(throughput.downloads)) - height / 2
                width: throughput.look.dot
                height: throughput.look.dot
                radius: width / 2
                color: Appearance.color.accent
            }
        }
    }
}
