import QtQuick
import qs.components
import "../../utils/Geometry.js" as Geometry

Item {
    id: shape

    property real shotStart: 0
    property real shotY: 0
    property real shotFrom: 0
    property real shotSize: 0
    property real shotStretch: 0
    property real shotSink: 0
    property real shotSquash: 0
    property real travel: 0
    property real edgeX: 0
    property real corner: 0
    property real fillet: 0
    readonly property real landX: edgeX + shotSink - shotSize / 2
    readonly property real flight: Geometry.clampUnit(travel)
    readonly property real stretch: shotStretch * Math.sin(Math.PI * flight)
    readonly property real pillSize: Geometry.mix(shotFrom, shotSize, flight)
    readonly property real pillCenter: Geometry.mix(shotStart, landX, travel)
    readonly property real wallStop: edgeX + shotSink
    readonly property real pillReach: pillSize * (1 + stretch) / 2
    readonly property real press: Math.max(0, pillCenter + pillReach - wallStop)
    readonly property real pillRight: Math.min(pillCenter + pillReach, wallStop)
    readonly property real pillLeft: Math.min(pillCenter - pillReach, pillRight - pillSize * (1 - shotSquash))
    readonly property real pillHeight: pillSize / (1 + stretch / 2) + press
    readonly property real bodyWidth: Math.max(0, pillRight - pillLeft)
    readonly property real bodyTop: shotY - pillHeight / 2
    readonly property real fuse: shotSink > 0 ? Geometry.clampUnit((pillRight - edgeX) / shotSink) : 0
    readonly property bool isGrown: travel > 0.01

    visible: isGrown

    Rectangle {
        color: "white"
        antialiasing: true
        x: shape.pillLeft
        y: shape.bodyTop
        width: shape.bodyWidth
        height: shape.pillHeight
        radius: Math.min(shape.corner, width / 2, height / 2)
    }

    Item {
        x: shape.edgeX
        transform: Scale { xScale: -1 }

        EdgeFuse {
            reach: shape.corner
            bodyTop: shape.bodyTop
            length: shape.pillHeight
            fillet: shape.fillet
            share: shape.fuse
        }
    }
}
