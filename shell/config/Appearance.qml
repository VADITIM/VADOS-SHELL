pragma Singleton
import QtQuick
import Quickshell

// V/AS design tokens: unified unit sizes shared across VAD/OS apps.
Singleton {
    readonly property QtObject unit: QtObject {
        readonly property int base: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 24
    }

    readonly property QtObject radius: QtObject {
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 20
    }

    readonly property QtObject color: QtObject {
        readonly property color surface: "#1a1a1f"
        readonly property color onSurface: "#e8e8ee"
        readonly property color accent: "#8ab4ff"
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "Inter"
        readonly property int size: 13
    }

    readonly property int barHeight: 40
}
