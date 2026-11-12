import QtQuick
import QtQuick.Shapes
import qs.config
import "../utils/Geometry.js" as Geometry

Shape {
    id: squircle

    property color color: "transparent"
    property color shade: color
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    readonly property var outline: {
        const points = Geometry.superellipse(width - strokeWidth, height - strokeWidth, Appearance.radius.squircle, Appearance.radius.squircleSteps)
        points.push(points[0])
        return points
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: squircle.width
            y2: squircle.height

            GradientStop {
                position: 0
                color: squircle.color
            }

            GradientStop {
                position: 1
                color: squircle.shade
            }
        }
        strokeColor: squircle.strokeWidth > 0 ? squircle.strokeColor : "transparent"
        strokeWidth: squircle.strokeWidth > 0 ? squircle.strokeWidth : -1
        startX: squircle.outline[0].x + squircle.strokeWidth / 2
        startY: squircle.outline[0].y + squircle.strokeWidth / 2

        PathPolyline {
            path: squircle.outline.map(point => Qt.point(point.x + squircle.strokeWidth / 2, point.y + squircle.strokeWidth / 2))
        }
    }
}
