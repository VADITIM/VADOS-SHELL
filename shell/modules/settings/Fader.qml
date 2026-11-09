import QtQuick
import qs.config
import qs.components
import "../../utils/Geometry.js" as Geometry

Column {
    id: fader

    property string label
    property real value: 0
    property real trackWidth: 220

    signal moved(real value)

    spacing: Appearance.unit.small

    Piece {
        Text {
            text: fader.label + "  " + Math.round(fader.value * 100) + "%"
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Piece {
        Item {
            width: fader.trackWidth
            height: Appearance.settings.slider + Appearance.settings.knob

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Appearance.settings.slider
                radius: height / 2
                color: Appearance.color.wash
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.settings.knob
                height: Appearance.settings.knob
                radius: height / 2
                color: Appearance.color.accent
                x: fader.value * (parent.width - width)
            }

            Gesture {
                anchors.fill: parent
                isVertical: false
                onMoved: travelX => fader.moved(Geometry.clampUnit((pressPoint.x + travelX) / width))
                onTapped: mouse => fader.moved(Geometry.clampUnit(mouse.x / width))
            }
        }
    }
}
