pragma Singleton
import QtQuick
import Quickshell
import "../utils/Tint.js" as Tint

Singleton {
    id: appearance

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
        readonly property real squircle: 4
        readonly property int squircleSteps: 96
    }

    readonly property QtObject color: QtObject {
        readonly property color ground: "#181818"
        readonly property color cornerFill: "#000000"
        readonly property bool isWhite: Config.data.pills.tone === "white"
        property real whiteness: isWhite ? 1 : 0

        Behavior on whiteness {
            NumberAnimation {
                duration: Motion.pace(Motion.stateDuration)
            }
        }

        function blend(whiteTone, darkTone) {
            const white = typeof whiteTone === "string" ? Qt.color(whiteTone) : whiteTone
            const dark = typeof darkTone === "string" ? Qt.color(darkTone) : darkTone
            return Qt.rgba(dark.r + (white.r - dark.r) * whiteness, dark.g + (white.g - dark.g) * whiteness, dark.b + (white.b - dark.b) * whiteness, dark.a + (white.a - dark.a) * whiteness)
        }

        readonly property color panel: Config.data.pills.color || blend("#f4f4f4", "#121212")
        readonly property real panelAlpha: Config.data.pills.opacity
        readonly property color hairline: blend("#c4c4c4", "#3a3a3a")
        readonly property color text: blend("#1c1c1c", "#dedede")
        readonly property color textBody: blend("#262626", "#d8d8d8")
        readonly property color textMuted: blend("#5e5e5e", "#9a9a9a")
        readonly property color clockText: "#dedede"
        readonly property color clockShade: "#99000000"
        readonly property real clockDateOpacity: 0.85
        readonly property color textFaint: blend("#8a8a8a", "#6a6a6a")
        readonly property color accent: Config.data.appearance.accent || defaultAccent
        readonly property color defaultAccent: "#ffffff"
        readonly property color danger: "#ff6b6b"
        readonly property color powerLock: "#4d9dff"
        readonly property color powerSleep: "#a78bfa"
        readonly property color powerRestart: "#ffb340"
        readonly property color powerShutdown: "#ff4d4d"
        readonly property color powerLogOut: "#3fc8b4"
        readonly property var powerColors: ({ "lock": powerLock, "suspend": powerSleep, "logout": powerLogOut, "restart": powerRestart, "shutdown": powerShutdown })
        readonly property color levelWarm: "#ffd429"
        readonly property color levelHot: "#ff9020"
        readonly property color levelCritical: "#e5342b"
        readonly property color levelFair: "#c8e65a"
        readonly property color levelFull: "#6fdc8c"
        readonly property color wash: blend(Qt.rgba(0, 0, 0, 0.08), Qt.rgba(1, 1, 1, 0.08))
        readonly property color raised: Qt.tint(panel, wash)
        readonly property color shadow: "#000000"
    }

    readonly property QtObject choice: QtObject {
        readonly property string style: Config.data.appearance.choice
        readonly property bool isPill: style === "pill"
        readonly property color outline: Config.data.appearance.choiceOutline || appearance.color.accent
        readonly property color pill: Config.data.appearance.choicePill || appearance.color.accent
        readonly property color current: isPill ? pill : outline
        readonly property bool isCustom: (isPill ? Config.data.appearance.choicePill : Config.data.appearance.choiceOutline).length > 0
        readonly property color pillInk: Tint.isLight(pill) ? appearance.color.ground : appearance.color.text
    }

    readonly property QtObject font: QtObject {
        readonly property string mono: "Space Mono"
        readonly property var monoFallbacks: ["Space Mono", "Consolas", "DejaVu Sans Mono", "Courier New"]
        readonly property string fixedMono: monoFallbacks.find(name => Qt.fontFamilies().indexOf(name) >= 0) ?? mono
        readonly property var sansFallbacks: ["Inter", "Noto Sans", "Adwaita Sans", "Cantarell", "DejaVu Sans", "Liberation Sans", "Segoe UI"]
        readonly property string sans: sansFallbacks.find(name => Qt.fontFamilies().indexOf(name) >= 0) ?? "sans-serif"
        readonly property int body: 15
        readonly property int label: 13
        readonly property real labelSpacing: 2.2
        readonly property int clock: 22
        readonly property int taskbarClock: 24
        readonly property real clockDateSpacing: 1.2
        readonly property var tabularFigures: ({ "tnum": 1 })
        readonly property int reading: 19
        readonly property int degrees: 36
        readonly property int chip: 12
        readonly property string scrambleSymbols: "&$~|=+-/\\#*%"
    }

    function bandColor(value, limits) {
        if (value < limits[0])
            return color.accent
        if (value < limits[1])
            return color.levelWarm
        if (value < limits[2])
            return color.levelHot
        return color.levelCritical
    }

    function levelColor(value, limits) {
        const shades = [color.levelFull, color.levelFair, color.levelWarm, color.levelHot, color.levelCritical]
        return shades[limits.filter(limit => value >= limit).length]
    }

    function chargeColor(level, isCharging) {
        if (isCharging)
            return color.levelFull
        const shades = [color.levelCritical, color.levelHot, color.levelWarm, color.levelFair, color.levelFull]
        return shades[dashboard.battery.bands.filter(limit => level >= limit).length]
    }

    readonly property QtObject liquid: QtObject {
        readonly property real fillThreshold: 0.5
        readonly property real rimThreshold: 0.3
        readonly property real edgeSoftness: 0.04
        readonly property real coreThreshold: 0.5
        readonly property real coreSoftness: 0.1
        readonly property int frost: 48
        readonly property real frostDetail: 0.25
    }

    readonly property QtObject screenCorner: QtObject {
        readonly property int radius: 10
    }

    readonly property QtObject taskbar: QtObject {
        readonly property int clockLine: 1
        readonly property int margin: 12
        readonly property int thickness: 52
        readonly property int item: 44
        readonly property int indicatorInset: 6
        readonly property int itemGap: 4
        readonly property int padding: 4
        readonly property int pillGap: 12
        readonly property int idleSize: 44
        readonly property int volumeTrack: 6
        readonly property real volumeStep: 0.05
        readonly property int idleGap: 10
        readonly property real hoverSlackShare: 0.05
        readonly property int hoverSwell: 4
        readonly property int icon: 26
        readonly property int glyph: 20
        readonly property int chargeRing: 36
        readonly property int chargeStroke: 2
        readonly property real chargeTrack: 0.22
        readonly property int chargeGap: 10
        readonly property int windowWidth: Math.max(480, margin * 2 + clipboard.width)
        readonly property int backdropWidth: 140
        readonly property int edgeStrip: 3
        readonly property int bead: 18
        readonly property real beadGrowth: 0.3
        readonly property int visitReach: 36
        readonly property int visitSwell: 10
        readonly property int reach: 76
        readonly property int tipHeight: 32
        readonly property int tipGap: 8
        readonly property int tipScreenGap: 16
        readonly property int tipPadding: 13
        readonly property int melt: 12
        readonly property int foldDot: 24
        readonly property int trayIcon: 22
        readonly property int trayCell: 30
        readonly property int trayLimit: 12
        readonly property int foldSpeck: 3
        readonly property int foldSpeckGap: 3
    }

    readonly property QtObject activity: QtObject {
        readonly property int bead: 24
        readonly property int speck: 6
        readonly property int width: 44
        readonly property int length: 92
        readonly property int padding: 12
        readonly property int glyph: 20
        readonly property int barCount: 3
        readonly property int bar: 3
        readonly property int barGap: 3
        readonly property int barHeight: 14
        readonly property int dot: 10
        readonly property int liveDot: 30
        readonly property int liveGlyph: 16
        readonly property int dotGap: 6
        readonly property real dotCore: 0.5
        readonly property int detailGap: 14
        readonly property int lineGap: 2
        readonly property int control: 28
        readonly property int controlGap: 4
        readonly property int countLimit: 9
        readonly property int carry: 26
        readonly property int gulp: 9
        readonly property real gulpStretch: 0.5
        readonly property var glyphs: ({ recording: "record", call: "headset", media: "music", notifications: "bell", tray: "dots" })
        readonly property QtObject expanded: QtObject {
            readonly property real factor: 1.3
            readonly property int detailGap: Math.round(14 * factor)
            readonly property int lineGap: Math.round(2 * factor)
            readonly property int control: Math.round(28 * factor)
            readonly property int controlGap: Math.round(4 * factor)
            readonly property int controlGlyph: Math.round(18 * factor)
            readonly property int glyph: Math.round(20 * factor)
            readonly property int label: Math.round(13 * factor)
            readonly property int body: Math.round(15 * factor)
            readonly property int smallLabel: 11
            readonly property int smallBody: 14
            readonly property int fade: 28
        }
        readonly property QtObject media: QtObject {
            readonly property int width: Math.round(300 * activity.expanded.factor)
            readonly property int height: Math.round(112 * activity.expanded.factor)
            readonly property int head: Math.round(128 * activity.expanded.factor)
            readonly property int art: Math.round(88 * activity.expanded.factor)
            readonly property int ring: Math.round(104 * activity.expanded.factor)
            readonly property real ringStroke: 2.5 * activity.expanded.factor
            readonly property int padding: Math.round(14 * activity.expanded.factor)
        }
        readonly property QtObject call: QtObject {
            readonly property int width: activity.media.width
            readonly property int height: activity.media.height
            readonly property int head: activity.media.head
            readonly property int avatar: activity.media.ring
            readonly property int padding: activity.media.padding
        }
        readonly property QtObject bud: QtObject {
            readonly property int size: 40
            readonly property int glyph: 18
            readonly property int gap: 8
            readonly property int spacing: 8
        }
        readonly property QtObject tray: QtObject {
            readonly property int height: Math.round(64 * activity.expanded.factor)
            readonly property int minimum: Math.round(200 * activity.expanded.factor)
            readonly property int badge: Math.round(44 * activity.expanded.factor)
            readonly property int cell: Math.round(34 * activity.expanded.factor)
            readonly property int icon: Math.round(20 * activity.expanded.factor)
            readonly property int columns: 8
        }
    }

    readonly property QtObject clipboard: QtObject {
        readonly property int width: 546
        readonly property int padding: 18
        readonly property int radius: 36
        readonly property int header: 42
        readonly property int headerGap: 8
        readonly property int row: 46
        readonly property int rowGap: 12
        readonly property int rowRadius: 18
        readonly property int rows: 11
        readonly property int height: padding * 2 + header + headerGap + rows * row + (rows - 1) * rowGap
        readonly property int imageSpan: 3
        readonly property int imageInset: 4
        readonly property int badge: 42
        readonly property int glyph: 24
        readonly property int thumbnail: 32
        readonly property int iconGap: 14
        readonly property int rowPadding: 12
        readonly property int action: 34
        readonly property int actionGlyph: 18
        readonly property real restShare: 0.6
        readonly property int maxLines: 3
        readonly property real charWidth: 0.56
        readonly property int labelWidth: width - padding * 2 - rowPadding * 2 - thumbnail - iconGap - action
        readonly property int lineChars: Math.floor(labelWidth / (text * charWidth))
        readonly property int text: 18
        readonly property int label: 14
        readonly property int trashInset: padding
        readonly property int scrollWidth: 4
        readonly property int scrollInset: 7
        readonly property int scrollMinimum: 36
        readonly property int scrollGrip: 6
        readonly property int divider: 2
        readonly property real dividerShare: 0.35
        readonly property color dividerColor: Qt.alpha(color.accent, dividerShare)
    }

    readonly property QtObject capture: QtObject {
        readonly property color tint: "#ff4d4d"
        readonly property real dim: 0.5
        readonly property real outline: 1.5
        readonly property int smallest: 6
        readonly property int nudge: 1
        readonly property int nudgeFar: 10
        readonly property int sizeHeight: 22
        readonly property int sizeGap: 8
        readonly property int sizePadding: 8
        readonly property int toolbarThickness: activity.width
        readonly property int tool: 36
        readonly property int toolGlyph: 20
        readonly property int hotkeySize: 9
        readonly property int hotkeyGap: 4
        readonly property color hotkeyShade: Tint.isLight(appearance.color.accent) ? "#000000" : "#ffffff"
        readonly property int toolGap: 2
        readonly property int toolPadding: 4
        readonly property int swatch: 30
        readonly property int swatchGlyph: 18
        readonly property int swatchGap: 8
        readonly property int menuGap: 8
        readonly property int stroke: 4
        readonly property int eraser: 10
        readonly property int dot: 10
        readonly property color ink: "#ff4d4d"
        readonly property int handle: 10
        readonly property int grab: 14
        readonly property int wheel: 150
        readonly property real wheelTurn: -90
        readonly property int knob: 16
        readonly property int slider: 12
        readonly property int gap: 10
        readonly property int wheelPadding: 14
        readonly property int wheelRadius: 28
        readonly property int textSize: 24
        readonly property int textPadding: 6
        readonly property real textLift: 0.75
        readonly property QtObject recording: QtObject {
            readonly property int width: Math.round(232 * activity.expanded.factor)
            readonly property int height: Math.round(60 * activity.expanded.factor)
            readonly property int padding: Math.round(10 * activity.expanded.factor)
            readonly property int head: Math.round(40 * activity.expanded.factor)
            readonly property int dot: Math.round(14 * activity.expanded.factor)
            readonly property int control: Math.round(34 * activity.expanded.factor)
            readonly property int controlGap: Math.round(6 * activity.expanded.factor)
        }
    }

    readonly property QtObject alerts: QtObject {
        readonly property int width: 288
        readonly property int height: 80
        readonly property int padding: 12
        readonly property int badge: 44
        readonly property int glyph: 20
        readonly property real ring: 1.5
        readonly property int gap: 12
        readonly property int lineGap: 2
        readonly property int count: 18
        readonly property int titleCharacters: 40
        readonly property int fade: 36
        readonly property int bodyCharacters: 72
        readonly property int expandedWidth: 400
        readonly property int radius: 40
        readonly property int titleLines: 3
        readonly property int bodyLines: 10
        readonly property int imageGap: 12
        readonly property int sectionGap: 10
        readonly property int openLabel: 13
        readonly property int openTitle: 17
        readonly property int imageHeight: 140
        readonly property int appIcon: 26
        readonly property int imageRadius: 12
    }

    readonly property QtObject extension: QtObject {
        readonly property color profilePerformance: "#ff4d4d"
        readonly property color profileBalanced: "#4d9dff"
        readonly property color profileSaver: "#4dd96f"
        readonly property var profileColors: ({ "performance": profilePerformance, "balanced": profileBalanced, "power-saver": profileSaver })
        readonly property int radius: 36
        readonly property int padding: 16
        readonly property int header: 44
        readonly property color hoverWash: Qt.rgba(1, 1, 1, 0.05)
        readonly property color pickedWash: Qt.rgba(1, 1, 1, 0.12)
        readonly property int row: 46
        readonly property int rowGap: 4
        readonly property int rowPadding: 10
        readonly property int glyph: 20
        readonly property int lock: 14
        readonly property int track: 6
        readonly property int trackGrab: 24
        readonly property int trackWidth: 64
        readonly property int streamName: 120
        readonly property int tab: 34
        readonly property int tabGap: 8
        readonly property real sliderStep: 0.05
        readonly property int percentWidth: 40
        readonly property int sectionGap: 10
        readonly property int divider: 1
        readonly property int toggleWidth: 34
        readonly property int toggleHeight: 18
        readonly property int toggleInset: 3
        readonly property real heightShare: 0.55
        readonly property int safeReach: 40
        readonly property int clockGap: 6
        readonly property int width: 440
        readonly property int split: 28
        readonly property int splitRoom: padding * 2 + split
        readonly property int field: 40
        readonly property int fieldPadding: 16
        readonly property int promptGap: 10
        readonly property QtObject sprout: QtObject {
            readonly property int reach: 26
            readonly property int rise: 18
            readonly property real seed: 0.35
            readonly property real fade: 2.5
        }
    }

    readonly property QtObject settings: QtObject {
        readonly property real bodyShare: 0.9
        readonly property int corner: 130
        readonly property int rootCorner: 40
        readonly property int melt: 16
        readonly property real dim: 0.55
        readonly property int inset: 28
        readonly property int top: 28
        readonly property int gap: 16
        readonly property int headerGap: 24
        readonly property real rightSpace: 0.22
        readonly property int endPadding: 56
        readonly property int contentGap: 32
        readonly property int wheel: 220
        readonly property real wheelTurn: -90
        readonly property int slider: 6
        readonly property int sliderGrab: 24
        readonly property real sliderStep: 0.05
        readonly property int swatch: 40
        readonly property int field: 40
        readonly property int fieldPadding: 16
        readonly property int fieldWidth: 220
        readonly property int pathWidth: 360
        readonly property QtObject textField: QtObject {
            readonly property real fadeLead: 2.5
            readonly property real textFrom: 0.6
            readonly property int actionReach: 6
        }
        readonly property int hexText: 15
        readonly property int option: 36
        readonly property int optionGap: 6
        readonly property int heading: 22
        readonly property int headingHeight: 84
        readonly property int headingGap: 12
        readonly property int headingLift: 44
        readonly property QtObject arrangement: QtObject {
            readonly property int cell: 44
            readonly property int glyph: 22
            readonly property int gap: 6
            readonly property real lift: 1.12
            readonly property int fold: 14
            readonly property int foldLine: 2
            readonly property int toggleWidth: 34
            readonly property int toggleHeight: 18
            readonly property int toggleInset: 3
            readonly property int toggleReach: 56
            readonly property real hiddenOpacity: 0.35
        }

        readonly property QtObject piece: QtObject {
            readonly property int slide: 22
            readonly property int rise: 12
            readonly property real squash: 0.7
            readonly property real fadeLead: 1.6
            readonly property real pop: 0.78
            readonly property real surface: 0.965
            readonly property int hintRise: 6
        }
        readonly property QtObject section: QtObject {
            readonly property int width: 420
            readonly property int inner: width
            readonly property int gap: 30
            readonly property int columnGap: 72
            readonly property int title: 18
            readonly property int groupTitle: 24
            readonly property real titleSpacing: 1.6
            readonly property int tick: 3
            readonly property int tickHeight: 14
            readonly property int tickGap: 12
            readonly property int titleIcon: 20
            readonly property real hintLine: 1.45
            readonly property int listSlide: 14
            readonly property int listReach: 8
            readonly property int titleGap: 18
            readonly property int rowGap: 18
            readonly property int rule: 1
            readonly property real ruleShade: 0.7
            readonly property int stripe: 4
            readonly property int stripeGap: 16
            readonly property real disabled: 0.4
            readonly property int icon: 52
            readonly property int list: 300
            readonly property int listRow: 38
            readonly property int preview: 24
        }
        readonly property QtObject keyboard: QtObject {
            readonly property int key: 38
            readonly property int keyGap: 4
            readonly property int keyRadius: 6
            readonly property int legend: 10
            readonly property int list: 220
            readonly property int pickerList: 260
            readonly property int canvasWidth: 640
        }
        readonly property QtObject choice: QtObject {
            readonly property int height: 38
            readonly property int padding: 16
            readonly property int gap: 6
            readonly property int divider: 18
            readonly property int ring: 2
            readonly property int labelGap: 8
            readonly property int inlineGap: 24
            readonly property int text: 15
            readonly property real spacing: 1.8
        }
        readonly property QtObject action: QtObject {
            readonly property int height: 38
            readonly property int padding: 20
            readonly property int ring: 1
            readonly property real armedFill: 0.14
            readonly property real tintFill: 0.1
            readonly property real tintHover: 0.18
            readonly property real tintRing: 0.3
        }
        readonly property QtObject selection: QtObject {
            readonly property int width: 260
            readonly property int wheel: 200
            readonly property int gap: 18
            readonly property int preview: 64
            readonly property int swatchGap: 12
            readonly property int hexField: 124
            readonly property int markGap: 36
        }
        readonly property QtObject clock: QtObject {
            readonly property int size: 15
            readonly property int inset: 30
        }
        readonly property QtObject wallpaper: QtObject {
            readonly property int plus: 56
            readonly property int plusStroke: 3
            readonly property real near: 0.32
            readonly property real far: 0.22
            readonly property real nearOverlap: 0.15
            readonly property int corner: 14
            readonly property int previewWidth: 1280
            readonly property int thumbWidth: 480
            readonly property int ring: 1
            readonly property real ringShade: 0.35
            readonly property int captionGap: 14
            readonly property int captionName: 22
            readonly property int captionCount: 15
            readonly property int fieldWidth: 360
            readonly property int reach: 2
            readonly property real glintFrom: 0.6
            readonly property QtObject glint: QtObject {
                readonly property real band: 0.35
                readonly property real reach: 1.6
                readonly property real tilt: 18
                readonly property real strength: 0.28
            }
        }
        readonly property QtObject lock: QtObject {
            readonly property int width: 560
            readonly property int bodyGap: 24
            readonly property int edgeGap: 36
            readonly property int padding: 24
            readonly property int corner: 64
            readonly property int fillet: 40
            readonly property int shot: 190
            readonly property int shotFrom: 96
            readonly property int shotInset: 44
            readonly property real shotStretch: 0.55
            readonly property int shotSink: 46
            readonly property real shotSquash: 0.35
            readonly property int cardGap: 18
            readonly property int captionHeight: 36
            readonly property real contentAt: 0.6
            readonly property int footer: 176
            readonly property real lineAlpha: 0.12
            readonly property real tileAlpha: 0.14
            readonly property int outline: 2
            readonly property real pickedShade: 0.5
        }
        readonly property QtObject widgets: QtObject {
            readonly property var grid: appearance.widgets
            readonly property int line: 1
            readonly property int outline: 2
            readonly property real lineAlpha: 0.1
            readonly property real tileAlpha: 0.16
            readonly property real wallpaperShade: 0.45
        }
        readonly property QtObject displays: QtObject {
            readonly property int padding: 36
            readonly property int line: 1
            readonly property int outline: 2
            readonly property real lineAlpha: 0.1
            readonly property real bodyAlpha: 0.16
            readonly property real restAlpha: 0.06
            readonly property int snap: 48
            readonly property int grid: 120
            readonly property real gridAlpha: 0.05
            readonly property int gridSpacingMin: 8
            readonly property int nameGap: 4
            readonly property int descriptionLines: 2
            readonly property int value: 150
            readonly property int stepper: 36
            readonly property int buttonWidth: 120
            readonly property int buttonHeight: 48
            readonly property int buttonGap: 16
            readonly property real zoomMax: 4
            readonly property real zoomStep: 1.15
            readonly property real offScale: 0.6
        }
        readonly property QtObject ascii: QtObject {
            readonly property int size: 24
            readonly property int gap: 84
            readonly property real angle: -25
            readonly property real shade: 0.04
        }
        readonly property QtObject home: QtObject {
            readonly property int bannerSize: 32
            readonly property real bannerLine: 1
            readonly property int gap: 24
            readonly property real versionShade: 0.5
            readonly property QtObject slice: QtObject {
                readonly property real spin: 90
                readonly property real jitter: 0.3
                readonly property real fade: 2.5
                readonly property int pushReach: 90
                readonly property int pushDepth: 14
            }
        }
        readonly property QtObject profile: QtObject {
            readonly property real avatarShare: 0.5
            readonly property real avatarWidthShare: 0.34
            readonly property int historyWidth: 800
            readonly property real initialShare: 0.4
            readonly property real hoverShade: 0.55
            readonly property int ring: 3
            readonly property int sectionGap: 40
            readonly property int nameGap: 16
            readonly property int lineGap: 6
            readonly property int nameSize: 40
            readonly property int secondSize: 16
            readonly property int underline: 2
            readonly property real hint: 0.35
            readonly property int weeks: 26
            readonly property int days: 7
            readonly property int cellGap: 3
            readonly property int boxPadding: 16
            readonly property int linkSize: 22
            readonly property real cellRound: 0.2
            readonly property real cellFloor: 0.2
            readonly property real cellStep: 0.2
            readonly property int rowGap: 8
            readonly property int rowPadding: 12
            readonly property real rowRest: 0.6
            readonly property int arrow: 44
            readonly property int arrowGlyph: 22
            readonly property real arrowWash: 0.14
            readonly property int arrowCorner: 14
            readonly property int arrowGap: 10
            readonly property int arrowNudge: 6
            readonly property int pickRows: 3
            readonly property real avatarSpin: -90
            readonly property real sliceReach: 0.5
            readonly property int infoWidth: 360
            readonly property int bannerSize: 9
            readonly property int fieldWidth: 220
            readonly property real bannerLine: 1
            readonly property int infoLabel: 160
            readonly property int infoSize: 16
            readonly property int infoGap: 10
        }
        readonly property QtObject navigation: QtObject {
            readonly property int width: 76
            readonly property int item: 60
            readonly property int itemGap: 8
            readonly property int padding: 8
            readonly property int gap: 14
            readonly property int glyph: 28
            readonly property real selection: 0.16
            readonly property real resting: 0.55
            readonly property int label: 34
            readonly property int labelPadding: 14
            readonly property int labelGap: 10
        }
    }

    readonly property QtObject widgets: QtObject {
        readonly property int cell: 88
        readonly property int gap: 12
        readonly property int inset: 80
        readonly property int padding: 16
        readonly property int corner: 64
        readonly property int stroke: 1
        readonly property int markStroke: 2
        readonly property real markAlpha: 0.6
        readonly property real markFill: 0.08
        readonly property real markScale: 0.92
        readonly property int clock: 58
        readonly property int glyph: 26
        readonly property int weatherGlyph: 44
        readonly property int dayGlyph: 22
        readonly property real dialStroke: 4
        readonly property real dialStart: -90
        readonly property real trackAlpha: 0.18
        readonly property int captionGap: 6
        readonly property real graphStroke: 2
        readonly property real graphFill: 0.16
        readonly property real graphHeadroom: 1.2
        readonly property real graphFloor: 125000
        readonly property var usageBands: dashboard.usageBands
        readonly property int noteGap: 10
        readonly property int noteCaret: 2
        readonly property real noteFocusRing: 1.5
    }

    readonly property QtObject calculator: QtObject {
        readonly property int width: 340
        readonly property int height: 520
        readonly property int minimumWidth: 260
        readonly property int minimumHeight: 400
        readonly property int padding: 18
        readonly property int gap: 10
        readonly property int corner: 22
        readonly property int display: 46
        readonly property int displayFloor: 22
        readonly property int line: 15
        readonly property int lineGap: 6
        readonly property int key: 20
        readonly property real keyFill: 0.06
        readonly property real operatorFill: 0.14
        readonly property real flashFill: 0.24
        readonly property int columns: 4
    }

    readonly property QtObject lock: QtObject {
        readonly property int gap: 18
        readonly property int padding: 22
        readonly property int corner: widgets.corner
        readonly property int melt: 14
        readonly property real dim: 0.32
        readonly property int blur: 64
        readonly property real backdropScale: 0.25
        readonly property int drop: 54
        readonly property real press: 0.42
        readonly property real bend: 0.34
        readonly property real bendLeast: 0.1
        readonly property int pull: 26
        readonly property int corePull: 90
        readonly property int splitPull: 14
        readonly property real pullLimit: 0.3
        readonly property real stretchGain: 0.1
        readonly property real stretchLimit: 0.45
        readonly property real bodyStretch: 0.55
        readonly property real stretchFade: 0.3
        readonly property real knockStretch: 0.012
        readonly property int knock: 34
        readonly property real knockSwell: 0.4
        readonly property int settle: 46
        readonly property real settleSwell: 0.06
        readonly property real settleSquash: 0.07
        readonly property int gatherReach: 150
        readonly property real gatherPop: 1.35
        readonly property real wallSpread: 0.16
        readonly property real wallCone: 1.15
        readonly property real growth: 2.2
        readonly property real bloom: 1.35
        readonly property real splitAt: 0.7
        readonly property real lead: 0.45
        readonly property real shotBirth: 0.6
        readonly property real popSwell: 1.6
        readonly property real smashSquash: 0.35
        readonly property int bubble: 20
        readonly property int bubblesLeast: 5
        readonly property int bubblesMost: 9
        readonly property int bubbleReach: 170
        readonly property real bubbleSpread: 0.4
        readonly property real bubbleBirth: 0.4
        readonly property real bubblePopAt: 0.72
        readonly property real bubblePop: 1.6
        readonly property real cutLean: 0.32
        readonly property int cutLine: 2
        readonly property int clock: 96
        readonly property int date: 19
        readonly property int glyph: 22
        readonly property int smallGlyph: 18
        readonly property int weatherGlyph: 44
        readonly property int avatar: 132
        readonly property int avatarRing: 2
        readonly property int initial: 54
        readonly property int bumpWidth: 150
        readonly property int bumpHeight: 34
        readonly property int bumpGap: 10
        readonly property int bumpText: 100
        readonly property int fieldHeight: 52
        readonly property int dot: 10
        readonly property int dotGap: 8
        readonly property int dotLimit: 24
        readonly property int caret: 2
        readonly property int caretHeight: 24
        readonly property int bar: 4
        readonly property int rowGap: 10
        readonly property int readingGap: 15
        readonly property int notificationRows: 4
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
        readonly property int crestInset: 14
        readonly property int jet: 30
        readonly property int jetReach: 64
        readonly property int impactPush: 16
        readonly property int stepTop: 30
        readonly property real stepTopShare: 0.7
        readonly property int stepBottom: 84
        readonly property real stepBottomShare: 0.42
        readonly property int stepCorner: 64
        readonly property int cornerSplash: 30
        readonly property int cornerReach: 46
        readonly property int blob: 22
        readonly property real blobVariance: 0.45
        readonly property int blobReach: 52
        readonly property int blobDrift: 18
        readonly property int trough: 30
        readonly property int troughLength: 200
        readonly property int troughStep: 8
        readonly property int curveStep: 8
        readonly property real splitNeck: 0.18
        readonly property real cutReach: 0.5
        readonly property real joinSlack: 0.5
        readonly property int edgeRound: 220
        readonly property int edgeRoundFade: 120
        readonly property int edgeSnap: 100
        readonly property real edgeReached: 0.6
        readonly property real cornerSharpness: 0.6
        readonly property real curveSlack: 1.3
        readonly property int seamBlend: 60
        readonly property int edgeHold: 16
        readonly property int edgeFade: 64
    }

    readonly property QtObject dashboard: QtObject {
        readonly property int width: 1040
        readonly property int chargeWidth: 690
        readonly property int bareWidth: 620
        readonly property int height: 600
        readonly property int corner: 130
        readonly property int rootCorner: 40
        readonly property int melt: 16
        readonly property real dim: 0.45
        readonly property int top: 24
        readonly property int graphicsX: 20
        readonly property int processorX: 20
        readonly property int memoryX: 256
        readonly property int readoutX: 290
        readonly property int dividerX: 572
        readonly property int dividerInset: 60
        readonly property int weatherX: 656
        readonly property int weatherWidth: 314
        readonly property real iconStroke: 2
        readonly property var usageBands: [0.75, 0.85, 0.95]
        readonly property var loadBands: [0.3, 0.55, 0.75, 0.9]
        readonly property var heatBands: [50, 65, 75, 85]
        readonly property int temperatureScale: 100
        readonly property QtObject font: QtObject {
            readonly property int label: 15
            readonly property int reading: 22
            readonly property int degrees: 56
            readonly property int day: 18
        }
        readonly property QtObject gauge: QtObject {
            readonly property int blockWidth: 246
            readonly property int blockHeight: 224
            readonly property int blockGap: 20
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
            readonly property real chipStroke: 4
            readonly property int chipText: 22
            readonly property int chipTextShift: 1
            readonly property int usageGap: 14
            readonly property real usageStroke: 3
            readonly property real usageTrack: 0.5
            readonly property int nameLift: 26
            readonly property int name: 16
            readonly property int nameSweep: 76
            readonly property real graphicsTilt: 22
            readonly property real processorTilt: -90
            readonly property real memoryTilt: 90
            readonly property int readoutGap: 2
            readonly property int readout: 46
            readonly property int spin: 360
            readonly property int bar: 8
            readonly property int barGap: 26
            readonly property int arcGap: 26
            readonly property int arcStart: 180
            readonly property int arcSweep: 66
            readonly property int labelGap: 12
            readonly property int fraction: 16
            readonly property int fractionGap: 2
        }
        readonly property QtObject drive: QtObject {
            readonly property int step: 420
            readonly property int glyph: 30
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
            readonly property int header: 32
            readonly property int pingCeiling: 999
            readonly property int rateDigits: 3
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
            readonly property int width: 60
            readonly property int height: 240
            readonly property int bar: 12
            readonly property int bolt: 22
            readonly property int gap: 12
            readonly property int percent: 18
            readonly property int capGap: 6
            readonly property var bands: [0.1, 0.2, 0.4, 0.6]
        }
        readonly property QtObject task: QtObject {
            readonly property int width: 724
            readonly property int minWidth: 460
            readonly property int height: 900
            readonly property int edgeGap: 36
            readonly property int bodyGap: 140
            readonly property int corner: 64
            readonly property int fillet: 40
            readonly property int shot: 190
            readonly property int shotFrom: 96
            readonly property int shotInset: 44
            readonly property real shotStretch: 0.55
            readonly property int shotSink: 46
            readonly property real shotSquash: 0.35
            readonly property int padding: 26
            readonly property int tab: 58
            readonly property int tabGlyph: 26
            readonly property int tabGap: 14
            readonly property int tabOut: 16
            readonly property real tabStretch: 0.24
            readonly property real tabSquash: 0.14
            readonly property int search: 58
            readonly property int searchGap: 22
            readonly property real searchShare: 0.5
            readonly property real searchStretch: 0.45
            readonly property real searchSquash: 0.3
            readonly property int searchPadding: 22
            readonly property int searchGlyph: 20
            readonly property int header: 66
            readonly property int cell: 112
            readonly property int unitGap: 4
            readonly property int cellPadding: 10
            readonly property int row: 38
            readonly property int iconRow: 50
            readonly property int icon: 30
            readonly property int iconGap: 12
            readonly property int toggleGap: 8
            readonly property int toggleGlyph: 18
            readonly property int fade: 28
            readonly property int sortMark: 6
            readonly property real heat: 0.3
            readonly property real selection: 0.18
            readonly property int menuWidth: 210
            readonly property int menuItem: 40
            readonly property int menuPadding: 7
            readonly property int menuCorner: 22
            readonly property QtObject font: QtObject {
                readonly property int name: 16
                readonly property int cell: 15
                readonly property int count: 14
                readonly property int label: 15
                readonly property int summary: 24
                readonly property int unit: 13
                readonly property int menu: 15
                readonly property int search: 16
            }
        }
        readonly property QtObject weather: QtObject {
            readonly property int icon: 112
            readonly property int iconGap: 18
            readonly property int rain: 18
            readonly property int daysY: 150
            readonly property int dayTile: 64
            readonly property int dayGlyph: 36
            readonly property int dayGap: 16
        }
    }

    readonly property QtObject prompt: QtObject {
        readonly property int width: 460
        readonly property int padding: 24
        readonly property int rowGap: 14
        readonly property int fieldHeight: 46
        readonly property int caret: 2
        readonly property int caretHeight: 18
        readonly property int dotGap: 2
        readonly property int caretGap: 3
        readonly property string mask: "•"
        readonly property int dotLimit: 24
        readonly property int buttonHeight: 40
        readonly property int buttonGap: 12
        readonly property int toggle: 18
        readonly property int shake: 12
        readonly property real disabled: 0.4
    }

    readonly property QtObject notifications: QtObject {
        readonly property real widthShare: 0.25
        readonly property int corner: 64
        readonly property int listFade: 36
        readonly property int rootCorner: 40
        readonly property int melt: 14
        readonly property real dim: 0.55
        readonly property real splitAt: 0.64
        readonly property int splitGap: 26
        readonly property var wall: [[0.9, 0], [1, 0.07], [0.97, 0.22], [1, 0.4], [0.96, 0.54], [0.78, 0.615], [0.5, 0.64], [0.72, 0.68], [0.82, 0.76], [0.84, 0.9], [0.95, 1]]
        readonly property var wholeWall: [[0.9, 0], [1, 0.07], [0.97, 0.3], [1, 0.6], [0.96, 0.85], [0.95, 1]]
        readonly property real wallOnly: 0.96
        readonly property real wholeListEnd: 0.94
        readonly property int staggerRows: 10
        readonly property int inset: 24
        readonly property int top: 30
        readonly property real listEnd: 0.58
        readonly property int row: 68
        readonly property int icon: 46
        readonly property int iconGap: 14
        readonly property int lineGap: 5
        readonly property int swipe: 120
        readonly property int bubble: 46
        readonly property int bubbleGlyph: 20
        readonly property int bubbleReach: 14
        readonly property var bubbleShares: [0.96, 0.89]
        readonly property real gearShare: 0.82
        readonly property int appGap: 10
        readonly property real devicesShare: 0.3
        readonly property real sendShare: 0.64
        readonly property int device: 52
        readonly property int deviceGap: 16
        readonly property int deviceName: 12
        readonly property int sendWidth: 150
        readonly property int sendHeight: 40
        readonly property int ring: 2
        readonly property real groupFade: 0.6
        readonly property var tint: ({ sample: 24, buckets: 12, alpha: 0.5, saturation: 0.25, darkest: 0.12, brightest: 0.92, lightness: 0.6 })
    }

    readonly property QtObject search: QtObject {
        readonly property int cardName: 17
        readonly property real widthShare: 0.2
        readonly property int corner: 64
        readonly property int rootCorner: 40
        readonly property int rowCorner: 14
        readonly property int inset: 22
        readonly property int top: 28
        readonly property int sectionGap: 18
        readonly property int topFade: 46
        readonly property int row: 46
        readonly property int rowGap: 4
        readonly property int rowIcon: 30
        readonly property int rowTextGap: 6
        readonly property int pinDot: 6
        readonly property var wall: [[0.648, 0], [0.314, 0.061], [0.267, 0.17], [0.362, 0.252], [0.695, 0.306], [1.124, 0.374], [1.314, 0.469], [1.267, 0.551], [0.933, 0.66], [0.505, 0.769], [0.219, 0.878], [0.314, 0.946], [0.695, 1]]
        readonly property int lobeGap: 12
        readonly property int found: 220
        readonly property int foundIcon: 168
        readonly property var foundTint: ({ sample: 24, buckets: 12, alpha: 0.5, saturation: 0.25, darkest: 0.08, brightest: 0.95, lightness: 0 })
        readonly property real foundShade: 0.14
        readonly property int hiddenRow: 34
        readonly property real newWindow: 1209600000
        readonly property int tabGap: 28
        readonly property int rowInset: 20
        readonly property real hiddenFade: 0.45
        readonly property QtObject menu: QtObject {
            readonly property int width: 200
            readonly property int item: 40
            readonly property int padding: 6
            readonly property int corner: 22
            readonly property int textPadding: 16
            readonly property real from: 0.6
        }
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
        readonly property int fieldText: 17
        readonly property real dim: 0.55
        readonly property QtObject profile: QtObject {
            readonly property real share: 0.2
            readonly property int blob: 232
            readonly property int avatar: 204
            readonly property real initialShare: 0.4
            readonly property real ring: 2
            readonly property int enterFrom: 40
            readonly property int enterApexX: 0
            readonly property int enterApexY: 160
            readonly property int gap: 44
            readonly property int blobGap: 18
            readonly property real swell: 0.12
            readonly property int splashCount: 9
            readonly property int splashDrop: 26
            readonly property int splashReach: 54
            readonly property real stretch: 0.12
            readonly property real stretchLimit: 0.4
            readonly property real squash: 1.5
            readonly property real throwEnd: 0.75
            readonly property real throwEdge: 0.32
            readonly property real throwSlide: 0.2
            readonly property real throwExit: 0.3
            readonly property int throwTurn: 150
            readonly property int throwPast: 130
            readonly property int throwApexY: -220
            readonly property int button: 58
            readonly property int buttonGlyph: 26
            readonly property int buttonGap: 12
            readonly property real armedWash: 0.18
            readonly property int nameGap: 16
            readonly property int name: 19
        }
    }
}
