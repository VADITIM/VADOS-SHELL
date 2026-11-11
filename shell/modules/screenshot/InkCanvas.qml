import QtQuick
import qs.config
import "../../utils/Ink.js" as Ink

Item {
    id: ink

    property var strokes: []
    property var drawing: null
    property int hiddenIndex: -1

    Canvas {
        id: canvas
        anchors.fill: parent

        function trace(context, stroke) {
            context.strokeStyle = stroke.color
            context.lineWidth = stroke.width
            context.lineCap = "round"
            context.lineJoin = "round"
            for (const line of Ink.linesOf(stroke)) {
                if (line.length === 0)
                    continue
                context.beginPath()
                context.moveTo(line[0].x, line[0].y)
                for (let at = 1; at < line.length; at++)
                    context.lineTo(line[at].x, line[at].y)
                if (line.length === 1)
                    context.lineTo(line[0].x + 0.01, line[0].y)
                context.stroke()
            }
        }

        onPaint: {
            const context = getContext("2d")
            context.reset()
            for (const stroke of ink.strokes)
                trace(context, stroke)
            if (ink.drawing)
                trace(context, ink.drawing)
        }
    }

    onStrokesChanged: canvas.requestPaint()
    onDrawingChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Repeater {
        model: ink.strokes

        InkText {
            required property var modelData
            required property int index
            stroke: modelData
            visible: Ink.isText(modelData) && index !== ink.hiddenIndex
        }
    }
}
