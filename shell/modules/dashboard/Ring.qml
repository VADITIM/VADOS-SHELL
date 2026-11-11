import QtQuick
import QtQuick.Shapes
import qs.config

Item {
    id: ring

    property real value: 0
    property bool isShown: false
    property color color: Appearance.color.accent
    property real drawn: isShown ? Math.max(0, Math.min(1, value)) : 0
    property bool hasOuter: false
    property real outerValue: 0
    property color outerColor: Appearance.color.accent
    property real outerDrawn: isShown && hasOuter ? Math.max(0, Math.min(1, outerValue)) : 0
    readonly property var look: Appearance.dashboard.gauge
    readonly property real center: width / 2
    readonly property real radius: center - look.knob
    readonly property real start: -Math.PI / 2
    readonly property real outerRadius: radius + look.usageGap
    readonly property real tickReach: hasOuter ? outerRadius + look.tick * 0.6 : radius + look.tick

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.level)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on outerDrawn {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.level)
            easing.type: Easing.OutCubic
        }
    }

    function pointAt(share, distance) {
        const angle = start + share * Math.PI * 2
        return (center + Math.cos(angle) * distance).toFixed(2) + " " + (center + Math.sin(angle) * distance).toFixed(2)
    }

    function arc(from, to, distance) {
        const reach = distance ?? radius
        if (to - from < 0.001)
            return ""
        const pieces = Math.ceil((to - from) * 4)
        let path = "M" + pointAt(from, reach)
        for (let piece = 1; piece <= pieces; piece++)
            path += " A" + reach + " " + reach + " 0 0 1 " + pointAt(from + (to - from) * piece / pieces, reach)
        return path
    }

    function dashes(from) {
        let path = ""
        const slot = 1 / look.dashes
        for (let dash = 0; dash < look.dashes; dash++) {
            const begin = dash * slot
            if (begin < from + slot * 0.5)
                continue
            path += " " + arc(begin, begin + slot * look.dashShare)
        }
        return path
    }

    function radial(share, inner, outer) {
        return "M" + pointAt(share, inner) + " L" + pointAt(share, outer)
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.rgba(ring.color.r, ring.color.g, ring.color.b, ring.look.trackAlpha)
            strokeWidth: ring.look.ringStroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: ring.dashes(ring.drawn) }
        }

        ShapePath {
            strokeColor: ring.color
            strokeWidth: ring.look.ringStroke + 1
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: ring.arc(0, ring.drawn) }
        }

        ShapePath {
            strokeColor: Qt.alpha(Appearance.color.accent, ring.hasOuter ? ring.look.usageTrack : 0)
            strokeWidth: ring.look.usageStroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: ring.hasOuter && ring.isShown ? ring.arc(0, 0.999, ring.outerRadius) : "" }
        }

        ShapePath {
            strokeColor: ring.outerColor
            strokeWidth: ring.look.usageStroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: ring.arc(0, ring.outerDrawn, ring.outerRadius) }
        }

        ShapePath {
            strokeColor: Appearance.color.levelCritical
            strokeWidth: ring.look.tickStroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: ring.radial(0, ring.radius - ring.look.tick * 0.6, ring.tickReach) }
        }

        ShapePath {
            strokeColor: Appearance.color.text
            strokeWidth: ring.look.knobStroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: ring.radial(ring.drawn, ring.radius - ring.look.knob, ring.radius + ring.look.knob * 0.6) }
        }
    }
}
