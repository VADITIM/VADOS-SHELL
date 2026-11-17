import QtQuick
import QtQuick.Shapes
import qs.config
import qs.components

Item {
    id: dial

    property real value: 0
    property color tint: Appearance.color.accent
    property string glyph: ""
    property real level: 1
    property bool isCharging: false
    property bool isShown: false
    property real drawn: isShown ? Math.max(0, Math.min(1, value)) : 0
    readonly property var look: Appearance.widgets
    readonly property real radius: (Math.min(width, height) - look.dialStroke) / 2

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.widgets.level)
            easing.type: Easing.OutCubic
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.alpha(dial.tint, dial.look.trackAlpha)
            strokeWidth: dial.look.dialStroke
            fillColor: "transparent"

            PathAngleArc {
                centerX: dial.width / 2
                centerY: dial.height / 2
                radiusX: dial.radius
                radiusY: dial.radius
                startAngle: dial.look.dialStart
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: dial.tint
            strokeWidth: dial.look.dialStroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: dial.width / 2
                centerY: dial.height / 2
                radiusX: dial.radius
                radiusY: dial.radius
                startAngle: dial.look.dialStart
                sweepAngle: 360 * dial.drawn
            }
        }
    }

    Turn {
        anchors.centerIn: parent
        width: dial.look.glyph
        height: dial.look.glyph
        isShown: dial.isShown
        enterEasing: Easing.OutBack
        spinAngle: Motion.widgets.glyphSpin

        Glyph {
            width: dial.look.glyph
            height: dial.look.glyph
            name: dial.glyph
            level: dial.level
            isCharging: dial.isCharging
            color: Appearance.color.text
        }
    }
}
