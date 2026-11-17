import QtQuick
import qs.config
import qs.components

Item {
    id: gauge

    property string name: ""
    property string chipName: "cpu"
    property real ringShare: 0
    property color ringColor: Appearance.color.accent
    property color glyphColor: Appearance.color.text
    property string chipLabel: ""
    property bool hasUsage: false
    property real usageShare: 0
    property color usageColor: Appearance.color.accent
    property string readout: ""
    property string caption: ""
    property real nameTilt: 0
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
    readonly property bool isHovered: hover.hovered && isPresent
    property real spin: isHovered ? look.spin : 0

    Behavior on spin {
        NumberAnimation {
            duration: Motion.pace(gauge.isHovered ? Motion.dashboard.gaugeSpin : Motion.dashboard.gaugeSpinBack)
            easing.type: gauge.isHovered ? Easing.OutBack : Easing.OutCubic
        }
    }

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
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Appearance.color.textMuted
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.gigabytes(gauge.barTotal)
                color: Appearance.color.accent
                font.family: Appearance.font.mono
                font.pixelSize: gauge.look.fraction
                font.bold: true
            }
        }

        Item {
            id: ringBox
            x: gauge.ringX
            width: gauge.look.ring
            height: gauge.look.ring

            HoverHandler {
                id: hover
                enabled: gauge.isPresent
            }

            Ring {
                anchors.fill: parent
                value: gauge.ringShare
                isShown: gauge.isPresent
                color: gauge.ringColor
                hasOuter: gauge.hasUsage
                outerValue: gauge.usageShare
                outerColor: gauge.usageColor
            }

            Item {
                id: chip
                anchors.centerIn: parent
                width: gauge.look.chip
                height: gauge.look.chip
                rotation: gauge.spin

                Glyph {
                    anchors.fill: parent
                    name: gauge.chipName
                    stroke: gauge.look.chipStroke * 24 / width
                    color: gauge.glyphColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                        }
                    }
                }

                TypedText {
                    x: (parent.width - fullWidth) / 2
                    y: (parent.height - height) / 2 + gauge.look.chipTextShift
                    target: gauge.chipLabel
                    isShown: gauge.isPresent
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    color: gauge.glyphColor
                    font.family: Appearance.font.mono
                    font.pixelSize: gauge.look.chipText
                    font.bold: true
                }
            }

            ArcText {
                x: parent.width / 2
                y: parent.height / 2
                rotation: gauge.nameTilt
                radius: gauge.look.ring / 2 + gauge.look.nameLift
                maxSweep: gauge.look.nameSweep
                target: gauge.name.toUpperCase()
                isShown: gauge.isHovered
                color: Appearance.color.text
                pixelSize: gauge.look.name
                letterSpacing: Appearance.font.labelSpacing
            }
        }
    }
}
