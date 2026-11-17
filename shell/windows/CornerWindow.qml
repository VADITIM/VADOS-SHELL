import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: window

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "vados-corners"
    color: "transparent"
    mask: passThrough

    Region {
        id: passThrough
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Appearance.color.cornerFill
            strokeWidth: -1
            startX: 0
            startY: 0
            PathLine { x: Appearance.screenCorner.radius; y: 0 }
            PathArc { x: 0; y: Appearance.screenCorner.radius; radiusX: Appearance.screenCorner.radius; radiusY: Appearance.screenCorner.radius; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: 0 }
        }

        ShapePath {
            fillColor: Appearance.color.cornerFill
            strokeWidth: -1
            startX: window.width
            startY: 0
            PathLine { x: window.width; y: Appearance.screenCorner.radius }
            PathArc { x: window.width - Appearance.screenCorner.radius; y: 0; radiusX: Appearance.screenCorner.radius; radiusY: Appearance.screenCorner.radius; direction: PathArc.Counterclockwise }
            PathLine { x: window.width; y: 0 }
        }

        ShapePath {
            fillColor: Appearance.color.cornerFill
            strokeWidth: -1
            startX: 0
            startY: window.height
            PathLine { x: 0; y: window.height - Appearance.screenCorner.radius }
            PathArc { x: Appearance.screenCorner.radius; y: window.height; radiusX: Appearance.screenCorner.radius; radiusY: Appearance.screenCorner.radius; direction: PathArc.Counterclockwise }
            PathLine { x: 0; y: window.height }
        }

        ShapePath {
            fillColor: Appearance.color.cornerFill
            strokeWidth: -1
            startX: window.width
            startY: window.height
            PathLine { x: window.width - Appearance.screenCorner.radius; y: window.height }
            PathArc { x: window.width; y: window.height - Appearance.screenCorner.radius; radiusX: Appearance.screenCorner.radius; radiusY: Appearance.screenCorner.radius; direction: PathArc.Counterclockwise }
            PathLine { x: window.width; y: window.height }
        }
    }
}
