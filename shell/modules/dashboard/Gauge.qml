import QtQuick
import qs.config
import qs.components

Item {
    id: gauge

    property string name: ""
    property string chipName: "cpu"
    property real ringShare: 0
    property color ringColor: Appearance.color.levelCool
    property color glyphColor: Appearance.color.text
    property string centerText: ""
    property string caption: ""
    property color captionColor: Appearance.color.text
    property bool hasBar: false
    property real barUsed: 0
    property real barTotal: 0
    property bool isShown: false
    property int enterDelay: 0
    readonly property var look: Appearance.dashboard.gauge
    readonly property var bands: Appearance.dashboard
    readonly property bool isPresent: turn.presence > 0.5
    readonly property real ringX: look.bar + look.barGap
    readonly property real barShare: barTotal > 0 ? barUsed / barTotal : 0

    width: look.blockWidth
    height: look.blockHeight

    function gigabytes(bytes) {
        return barTotal > 0 ? String(Math.round(bytes / 1073741824)) : "--"
    }

    Turn {
        id: turn
        width: gauge.width
        height: gauge.height
        isShown: gauge.isShown
        enterDelay: gauge.enterDelay
        enterDuration: Motion.search.tileEnter

        Crescent {
            visible: gauge.hasBar
            x: gauge.ringX
            width: gauge.look.ring
            height: gauge.look.ring
            isShown: gauge.isPresent
            level: gauge.barShare
            fill: Appearance.bandColor(gauge.barShare, gauge.bands.usageBands)
        }

        Column {
            visible: gauge.hasBar
            x: gauge.ringX - gauge.look.arcGap - width / 2
            y: gauge.look.ring / 2 + gauge.look.labelGap
            spacing: gauge.look.fractionGap

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.gigabytes(gauge.barUsed)
                color: Appearance.bandColor(gauge.barShare, gauge.bands.usageBands)
                font.family: Appearance.font.mono
                font.pixelSize: gauge.look.fraction
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Appearance.color.textMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.gigabytes(gauge.barTotal)
                color: Appearance.color.levelCool
                font.family: Appearance.font.mono
                font.pixelSize: gauge.look.fraction
            }
        }

        Ring {
            x: gauge.ringX
            width: gauge.look.ring
            height: gauge.look.ring
            value: gauge.ringShare
            isShown: gauge.isPresent
            color: gauge.ringColor

            Glyph {
                anchors.centerIn: parent
                width: gauge.look.chip
                height: gauge.look.chip
                name: gauge.chipName
                stroke: gauge.bands.iconStroke * 24 / width
                color: gauge.glyphColor

                Behavior on color {
                    ColorAnimation { duration: Motion.stateDuration }
                }
            }

            TypedText {
                x: (parent.width - fullWidth) / 2
                y: (parent.height - height) / 2
                target: gauge.centerText
                isShown: gauge.isPresent
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                color: gauge.glyphColor
                font.family: Appearance.font.mono
                font.pixelSize: gauge.look.loadText
                font.bold: true
            }

            ArcText {
                x: parent.width / 2
                y: parent.height / 2
                radius: gauge.look.ring / 2 - gauge.look.textInset
                maxSweep: gauge.look.textSweep
                target: gauge.name.toUpperCase()
                isShown: gauge.isPresent
                color: Appearance.color.text
                pixelSize: Appearance.font.label
                letterSpacing: Appearance.font.labelSpacing
            }

            ArcText {
                x: parent.width / 2
                y: parent.height / 2
                isBottom: true
                radius: gauge.look.ring / 2 - gauge.look.textInset
                maxSweep: gauge.look.textSweep
                target: gauge.caption
                isShown: gauge.isPresent
                color: gauge.captionColor
                pixelSize: Appearance.font.reading
            }
        }
    }
}
