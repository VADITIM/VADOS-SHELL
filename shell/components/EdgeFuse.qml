import QtQuick
import QtQuick.Shapes

Item {
    id: fuse

    property real reach: 0
    property real bodyTop: 0
    property real length: 0
    property real fillet: 12
    property real share: 0
    readonly property real flare: length > 0.5 ? Math.min(fillet, length) * share : 0
    readonly property real bodyBottom: bodyTop + length

    x: 0
    y: 0
    width: 0
    height: 0

    Rectangle {
        color: "white"
        x: -4
        y: fuse.bodyTop
        width: Math.max(0, fuse.reach + 4) * fuse.share
        height: fuse.length
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            strokeWidth: 0
            startX: -4
            startY: fuse.bodyTop - fuse.flare

            PathLine { x: 0; y: fuse.bodyTop - fuse.flare }
            PathArc {
                x: fuse.flare
                y: fuse.bodyTop
                radiusX: fuse.flare
                radiusY: fuse.flare
                direction: PathArc.Counterclockwise
            }
            PathLine { x: -4; y: fuse.bodyTop }
        }

        ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            strokeWidth: 0
            startX: -4
            startY: fuse.bodyBottom + fuse.flare

            PathLine { x: 0; y: fuse.bodyBottom + fuse.flare }
            PathArc {
                x: fuse.flare
                y: fuse.bodyBottom
                radiusX: fuse.flare
                radiusY: fuse.flare
                direction: PathArc.Clockwise
            }
            PathLine { x: -4; y: fuse.bodyBottom }
        }
    }
}
