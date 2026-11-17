import QtQuick
import qs.config
import "../../utils/Geometry.js" as Geometry

Piece {
    id: lattice

    property int columnLines: 0
    property int rowLines: 0
    property real firstX: 0
    property real firstY: 0
    property real stepX: 0
    property real stepY: 0
    property real columnStart: 0
    property real rowStart: 0
    property real columnLength: height
    property real rowLength: width
    property real stroke: 1
    property color ink: Appearance.color.text

    function drawn(index, count) {
        return Geometry.clampUnit(presence * (1 + Motion.settings.latticeSpread) - index / Math.max(1, count) * Motion.settings.latticeSpread)
    }

    isFlipping: false
    enterDuration: Motion.settings.lattice
    enterEasing: Easing.OutCubic

    Repeater {
        model: lattice.columnLines

        Rectangle {
            required property int index
            x: lattice.firstX + index * lattice.stepX
            y: lattice.columnStart
            width: lattice.stroke
            height: lattice.columnLength * lattice.drawn(index, lattice.columnLines)
            color: lattice.ink
        }
    }

    Repeater {
        model: lattice.rowLines

        Rectangle {
            required property int index
            x: lattice.rowStart
            y: lattice.firstY + index * lattice.stepY
            width: lattice.rowLength * lattice.drawn(index, lattice.rowLines)
            height: lattice.stroke
            color: lattice.ink
        }
    }
}
