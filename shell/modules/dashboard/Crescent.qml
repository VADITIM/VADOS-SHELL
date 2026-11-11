import QtQuick
import QtQuick.Shapes
import qs.config

Item {
    id: crescent

    property real level: 0
    property bool isShown: false
    property color fill: Appearance.color.accent
    property real drawn: isShown ? Math.max(0, Math.min(1, level)) : 0
    readonly property var look: Appearance.dashboard.gauge
    readonly property real reach: width / 2 + look.arcGap

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.level)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on fill {
        ColorAnimation {
            duration: Motion.pace(Motion.stateDuration)
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.alpha(Appearance.color.accent, crescent.look.usageTrack)
            strokeWidth: crescent.look.bar
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: crescent.width / 2
                centerY: crescent.height / 2
                radiusX: crescent.reach
                radiusY: crescent.reach
                startAngle: crescent.look.arcStart
                sweepAngle: crescent.look.arcSweep
            }
        }

        ShapePath {
            strokeColor: crescent.fill
            strokeWidth: crescent.look.bar
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: crescent.width / 2
                centerY: crescent.height / 2
                radiusX: crescent.reach
                radiusY: crescent.reach
                startAngle: crescent.look.arcStart
                sweepAngle: crescent.look.arcSweep * Math.max(0.001, crescent.drawn)
            }
        }
    }
}
