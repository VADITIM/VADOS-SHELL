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
    property real grownWidth: 0
    property real grownHeight: 0
    property real edgeX: 0
    property real columnWidth: 0
    property real columnTop: 0
    property real columnHeight: 0
    property real corner: 0
    property real fillet: 0
    property real wave: 0
    property real waveRun: 0
    property int crests: 4
    readonly property real columnLeft: edgeX - columnWidth
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
    readonly property real widthShare: columnWidth > 0 ? Math.max(0, grownWidth / columnWidth) : 0
    readonly property real heightShare: columnHeight > 0 ? Math.max(0, grownHeight / columnHeight) : 0
    readonly property real bodyLeft: Geometry.mix(pillLeft, columnLeft, widthShare)
    readonly property real bodyRight: Geometry.mix(pillRight, edgeX + corner, Geometry.clampUnit(widthShare))
    readonly property real bodyWidth: Math.max(0, bodyRight - bodyLeft)
    readonly property real bodyHeight: Math.max(0, Geometry.mix(pillHeight, columnHeight, heightShare))
    readonly property real bodyCenter: Geometry.mix(shotY, columnTop + columnHeight / 2, Geometry.clampUnit(heightShare))
    readonly property real bodyTop: bodyCenter - bodyHeight / 2
    readonly property real front: Geometry.clampUnit(heightShare)
    readonly property real swell: Math.max(0, Math.sin(Math.PI * front))
    readonly property real crestReach: Math.max(0, bodyHeight / 2 - Math.min(corner, bodyWidth / 2))
    readonly property real fuse: shotSink > 0 ? Geometry.clampUnit((bodyRight - edgeX) / shotSink) : 0
    readonly property bool isGrown: travel > 0.01

    visible: isGrown

    function crestAt(step) {
        const place = step / (crests + 1)
        const distance = Math.abs(front - place) / waveRun
        return wave * swell * Math.max(0, 1 - distance)
    }

    Rectangle {
        color: "white"
        antialiasing: true
        x: shape.bodyLeft
        y: shape.bodyTop
        width: shape.bodyWidth
        height: shape.bodyHeight
        radius: Math.min(shape.corner, width / 2, height / 2)
    }

    Repeater {
        model: shape.crests * 2

        LiquidShape {
            required property int index
            readonly property int step: Math.floor(index / 2) + 1
            readonly property int side: index % 2 === 0 ? -1 : 1
            readonly property real size: shape.crestAt(step)

            visible: size > 0.5
            x: shape.bodyLeft - size / 2
            y: shape.bodyCenter + side * shape.crestReach * step / (shape.crests + 1) - size
            width: size * 2
            height: size * 2
        }
    }

    Item {
        x: shape.edgeX
        transform: Scale { xScale: -1 }

        EdgeFuse {
            reach: shape.corner
            bodyTop: shape.bodyTop
            length: shape.bodyHeight
            fillet: shape.fillet
            share: shape.fuse
        }
    }
}
