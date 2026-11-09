import QtQuick
import QtQuick.Shapes
import qs.config
import "../utils/Geometry.js" as Geometry
import "../utils/Playing.js" as Playing

Item {
    id: outline

    property bool isShown: false
    property string label: "outline"
    property real radius: 0
    property real lineWidth: 1
    property color lineColor: Appearance.color.hairline
    property int traceDuration: Motion.stateDuration
    property int leaveDuration: Motion.hoverOut
    property real step: 6
    property real trace: 0
    property real fade: 0
    property int traceSpan: traceDuration
    readonly property string playing: tracing.running ? label + " enter" : leaving.running ? label + " leave" : ""
    readonly property real inset: lineWidth / 2
    readonly property var clockwise: Geometry.halfOutline(width - lineWidth, height - lineWidth, radius - inset, true, step)
    readonly property var counter: Geometry.halfOutline(width - lineWidth, height - lineWidth, radius - inset, false, step)

    function play() {
        if (isShown) {
            leaving.stop()
            if (trace >= 1 && fade >= 1)
                return
            traceSpan = traceDuration * (1 - trace)
            tracing.restart()
            return
        }
        tracing.stop()
        if (fade <= 0) {
            trace = 0
            return
        }
        leaving.restart()
    }

    onIsShownChanged: play()
    Component.onCompleted: {
        Playing.enlist(outline)
        if (isShown)
            play()
    }
    Component.onDestruction: Playing.delist(outline)

    Shape {
        x: outline.inset
        y: outline.inset
        opacity: outline.fade
        visible: outline.trace > 0 && outline.fade > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: outline.lineWidth
            strokeColor: outline.lineColor
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap

            PathPolyline {
                path: Geometry.cutAlong(outline.clockwise, outline.trace)
            }
        }

        ShapePath {
            strokeWidth: outline.lineWidth
            strokeColor: outline.lineColor
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap

            PathPolyline {
                path: Geometry.cutAlong(outline.counter, outline.trace)
            }
        }
    }

    ParallelAnimation {
        id: tracing
        paused: Motion.isHeld && running
        NumberAnimation {
            target: outline
            property: "trace"
            to: 1
            duration: Motion.pace(outline.traceSpan)
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: outline
            property: "fade"
            to: 1
            duration: Motion.pace(Motion.hoverIn)
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: leaving
        paused: Motion.isHeld && running
        NumberAnimation {
            target: outline
            property: "fade"
            to: 0
            duration: Motion.pace(outline.leaveDuration)
            easing.type: Easing.InQuad
        }
        ScriptAction { script: outline.trace = 0 }
    }
}
