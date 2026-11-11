import QtQuick
import QtQuick.Shapes
import "../utils/Icons.js" as Icons

Item {
    id: glyph

    property string name
    property color color: "white"
    property real level: 1
    property bool isCharging: false
    property real stroke: name === "dots" ? 3.2 : 1.8
    readonly property string icon: Icons.pick(name, level, isCharging)

    implicitWidth: 20
    implicitHeight: 20

    function cloud(left, bottom, size) {
        const unit = size / 11
        const number = value => (value * unit).toFixed(2)
        return "M" + left.toFixed(2) + " " + bottom.toFixed(2)
            + " a" + number(4) + " " + number(4) + " 0 0 1 " + number(-0.4) + " " + number(-7.97)
            + " a" + number(5.5) + " " + number(5.5) + " 0 0 1 " + number(10.6) + " " + number(-1.2)
            + " a" + number(4.6) + " " + number(4.6) + " 0 0 1 " + number(0.8) + " " + number(9.17) + " Z"
    }

    function rays(centerX, centerY, inner, outer, count, from, to) {
        let path = ""
        for (let ray = 0; ray < count; ray++) {
            const angle = from + (to - from) * ray / Math.max(1, count - 1)
            path += " M" + (centerX + Math.cos(angle) * inner).toFixed(2) + " " + (centerY + Math.sin(angle) * inner).toFixed(2)
                + " L" + (centerX + Math.cos(angle) * outer).toFixed(2) + " " + (centerY + Math.sin(angle) * outer).toFixed(2)
        }
        return path
    }

    function chip(isPadded) {
        let path = "M7 5.5 H17 a1.5 1.5 0 0 1 1.5 1.5 V17 a1.5 1.5 0 0 1 -1.5 1.5 H7 a1.5 1.5 0 0 1 -1.5 -1.5 V7 a1.5 1.5 0 0 1 1.5 -1.5 Z"
        for (const offset of [9, 12, 15]) {
            if (isPadded) {
                path += " M" + (offset - 0.8) + " 2.6 h1.6 v1.6 h-1.6 Z M" + (offset - 0.8) + " 19.8 h1.6 v1.6 h-1.6 Z"
                path += " M2.6 " + (offset - 0.8) + " h1.6 v1.6 h-1.6 Z M19.8 " + (offset - 0.8) + " h1.6 v1.6 h-1.6 Z"
            } else {
                path += " M" + offset + " 5.5 V3 M" + offset + " 18.5 V21 M5.5 " + offset + " H3 M18.5 " + offset + " H21"
            }
        }
        return path
    }

    function ram() {
        let path = "M5.5 8.5 A3 3 0 0 0 8.5 5.5 M15.5 5.5 A3 3 0 0 0 18.5 8.5 M18.5 15.5 A3 3 0 0 0 15.5 18.5 M8.5 18.5 A3 3 0 0 0 5.5 15.5"
        path += " M5.5 5.5 H18.5 V18.5 H5.5 Z"
        for (const offset of [7.2, 9.6, 12, 14.4, 16.8]) {
            const near = (offset - 0.6).toFixed(1)
            const far = (offset + 0.6).toFixed(1)
            path += " M" + near + " 5.5 V2.7 H" + far + " V5.5"
            path += " M" + near + " 18.5 V21.3 H" + far + " V18.5"
            path += " M5.5 " + near + " H2.7 V" + far + " H5.5"
            path += " M18.5 " + near + " H21.3 V" + far + " H18.5"
        }
        return path
    }

    function strokeFor(glyphName) {
        if (Icons.has(glyphName))
            return Icons.strokeOf(glyphName)
        switch (glyphName) {
        case "dots":
            return "M5.5 12 h0.01 M12 12 h0.01 M18.5 12 h0.01"
        case "eject":
            return "M12 5 L18.5 13 H5.5 Z M5.5 17.5 H18.5"
        case "search":
            return "M10.5 4 a6.5 6.5 0 1 0 0 13 a6.5 6.5 0 1 0 0 -13 Z M15.3 15.3 L20 20"
        case "style-floating":
            return "M3 3 V21 M9 7 a3 3 0 0 1 6 0 V17 a3 3 0 0 1 -6 0 Z"
        case "style-fused":
            return "M3 3 V21 M3 4 Q3 6 5 6 H10 a3 3 0 0 1 3 3 V15 a3 3 0 0 1 -3 3 H5 Q3 18 3 20"
        case "mode-canvas":
            return "M4 9 V4 H9 M15 4 H20 V9 M20 15 V20 H15 M9 20 H4 V15 M9 9 H15 V15 H9 Z"
        case "mode-desktop":
            return "M3 5 H21 V17 H3 Z M3 14 H21 M9 21 H15 M12 17 V21"
        case "style-bare":
            return "M3 3 V21 M11.5 7 h0.01 M11.5 12 h0.01 M11.5 17 h0.01"
        case "drop":
            return "M12 3.5 C9 7.5 6 10.8 6 14 a6 6 0 0 0 12 0 C18 10.8 15 7.5 12 3.5 Z"
        case "close":
            return "M7 7 L17 17 M17 7 L7 17"
        case "trash":
            return "M4.5 7 H19.5 M9.5 7 V4.5 H14.5 V7 M6.5 7 L7.5 20 H16.5 L17.5 7 M10.5 10.5 V16.5 M13.5 10.5 V16.5"
        case "bell":
            return "M6 16.5 V11 a6 6 0 0 1 12 0 V16.5 L19.5 18 H4.5 Z M10 20.5 a2 2 0 0 0 4 0"
        case "chat":
            return "M6.5 4.5 H17.5 a2 2 0 0 1 2 2 V14 a2 2 0 0 1 -2 2 H10.5 L6.5 19.5 V16 a2 2 0 0 1 -2 -2 V6.5 a2 2 0 0 1 2 -2 Z"
        case "send":
            return "M20.5 3.5 L3.5 10.5 L10 13.5 L13.5 20.5 Z M20.5 3.5 L10 13.5"
        case "mail":
            return "M4 6 H20 V18 H4 Z M4 6 L12 13 L20 6"
        case "headset":
            return "M4.5 14 V12 a7.5 7.5 0 0 1 15 0 V14 M4.5 13.5 H7.5 V18.5 H4.5 Z M16.5 13.5 H19.5 V18.5 H16.5 Z M19.5 18 a4 4 0 0 1 -4 3.5 H13"
        case "headphones":
            return "M4.5 17 V12 a7.5 7.5 0 0 1 15 0 V17 M4.5 13.5 H7.5 V19.5 H4.5 Z M16.5 13.5 H19.5 V19.5 H16.5 Z"
        case "deafened":
            return "M4.5 17 V12 a7.5 7.5 0 0 1 15 0 V17 M4.5 13.5 H7.5 V19.5 H4.5 Z M16.5 13.5 H19.5 V19.5 H16.5 Z M3.5 3.5 L20.5 20.5"
        case "play":
            return "M8 5.5 L18.5 12 L8 18.5 Z"
        case "pause":
            return "M8.5 6 V18 M15.5 6 V18"
        case "next":
            return "M6.5 6 L14.5 12 L6.5 18 Z M17.5 6 V18"
        case "previous":
            return "M17.5 6 L9.5 12 L17.5 18 Z M6.5 6 V18"
        case "cpu":
            return chip(false)
        case "gpu":
            return chip(true)
        case "ram":
            return ram()
        case "disk":
            return "M5 6 a7 2.5 0 1 0 14 0 a7 2.5 0 1 0 -14 0 M5 6 V18 M19 6 V18 M5 10 a7 2.5 0 0 0 14 0 M5 14 a7 2.5 0 0 0 14 0 M5 18 a7 2.5 0 0 0 14 0 M16 10.4 h0.01 M14 10.9 h0.01 M16 14.4 h0.01 M14 14.9 h0.01"
        case "umbrella":
            return "M3.5 12 a8.5 8.5 0 0 1 17 0 Z M12 12 V18.5 a1.8 1.8 0 0 1 -3.6 0 M12 3.5 V2.5"
        case "weather-clear":
            return "M12 7.5 a4.5 4.5 0 1 0 0 9 a4.5 4.5 0 1 0 0 -9 Z" + rays(12, 12, 6.8, 9.5, 9, 0, Math.PI * 2 * 8 / 9)
        case "weather-partly":
            return "M13.2 7.6 a3.6 3.6 0 0 1 6.2 3.4" + rays(16.4, 9.4, 4.9, 6.9, 5, -Math.PI * 1.05, Math.PI * 0.05) + " " + cloud(6, 20, 9)
        case "weather-cloudy":
            return cloud(6.5, 18, 11)
        case "weather-fog":
            return cloud(6.5, 14, 8) + " M4 17 H20 M6 20 H18"
        case "weather-rain":
            return cloud(6.5, 15.5, 10) + " M8.5 18 l-1 2.5 M12.5 18 l-1 2.5 M16.5 18 l-1 2.5"
        case "weather-snow":
            return cloud(6.5, 15.5, 10) + " M8 19 h0.01 M12 20.5 h0.01 M16 19 h0.01"
        case "weather-storm":
            return cloud(6.5, 15.5, 10) + " M13 16.5 L10.8 19.5 H13.4 L11.4 22.5"
        default:
            return "M6 5 H18 a1 1 0 0 1 1 1 V18 a1 1 0 0 1 -1 1 H6 a1 1 0 0 1 -1 -1 V6 a1 1 0 0 1 1 -1 Z"
        }
    }

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: glyph.width / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: glyph.color
            strokeWidth: glyph.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: glyph.strokeFor(glyph.icon) }
        }

        ShapePath {
            strokeColor: "transparent"
            fillColor: glyph.color
            PathSvg { path: Icons.fillOf(glyph.icon) }
        }
    }
}
