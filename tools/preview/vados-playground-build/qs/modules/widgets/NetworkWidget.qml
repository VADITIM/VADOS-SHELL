import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    property real download: 0
    property real upload: 0
    property var downloads: []
    property var uploads: []
    property real range: peak
    property real drawn: isShown ? 1 : 0
    readonly property var look: Appearance.widgets
    readonly property real peak: Math.max(look.graphFloor, ...downloads, ...uploads) * look.graphHeadroom
    readonly property real graphTop: header.height + look.captionGap
    readonly property real graphHeight: height - graphTop
    readonly property real step: width / (Motion.widgets.samples - 1)

    function rate(bytes) {
        const bits = bytes * 8
        if (bits >= 1e9)
            return { value: (bits / 1e9).toFixed(1), unit: "GBPS" }
        if (bits >= 1e6)
            return { value: (bits / 1e6).toFixed(1), unit: "MBPS" }
        return { value: String(Math.round(bits / 1e3)), unit: "KBPS" }
    }

    function pointX(index, count) {
        return step * (Motion.widgets.samples - count + index)
    }

    function pointY(value) {
        return graphTop + graphHeight * (1 - value / Math.max(1, range) * drawn)
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

    Binding on download {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: Traffic.download
    }

    Binding on upload {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: Traffic.upload
    }

    Binding on downloads {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: Traffic.downloads
    }

    Binding on uploads {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: Traffic.uploads
    }

    Behavior on range {
        NumberAnimation {
            duration: Motion.pace(Motion.widgets.sample)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.widgets.level)
            easing.type: Easing.OutCubic
        }
    }

    Row {
        id: header
        width: face.width

        Repeater {
            model: 2

            Row {
                id: entry

                required property int index
                readonly property bool isDown: index === 0
                readonly property var shownRate: face.rate(isDown ? face.download : face.upload)

                width: face.width / 2
                spacing: Appearance.unit.base

                Text {
                    anchors.baseline: amount.baseline
                    text: entry.isDown ? "↓" : "↑"
                    color: entry.isDown ? Appearance.color.accent : Appearance.color.levelWarm
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.reading
                    font.bold: true
                }

                Roll {
                    id: amount
                    target: entry.shownRate.value
                    isShown: face.isShown
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.reading
                    font.bold: true
                }

                Text {
                    anchors.baseline: amount.baseline
                    text: entry.shownRate.unit
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.chip
                    font.letterSpacing: Appearance.font.labelSpacing
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                fillColor: Qt.alpha(Appearance.color.accent, face.look.graphFill)

                PathPolyline {
                    path: face.areaPoints(face.downloads)
                }
            }

            ShapePath {
                strokeColor: Appearance.color.accent
                strokeWidth: face.look.graphStroke
                fillColor: "transparent"

                PathPolyline {
                    path: face.linePoints(face.downloads)
                }
            }

            ShapePath {
                strokeColor: Appearance.color.levelWarm
                strokeWidth: face.look.graphStroke
                fillColor: "transparent"

                PathPolyline {
                    path: face.linePoints(face.uploads)
                }
            }
        }
    }
}
