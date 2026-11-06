pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property QtObject unit: QtObject {
        readonly property int base: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int extraLarge: 24
    }

    readonly property QtObject radius: QtObject {
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 20
    }

    readonly property QtObject color: QtObject {
        readonly property color ground: "#181818"
        readonly property color panel: "#121212"
        readonly property real panelAlpha: 0.94
        readonly property color hairline: "#3a3a3a"
        readonly property color text: "#dedede"
        readonly property color textBody: "#d8d8d8"
        readonly property color textMuted: "#9a9a9a"
        readonly property color textFaint: "#6a6a6a"
        readonly property color accent: Config.data.appearance.accent || defaultAccent
        readonly property color defaultAccent: "#ffffff"
        readonly property color danger: "#ff6b6b"
        readonly property color levelCool: "#9fd8f2"
        readonly property color levelWarm: "#ffd429"
        readonly property color levelHot: "#ff9020"
        readonly property color levelCritical: "#e5342b"
        readonly property color levelFair: "#c8e65a"
        readonly property color levelFull: "#6fdc8c"
        readonly property color wash: Qt.rgba(1, 1, 1, 0.08)
        readonly property color shadow: "#000000"
    }

    readonly property QtObject font: QtObject {
        readonly property string mono: "Space Mono"
        readonly property int body: 12
        readonly property int label: 10
        readonly property real labelSpacing: 2.6
        readonly property int clock: 20
        readonly property int reading: 16
        readonly property int degrees: 34
        readonly property int chip: 9
    }

    function bandColor(value, limits) {
        if (value < limits[0])
            return color.levelCool
        if (value < limits[1])
            return color.levelWarm
        if (value < limits[2])
            return color.levelHot
        return color.levelCritical
    }

    readonly property QtObject taskbar: QtObject {
        readonly property int margin: 11
        readonly property int thickness: 47
        readonly property int item: 40
        readonly property int itemGap: 4
        readonly property int padding: 4
        readonly property int pillGap: 11
        readonly property int idleSize: 40
        readonly property int idleGap: 9
        readonly property int hoverSlack: 8
        readonly property int hoverSwell: 4
        readonly property int icon: 23
        readonly property int glyph: 18
        readonly property int windowWidth: 340
        readonly property int backdropWidth: 140
        readonly property int edgeStrip: 3
        readonly property int bead: 16
        readonly property real beadGrowth: 0.3
        readonly property int visitReach: 32
        readonly property int visitSwell: 9
        readonly property int reach: 68
        readonly property int tipHeight: 29
        readonly property int tipGap: 7
        readonly property int tipTextLimit: 220
        readonly property int melt: 11
        readonly property int foldDot: 22
        readonly property int foldSpeck: 3
        readonly property int foldSpeckGap: 3
    }

    readonly property QtObject extension: QtObject {
        readonly property int width: 300
        readonly property int radius: 44
        readonly property int padding: 22
        readonly property int header: 44
        readonly property int headerGap: 14
        readonly property int row: 46
        readonly property int rowGap: 4
        readonly property int rowPadding: 14
        readonly property int glyph: 20
        readonly property int lock: 14
        readonly property int melt: 12
    }

    readonly property QtObject settings: QtObject {
        readonly property int width: 600
        readonly property int height: 440
        readonly property int radius: 30
        readonly property int padding: 28
        readonly property int gap: 16
        readonly property int headerGap: 24
        readonly property int wheel: 220
        readonly property int knob: 18
        readonly property int slider: 14
        readonly property int swatch: 40
        readonly property int field: 40
        readonly property int hexText: 14
        readonly property int option: 36
        readonly property int optionGap: 6
        readonly property int melt: 14
        readonly property real dim: 0.55
        readonly property int jolt: 6
        readonly property int ball: 84
        readonly property int crouchShift: 12
        readonly property int overshoot: 22
        readonly property var trail: [0.5, 0.36, 0.24]
        readonly property int splashCount: 8
        readonly property int splash: 26
        readonly property real splashReach: 1.16
        readonly property real budSeed: 0.4
        readonly property QtObject tabBar: QtObject {
            readonly property int width: 52
            readonly property int item: 44
            readonly property int itemGap: 4
            readonly property int padding: 4
            readonly property int gap: 10
            readonly property int glyph: 20
        }
    }

    readonly property QtObject desktop: QtObject {
        readonly property int parkReach: 40000
        readonly property int parkSpacing: 2000
        readonly property int cascadeStep: 32
        readonly property int cascadeSteps: 8
    }

    readonly property QtObject rising: QtObject {
        readonly property int count: 28
        readonly property real low: 8
        readonly property real high: 18
        readonly property real sink: 5
        readonly property real swayLow: 5
        readonly property real swayHigh: 16
        readonly property real shrink: 0.55
    }

    readonly property QtObject burst: QtObject {
        readonly property int ball: 120
        readonly property int leaveBall: 72
        readonly property int rootSpan: 120
        readonly property int rootSwell: 48
        readonly property real swellShare: 0.3
        readonly property real rootCap: 0.05
        readonly property int crest: 28
        readonly property int crestLength: 340
        readonly property int crestSamples: 36
        readonly property int crestInset: 14
        readonly property int jet: 30
        readonly property int jetReach: 64
        readonly property int impactPush: 16
        readonly property int stepTop: 30
        readonly property real stepTopShare: 0.7
        readonly property int stepBottom: 84
        readonly property real stepBottomShare: 0.42
        readonly property int stepCorner: 64
        readonly property int stepSide: 56
        readonly property int stepSideHeight: 244
        readonly property int stepSideOffset: 22
        readonly property int stepSideCorner: 36
        readonly property int cornerSplash: 30
        readonly property int cornerReach: 46
        readonly property int trough: 30
        readonly property int troughLength: 200
        readonly property int troughStep: 8
        readonly property int spray: 24
        readonly property int sprayCount: 10
        readonly property int curveSamples: 8
    }

    readonly property QtObject dashboard: QtObject {
        readonly property int width: 1000
        readonly property int height: 600
        readonly property int corner: 130
        readonly property int rootCorner: 40
        readonly property int melt: 16
        readonly property real dim: 0.45
        readonly property int top: 24
        readonly property int graphicsX: 20
        readonly property int processorX: 256
        readonly property int memoryX: 138
        readonly property int dividerX: 572
        readonly property int dividerInset: 60
        readonly property int weatherX: 616
        readonly property int weatherWidth: 314
        readonly property real iconStroke: 2
        readonly property var temperatureBands: [60, 70, 85]
        readonly property var usageBands: [0.75, 0.85, 0.95]
        readonly property int temperatureScale: 100
        readonly property QtObject gauge: QtObject {
            readonly property int blockWidth: 246
            readonly property int blockHeight: 224
            readonly property int blockGap: 4
            readonly property int ring: 212
            readonly property real ringStroke: 3
            readonly property int dashes: 44
            readonly property real dashShare: 0.5
            readonly property real trackAlpha: 0.75
            readonly property int tick: 9
            readonly property real tickStroke: 4
            readonly property int knob: 9
            readonly property real knobStroke: 4
            readonly property int chip: 128
            readonly property int loadText: 20
            readonly property int bar: 8
            readonly property int barGap: 26
            readonly property int arcGap: 14
            readonly property int textInset: 16
            readonly property int textSweep: 150
            readonly property int arcStart: 180
            readonly property int arcSweep: 90
            readonly property int labelGap: 12
            readonly property int fraction: 10
            readonly property int fractionGap: 2
        }
        readonly property QtObject drive: QtObject {
            readonly property int width: 360
            readonly property int glyph: 26
            readonly property int glyphGap: 14
            readonly property int rowGap: 12
            readonly property int barHeight: 8
            readonly property int dot: 6
            readonly property int dotGap: 8
            readonly property int inset: 14
        }
        readonly property QtObject traffic: QtObject {
            readonly property int gap: 12
            readonly property int dividerGap: 24
            readonly property int inset: 14
            readonly property int header: 24
            readonly property int graphGap: 8
            readonly property int valueGap: 6
            readonly property int columnGap: 28
            readonly property real line: 2
            readonly property int dot: 6
            readonly property real fillAlpha: 0.3
            readonly property real floor: 125000
            readonly property real headroom: 1.3
        }
        readonly property QtObject battery: QtObject {
            readonly property int width: 40
            readonly property int height: 140
            readonly property int cap: 16
            readonly property int capHeight: 6
            readonly property int corner: 7
            readonly property int inset: 4
            readonly property int bolt: 26
            readonly property int gap: 12
            readonly property int pull: 6
            readonly property var bands: [0.1, 0.25, 0.4, 0.6, 0.8]
        }
        readonly property QtObject weather: QtObject {
            readonly property int icon: 112
            readonly property int iconGap: 18
            readonly property int rain: 14
            readonly property int daysY: 150
            readonly property int dayTile: 44
            readonly property int dayGlyph: 26
            readonly property int dayGap: 10
            readonly property int vacantY: 250
            readonly property int vacantHeight: 254
        }
    }

    readonly property QtObject search: QtObject {
        readonly property int tile: 88
        readonly property int tileGap: 18
        readonly property int favoriteColumns: 4
        readonly property int favoriteRows: 2
        readonly property int label: 20
        readonly property int nameGap: 5
        readonly property int name: 10
        readonly property int cardName: 15
        readonly property real widthShare: 0.2
        readonly property int corner: 64
        readonly property int rootCorner: 40
        readonly property int inset: 22
        readonly property int top: 28
        readonly property int sectionGap: 18
        readonly property int row: 46
        readonly property int rowGap: 4
        readonly property int rowIcon: 30
        readonly property int rowTextGap: 6
        readonly property int pinDot: 6
        readonly property int wallOverhang: 52
        readonly property var wall: [[0.648, 0], [0.314, 0.061], [0.267, 0.17], [0.362, 0.252], [0.695, 0.306], [1.124, 0.374], [1.314, 0.469], [1.267, 0.551], [0.933, 0.66], [0.505, 0.769], [0.219, 0.878], [0.314, 0.946], [0.695, 1]]
        readonly property int lobeGap: 12
        readonly property int found: 220
        readonly property int foundIcon: 120
        readonly property int foundX: 390
        readonly property real foundShare: 0.483
        readonly property real ringStroke: 2
        readonly property real tether: 1
        readonly property int nameReach: 16
        readonly property int nameHeight: 40
        readonly property int namePadding: 18
        readonly property int nameLimit: 220
        readonly property real rowShrink: 0.5
        readonly property int melt: 14
        readonly property int fieldHeight: 46
        readonly property int fieldPadding: 16
        readonly property int fieldText: 15
        readonly property real dim: 0.55
    }
}
