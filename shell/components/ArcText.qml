import QtQuick
import qs.config

Item {
    id: arc

    property string target: ""
    property bool isShown: true
    property bool isBottom: false
    property real radius: 90
    property real maxSweep: 120
    property color color: Appearance.color.text
    property string fontFamily: Appearance.font.mono
    property int pixelSize: Appearance.font.label
    property real letterSpacing: 0
    property int characterInterval: Motion.type.quick
    property int untypeInterval: Motion.type.quickUntype
    readonly property real advance: measure.implicitWidth + letterSpacing
    readonly property real stepAngle: advance / radius * 180 / Math.PI
    readonly property int capacity: Math.max(1, Math.floor(maxSweep / stepAngle))
    readonly property string display: target.length > capacity ? target.slice(0, capacity - 1) + "…" : target

    width: 0
    height: 0

    Text {
        id: measure
        visible: false
        text: "M"
        font.family: arc.fontFamily
        font.pixelSize: arc.pixelSize
    }

    TypedText {
        id: typer
        visible: false
        target: arc.display
        isShown: arc.isShown
        characterInterval: arc.characterInterval
        untypeInterval: arc.untypeInterval
        font.family: arc.fontFamily
        font.pixelSize: arc.pixelSize
    }

    Repeater {
        model: arc.display.length

        Item {
            required property int index
            readonly property real offset: index - (arc.display.length - 1) / 2

            rotation: (arc.isBottom ? -offset : offset) * arc.stepAngle
            visible: index < typer.shown.length

            Text {
                x: -width / 2
                y: arc.isBottom ? arc.radius - height : -arc.radius
                text: arc.display.charAt(parent.index)
                textFormat: Text.PlainText
                color: arc.color
                font.family: arc.fontFamily
                font.pixelSize: arc.pixelSize
            }
        }
    }
}
