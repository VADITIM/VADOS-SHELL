pragma Singleton
import QtQuick
import Quickshell

// Shared motion tokens: durations and spring parameters.
Singleton {
    readonly property QtObject duration: QtObject {
        readonly property int fast: 120
        readonly property int normal: 220
        readonly property int slow: 360
    }

    readonly property QtObject spring: QtObject {
        readonly property real stiffness: 4.0
        readonly property real damping: 0.35
        readonly property real mass: 1.0
    }
}
