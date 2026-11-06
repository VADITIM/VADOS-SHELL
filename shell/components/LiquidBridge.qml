import QtQuick
import QtQuick.Shapes

Shape {
    id: bridge

    property real fromX: 0
    property real fromY: 0
    property real fromRadius: 0
    property real toX: 0
    property real toY: 0
    property real toRadius: 0
    property real spread: 0
    property real handle: 2.4
    readonly property var outline: shape(fromX, fromY, fromRadius, toX, toY, toRadius, spread, handle)
    readonly property bool isFormed: outline !== null

    function around(x, y, angle, radius) {
        return { x: x + Math.cos(angle) * radius, y: y + Math.sin(angle) * radius }
    }

    function shape(fromX, fromY, fromRadius, toX, toY, toRadius, spreadShare, handleSize) {
        const distance = Math.hypot(toX - fromX, toY - fromY)
        if (spreadShare <= 0.001 || fromRadius <= 0 || toRadius <= 0 || distance <= Math.abs(fromRadius - toRadius) + 0.5)
            return null
        let fromOverlap = 0
        let toOverlap = 0
        if (distance < fromRadius + toRadius) {
            fromOverlap = Math.acos(Math.max(-1, Math.min(1, (fromRadius * fromRadius + distance * distance - toRadius * toRadius) / (2 * fromRadius * distance))))
            toOverlap = Math.acos(Math.max(-1, Math.min(1, (toRadius * toRadius + distance * distance - fromRadius * fromRadius) / (2 * toRadius * distance))))
        }
        const heading = Math.atan2(toY - fromY, toX - fromX)
        const widest = Math.acos(Math.max(-1, Math.min(1, (fromRadius - toRadius) / distance)))
        const fromStartAngle = heading + fromOverlap + (widest - fromOverlap) * spreadShare
        const fromEndAngle = heading - fromOverlap - (widest - fromOverlap) * spreadShare
        const toStartAngle = heading + Math.PI - toOverlap - (Math.PI - toOverlap - widest) * spreadShare
        const toEndAngle = heading - Math.PI + toOverlap + (Math.PI - toOverlap - widest) * spreadShare
        const fromStart = around(fromX, fromY, fromStartAngle, fromRadius)
        const fromEnd = around(fromX, fromY, fromEndAngle, fromRadius)
        const toStart = around(toX, toY, toStartAngle, toRadius)
        const toEnd = around(toX, toY, toEndAngle, toRadius)
        const reach = Math.min(spreadShare * handleSize, Math.hypot(toStart.x - fromStart.x, toStart.y - fromStart.y) / (fromRadius + toRadius))
            * Math.min(1, distance * 2 / (fromRadius + toRadius))
        return {
            fromStart: fromStart, fromEnd: fromEnd, toStart: toStart, toEnd: toEnd,
            fromStartHandle: around(fromStart.x, fromStart.y, fromStartAngle - Math.PI / 2, fromRadius * reach),
            fromEndHandle: around(fromEnd.x, fromEnd.y, fromEndAngle + Math.PI / 2, fromRadius * reach),
            toStartHandle: around(toStart.x, toStart.y, toStartAngle + Math.PI / 2, toRadius * reach),
            toEndHandle: around(toEnd.x, toEnd.y, toEndAngle - Math.PI / 2, toRadius * reach)
        }
    }

    readonly property var none: ({ x: 0, y: 0 })
    readonly property var fromStart: outline ? outline.fromStart : none
    readonly property var fromEnd: outline ? outline.fromEnd : none
    readonly property var toStart: outline ? outline.toStart : none
    readonly property var toEnd: outline ? outline.toEnd : none
    readonly property var fromStartHandle: outline ? outline.fromStartHandle : none
    readonly property var fromEndHandle: outline ? outline.fromEndHandle : none
    readonly property var toStartHandle: outline ? outline.toStartHandle : none
    readonly property var toEndHandle: outline ? outline.toEndHandle : none

    preferredRendererType: Shape.CurveRenderer
    opacity: isFormed ? 1 : 0

    ShapePath {
        fillColor: "white"
        strokeColor: "transparent"
        strokeWidth: 0
        startX: bridge.fromStart.x
        startY: bridge.fromStart.y

        PathCubic {
            x: bridge.toStart.x
            y: bridge.toStart.y
            control1X: bridge.fromStartHandle.x
            control1Y: bridge.fromStartHandle.y
            control2X: bridge.toStartHandle.x
            control2Y: bridge.toStartHandle.y
        }
        PathLine {
            x: bridge.toEnd.x
            y: bridge.toEnd.y
        }
        PathCubic {
            x: bridge.fromEnd.x
            y: bridge.fromEnd.y
            control1X: bridge.toEndHandle.x
            control1Y: bridge.toEndHandle.y
            control2X: bridge.fromEndHandle.x
            control2Y: bridge.fromEndHandle.y
        }
        PathLine {
            x: bridge.fromStart.x
            y: bridge.fromStart.y
        }
    }
}
