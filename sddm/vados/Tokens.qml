import QtQuick

QtObject {
    readonly property QtObject color: QtObject {
        readonly property color ground: "#181818"
        readonly property color panel: "#121212"
        readonly property color hairline: "#3a3a3a"
        readonly property color text: "#dedede"
        readonly property color textMuted: "#9a9a9a"
        readonly property color textFaint: "#6a6a6a"
        readonly property color defaultAccent: "#ffffff"
        readonly property color danger: "#ff6b6b"
        readonly property color levelWarm: "#ffd429"
        readonly property color shadow: "#000000"
    }

    readonly property QtObject font: QtObject {
        readonly property string mono: "Space Mono"
        readonly property int body: 15
        readonly property int label: 13
        readonly property real labelSpacing: 2.2
        readonly property int chip: 12
    }

    readonly property QtObject login: QtObject {
        readonly property int time: 96
        readonly property int profile: 168
        readonly property int ring: 2
        readonly property int pill: 52
        readonly property int field: 360
        readonly property int button: 40
        readonly property int power: 148
        readonly property int arrow: 36
        readonly property int gap: 16
        readonly property int padding: 20
        readonly property real dim: 0.45
        readonly property int blur: 64
        readonly property real panelAlpha: 0.92
        readonly property int dot: 10
        readonly property int dotFall: 18
        readonly property real splashReach: 1.6
        readonly property real splashOpacity: 0.8
        readonly property real squeeze: 0.9
        readonly property int bubbles: 14
        readonly property int bubbleSmallest: 6
        readonly property int bubbleLargest: 20
        readonly property real bubbleOpacity: 0.12
    }

    readonly property QtObject motion: QtObject {
        readonly property int arrival: 260
        readonly property int stagger: 70
        readonly property int delay: 120
        readonly property real arrivalScale: 0.6
        readonly property real spring: 3.2
        readonly property real damping: 0.22
        readonly property int state: 220
        readonly property int shake: 60
        readonly property int shakeReach: 10
        readonly property int armed: 3000
        readonly property int pulse: 520
        readonly property int tick: 1000
        readonly property real pressDepth: 0.94
        readonly property real pulseLow: 0.4
        readonly property int leave: 160
        readonly property int dotPop: 200
        readonly property int drain: 150
        readonly property int splash: 560
        readonly property int squash: 110
        readonly property int roll: 280
        readonly property int riseShortest: 9000
        readonly property int riseLongest: 16000
    }
}
