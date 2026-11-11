import QtQuick
import qs.components
import "../../utils/Geometry.js" as Geometry

Item {
    id: shape

    property real neckStart: 0
    property real neckCenter: 0
    property real neckHeight: 0
    property real reach: 0
    property real grownHeight: 0
    property real edgeX: 0
    property real columnWidth: 0
    property real columnTop: 0
    property real columnHeight: 0
    property real corner: 0
    property real fillet: 0
    readonly property real tipX: neckStart + reach
    readonly property real columnLeft: edgeX - columnWidth
    readonly property real heightShare: columnHeight > 0 ? Geometry.clampUnit(grownHeight / columnHeight) : 0
    readonly property real bodyWidth: Math.max(0, tipX - columnLeft)
    readonly property real bodyHeight: Math.max(Math.min(neckHeight, reach), grownHeight)
    readonly property real bodyCenter: Geometry.mix(neckCenter, columnTop + columnHeight / 2, heightShare)
    readonly property real bodyTop: bodyCenter - bodyHeight / 2
    readonly property real fuse: corner > 0 ? Geometry.clampUnit((tipX - edgeX) / corner) : 0
    readonly property bool isGrown: reach > 0.5

    visible: isGrown

    LiquidShape {
        readonly property real thickness: Math.min(shape.neckHeight, shape.reach)

        x: shape.neckStart
        y: shape.neckCenter - thickness / 2
        width: Math.max(0, Math.min(shape.tipX, shape.columnLeft + shape.corner) - shape.neckStart)
        height: thickness
    }

    Rectangle {
        color: "white"
        antialiasing: true
        x: shape.columnLeft
        y: shape.bodyTop
        width: shape.bodyWidth
        height: shape.bodyHeight
        radius: Math.min(shape.corner, width / 2, height / 2)
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
