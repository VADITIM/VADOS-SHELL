import QtQuick
import QtQuick.Shapes

Shape {
    id: lobe

    property int side: 1
    property real edge: 0
    property real tip: 0
    property real centerY: 0
    property real outerHalf: 0
    property real innerHalf: 0
    property real capShare: 0.9
    readonly property real pull: 0.45
    readonly property real cap: innerHalf * capShare
    readonly property real neck: tip - side * cap
    readonly property real span: neck - edge

    function bendAt(time, sign) {
        const rest = 1 - time
        const first = rest * rest * rest
        const second = 3 * rest * rest * time
        const third = 3 * rest * time * time
        const fourth = time * time * time
        const x = first * edge + second * (edge + span * pull) + third * (edge + span * (1 - pull)) + fourth * neck
        const half = (first + second) * outerHalf + (third + fourth) * innerHalf
        return Qt.point(x, centerY + sign * half)
    }

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "white"
        strokeColor: "transparent"
        strokeWidth: 0
        startX: lobe.edge
        startY: lobe.centerY - lobe.outerHalf

        PathCubic {
            x: lobe.neck
            y: lobe.centerY - lobe.innerHalf
            control1X: lobe.edge + lobe.span * lobe.pull
            control1Y: lobe.centerY - lobe.outerHalf
            control2X: lobe.edge + lobe.span * (1 - lobe.pull)
            control2Y: lobe.centerY - lobe.innerHalf
        }
        PathArc {
            x: lobe.neck
            y: lobe.centerY + lobe.innerHalf
            radiusX: lobe.cap
            radiusY: lobe.innerHalf
            direction: lobe.side > 0 ? PathArc.Clockwise : PathArc.Counterclockwise
        }
        PathCubic {
            x: lobe.edge
            y: lobe.centerY + lobe.outerHalf
            control1X: lobe.edge + lobe.span * (1 - lobe.pull)
            control1Y: lobe.centerY + lobe.innerHalf
            control2X: lobe.edge + lobe.span * lobe.pull
            control2Y: lobe.centerY + lobe.outerHalf
        }
        PathLine {
            x: lobe.edge
            y: lobe.centerY - lobe.outerHalf
        }
    }
}
