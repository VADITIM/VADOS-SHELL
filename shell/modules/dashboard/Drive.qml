import QtQuick
import qs.config
import qs.components

Item {
    id: drive

    property string label: ""
    property real used: 0
    property real total: 0
    property int pageCount: 1
    property int page: 0
    property bool isShown: false
    property int enterDelay: 0
    readonly property var look: Appearance.dashboard.drive
    readonly property bool isPresent: turn.presence > 0.5
    readonly property real share: total > 0 ? used / total : 0
    readonly property color usageColor: Appearance.bandColor(share, Appearance.dashboard.usageBands)

    signal paged()

    width: look.width
    height: look.glyph + look.rowGap + look.barHeight

    function gigabytes(bytes) {
        return String(Math.round(bytes / 1073741824))
    }

    Turn {
        id: turn
        width: drive.width
        height: drive.height
        isShown: drive.isShown
        enterDelay: drive.enterDelay
        enterDuration: Motion.search.tileEnter

        Glyph {
            width: drive.look.glyph
            height: drive.look.glyph
            name: "disk"
            stroke: Appearance.dashboard.iconStroke * 24 / width
            color: Appearance.color.text

            TapHandler {
                enabled: drive.pageCount > 1
                onTapped: drive.paged()
            }
        }

        TypedText {
            id: labelText
            x: drive.look.glyph + drive.look.glyphGap
            y: (drive.look.glyph - height) / 2
            target: drive.label.toUpperCase()
            isShown: drive.isPresent
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }

        Row {
            x: labelText.x + labelText.width + drive.look.glyphGap
            y: (drive.look.glyph - height) / 2
            spacing: drive.look.dotGap
            visible: drive.pageCount > 1

            Repeater {
                model: drive.pageCount

                Rectangle {
                    required property int index
                    width: drive.look.dot
                    height: drive.look.dot
                    radius: width / 2
                    color: index === drive.page ? Appearance.color.text : Appearance.color.textFaint

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                        }
                    }
                }
            }
        }

        TypedText {
            x: drive.width - fullWidth
            y: (drive.look.glyph - height) / 2
            target: drive.total > 0 ? drive.gigabytes(drive.used) + "GB/" + drive.gigabytes(drive.total) + "GB" : "--GB/--GB"
            isShown: drive.isPresent
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: drive.usageColor
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.reading
        }

        LevelBar {
            x: drive.width
            y: drive.look.glyph + drive.look.rowGap
            transformOrigin: Item.TopLeft
            rotation: 90
            width: drive.look.barHeight
            height: drive.width
            isShown: drive.isPresent
            level: drive.share
            fill: drive.usageColor
        }
    }
}
