import QtQuick
import QtTest
import qs.config
import qs.services
import qs.modules.widgets
import qs.modules.settings
import "../../shell/utils/Widgets.js" as Widgets
import "../../shell/utils/Placement.js" as Placement

Item {
    id: scene

    width: 1280
    height: 720

    property var requested: []
    property var edited: []

    WidgetLayer {
        id: desktop
        anchors.fill: parent
        layout: ["clock:0:0", "system:4:0"]
        onLayoutRequested: entries => {
            scene.requested = entries
            layout = entries
        }
    }

    WidgetEditor {
        id: editor
        visible: false
        screens: [{ name: "DP-1", width: 1920, height: 1080 }, { name: "HDMI-A-1", width: 1280, height: 720 }]
        startScreen: "HDMI-A-1"
        areaWidth: 1200
        areaHeight: 700
        layout: ["DP-1:weather:3:3"]
        onLayoutRequested: entries => {
            scene.edited = entries
            layout = entries
        }
    }

    TestCase {
        name: "Widgets"
        when: windowShown

        readonly property var lowerName: new RegExp("^[a-z]+$")
        readonly property var typeName: new RegExp("^[A-Z][A-Za-z]+Widget$")
        readonly property var look: Appearance.widgets

        function holderOf(key) {
            const repeater = desktop.children.find(child => child.count !== undefined && child.itemAt !== undefined)
            for (let index = 0; index < repeater.count; index++) {
                if (repeater.itemAt(index).modelData.key === key)
                    return repeater.itemAt(index)
            }
            return null
        }

        function faceOf(key) {
            const holder = holderOf(key)
            const found = []
            const visit = item => {
                for (const child of item.children) {
                    if (child.status !== undefined && child.source !== undefined && child.item !== undefined)
                        found.push(child)
                    visit(child)
                }
            }
            visit(holder)
            return found[0] ?? null
        }

        function test_catalogueRowsAreComplete() {
            const keys = Widgets.widgets.map(widget => widget.key)
            compare(new Set(keys).size, keys.length, "keys are unique")
            for (const widget of Widgets.widgets) {
                verify(lowerName.test(widget.key), widget.key)
                verify(widget.label.length > 0 && widget.label === widget.label.toUpperCase(), widget.key + " has a label in caps")
                verify(typeName.test(widget.root), widget.key + " names its file")
                verify(Number.isInteger(widget.columns) && widget.columns > 0 && Number.isInteger(widget.rows) && widget.rows > 0, widget.key + " has a size in cells")
                verify(widget.sources.every(source => Widgets.sources.indexOf(source) >= 0), widget.key + " asks only known sources")
                compare(Widgets.widgetOf(widget.key), widget)
            }
            compare(Widgets.widgetOf("agent"), null)
        }

        function test_everyCatalogueFileLoads() {
            desktop.layout = ["clock:0:0", "system:4:0", "weather:8:0", "network:0:2", "battery:4:2", "disk:6:2", "notes:8:2"]
            compare(Placement.settle(desktop.layout, Widgets.widgets, desktop.grid).length, Widgets.widgets.length, "every widget fits the test screen")
            for (const widget of Widgets.widgets) {
                tryVerify(() => faceOf(widget.key) !== null && faceOf(widget.key).status === Loader.Ready, 2000, widget.root + " loads")
                verify(faceOf(widget.key).item.isLive, widget.root + " is live while uncovered")
            }
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_notesTakeTextWhereTappedAndKeepIt() {
            desktop.layout = ["notes:0:0"]
            tryVerify(() => holderOf("notes") !== null && holderOf("notes").isRevealed && faceOf("notes").status === Loader.Ready, 3000)
            const holder = holderOf("notes")
            verify(holder.takesText)
            verify(!holder.isTyping)
            const rect = Widgets.rectOf(desktop.placementOf("notes"), desktop.origin, look)
            const before = Notes.text
            mouseClick(desktop, rect.x + rect.width / 2, rect.y + rect.height - look.padding - 4)
            tryVerify(() => holder.isTyping, 2000, "a tap starts typing")
            verify(desktop.wantsKeyboard, "the desktop asks for the keyboard while a note is typed in")
            verify(holder.z > 0, "the note sits above the drag area while typed in")
            keyClick(Qt.Key_End, Qt.ControlModifier)
            keyClick(Qt.Key_X)
            tryCompare(Notes, "text", before + "x", 2000)
            keyClick(Qt.Key_Escape)
            tryVerify(() => !holder.isTyping, 2000, "escape ends typing")
            Notes.write(before)
            mouseMove(desktop, 1, 1)
            tryVerify(() => !desktop.wantsKeyboard, 2000, "the desktop lets go of the keyboard once the pointer leaves")
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_onlyTextWidgetsAskForTheKeyboard() {
            for (const widget of Widgets.widgets)
                compare(typeof widget.takesText, "boolean", widget.key + " says whether it takes text")
            compare(Widgets.widgets.filter(widget => widget.takesText).map(widget => widget.key), ["notes"])
            desktop.layout = ["clock:0:0"]
            tryVerify(() => holderOf("clock") !== null && holderOf("clock").isRevealed, 3000)
            const rect = Widgets.rectOf(desktop.placementOf("clock"), desktop.origin, look)
            mouseMove(desktop, rect.x + rect.width / 2, rect.y + rect.height / 2)
            mouseClick(desktop, rect.x + rect.width / 2, rect.y + rect.height / 2)
            verify(!desktop.wantsKeyboard, "a clock never takes the keyboard")
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_layoutsAreKeptPerMonitor() {
            const entries = ["DP-1:clock:0:0", "DP-1:system:4:0", "HDMI-A-1:weather:2:1", "broken", "odd:name:disk:1:1"]
            compare(Widgets.layoutOn(entries, "DP-1"), ["clock:0:0", "system:4:0"])
            compare(Widgets.layoutOn(entries, "odd:name"), ["disk:1:1"], "a monitor name may hold a colon")
            compare(Widgets.layoutOn(entries, "eDP-1"), [], "a new monitor starts empty")
            compare(Widgets.screensOf(entries), ["DP-1", "HDMI-A-1", "odd:name"])
            verify(Widgets.hasLayout(entries, "HDMI-A-1"))
            verify(!Widgets.hasLayout(["DP-1:ghost:0:0"], "DP-1"), "an unknown widget is no layout")
            compare(Widgets.withLayout(entries, "DP-1", ["clock:1:1"]), ["HDMI-A-1:weather:2:1", "odd:name:disk:1:1", "DP-1:clock:1:1"], "other monitors keep their widgets")
        }

        function test_addingRemovingAndMovingStayOnTheGrid() {
            const grid = { columns: 8, rows: 4 }
            const placed = Widgets.placedOn(["X:clock:0:0"], "X", grid)
            compare(Widgets.added(placed, grid, "system"), ["clock:0:0", "system:4:0"])
            compare(Widgets.added(placed, grid, "clock"), ["clock:0:0"], "a widget is placed once")
            compare(Widgets.added(Widgets.placedOn(["X:clock:0:0", "X:system:4:0", "X:weather:0:2", "X:network:4:2"], "X", grid), grid, "disk").length, 4, "no room leaves the layout as it was")
            compare(Widgets.removed(placed, "clock"), [])
            compare(Widgets.moved(placed, grid, "clock", 9, 9), ["clock:4:2"], "a move past the edge lands inside")
            compare(Widgets.moved(Widgets.placedOn(["X:clock:0:0", "X:system:4:0"], "X", grid), grid, "clock", 3, 0), ["clock:3:2", "system:4:0"], "a move onto another widget finds the nearest free spot")
        }

        function test_pollingFollowsTheWidgetsOnUncoveredScreens() {
            const entries = ["DP-1:system:0:0", "HDMI-A-1:weather:0:0", "eDP-1:clock:0:0"]
            const screens = [
                { name: "DP-1", width: 1920, height: 1080, isCovered: false },
                { name: "HDMI-A-1", width: 1920, height: 1080, isCovered: true },
                { name: "eDP-1", width: 1920, height: 1080, isCovered: false }
            ]
            compare(Widgets.sourcesShown(entries, screens, look), ["hardware"], "a covered screen polls nothing")
            screens[1].isCovered = false
            compare(Widgets.sourcesShown(entries, screens, look), ["hardware", "weather"])
            compare(Widgets.sourcesShown(entries, [screens[2]], look), [], "a clock needs no polling")
            compare(Widgets.sourcesShown(["DP-1:system:0:0"], [{ name: "DP-1", width: 100, height: 100, isCovered: false }], look), [], "a widget with no room is not shown")
        }

        function test_widgetsSitOnTheGridAndTheirZonesTakeInput() {
            desktop.layout = ["clock:0:0", "system:4:0"]
            const grid = Widgets.gridOn(scene.width, scene.height, look)
            compare(desktop.grid, grid)
            compare(desktop.zones.length, 2)
            compare(desktop.zones[0], Widgets.rectOf({ column: 0, row: 0, columns: 4, rows: 2 }, desktop.origin, look))
            verify(desktop.zones[1].x >= desktop.zones[0].x + desktop.zones[0].width, "the system widget is beside the clock")
            compare(desktop.keyAt(desktop.zones[0].x + 1, desktop.zones[0].y + 1), "clock")
            compare(desktop.keyAt(1, 1), "")
            tryVerify(() => holderOf("clock").isRevealed, 3000, "the clock pops in on its own")
            tryCompare(holderOf("clock"), "x", desktop.zones[0].x)
        }

        function test_draggedWidgetSnapsToTheNearestFreeCell() {
            desktop.layout = ["clock:0:0", "system:4:0"]
            scene.requested = []
            desktop.pickUp("clock", 0, 0)
            desktop.follow(look.cell * 2 + 10, look.cell * 3 - 20)
            compare(holderOf("clock").x, desktop.zones[0].x + look.cell * 2 + 10, "the widget follows the finger")
            desktop.drop(0, 0)
            compare(scene.requested, ["clock:2:3", "system:4:0"])
            compare(desktop.carried, "")
            tryCompare(holderOf("clock"), "x", desktop.origin.x + look.cell * 2)
            tryCompare(holderOf("clock"), "y", desktop.origin.y + look.cell * 3)
        }

        function test_carriedWidgetMarksWhereItWillLand() {
            desktop.layout = ["clock:0:0", "system:4:0"]
            scene.requested = []
            compare(desktop.landing, null, "nothing is marked while nothing is carried")
            desktop.pickUp("clock", 0, 0)
            desktop.follow(look.cell * 2 + 10, look.cell * 3 - 20)
            compare(desktop.landing.column, 2)
            compare(desktop.landing.row, 3)
            const free = Widgets.rectOf(desktop.landing, desktop.origin, look)
            tryCompare(desktop, "landingX", free.x)
            tryCompare(desktop, "landingY", free.y)
            compare(desktop.landingWidth, holderOf("clock").width)
            desktop.follow(look.cell * 4, 0)
            verify(desktop.landing.column !== 4 || desktop.landing.row !== 0, "the mark never sits on another widget")
            const marked = desktop.landing
            desktop.drop(0, 0)
            compare(scene.requested[0], "clock:" + marked.column + ":" + marked.row, "the widget lands where the mark was")
            compare(desktop.landing, null)
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_widgetCornersDoNotStretchWithTheirShape() {
            desktop.layout = ["clock:0:0", "battery:4:0"]
            const outlineOf = key => {
                let found = null
                const visit = item => {
                    for (const child of item.children) {
                        if (child.outline !== undefined && child.corner !== undefined)
                            found = child
                        visit(child)
                    }
                }
                visit(holderOf(key))
                return found
            }
            const bendOf = shape => {
                const corner = shape.outline[12]
                return { x: shape.width - shape.strokeWidth - corner.x, y: shape.height - shape.strokeWidth - corner.y }
            }
            const wide = outlineOf("clock")
            const square = outlineOf("battery")
            verify(wide.width > square.width * 1.5, "the clock is wider than the battery")
            compare(wide.corner, look.corner)
            fuzzyCompare(bendOf(wide).x, bendOf(wide).y, 0.001)
            fuzzyCompare(bendOf(wide).x, bendOf(square).x, 0.001)
            fuzzyCompare(bendOf(wide).y, bendOf(square).y, 0.001)
            verify(look.corner < square.height / 2, "the corner is smaller than the full squircle's")
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_pointerDragMovesTheWidget() {
            desktop.layout = ["clock:0:0", "system:4:0"]
            scene.requested = []
            const zone = desktop.zones[0]
            const startX = zone.x + zone.width / 2
            const startY = zone.y + zone.height / 2
            mousePress(desktop, startX, startY)
            for (let step = 1; step <= 12; step++)
                mouseMove(desktop, startX, startY + step * look.cell / 4, 16)
            for (let rest = 0; rest < 6; rest++)
                mouseMove(desktop, startX, startY + look.cell * 3, 16)
            mouseRelease(desktop, startX, startY + look.cell * 3, Qt.LeftButton, Qt.NoModifier, 16)
            verify(scene.requested.length === 2, "the drop writes the layout")
            const clock = Placement.parse(scene.requested, Widgets.widgets)[0]
            compare(clock.column, 0)
            verify(clock.row >= 2, "the clock moved down")
        }

        function test_smallerScreenReplacesWidgetsInside() {
            desktop.layout = ["clock:0:0", "system:20:9"]
            const placed = desktop.placements.find(placement => placement.key === "system")
            verify(placed.column + placed.columns <= desktop.grid.columns && placed.row + placed.rows <= desktop.grid.rows, "the far widget is re-placed inside the screen")
            compare(desktop.layout, ["clock:0:0", "system:20:9"], "the saved layout is not rewritten by a re-place")
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_coveredScreenStopsTheWidgets() {
            desktop.layout = ["clock:0:0", "network:4:0"]
            tryVerify(() => faceOf("network") !== null && faceOf("network").status === Loader.Ready)
            verify(faceOf("network").item.isLive)
            desktop.isCovered = true
            verify(!desktop.isLive)
            verify(!faceOf("network").item.isLive, "a fullscreen window stops the widgets")
            desktop.isCovered = false
            verify(faceOf("network").item.isLive)
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_removedWidgetLeavesAndGivesUpItsZone() {
            desktop.layout = ["clock:0:0", "system:4:0"]
            tryVerify(() => holderOf("system").isRevealed, 3000)
            desktop.layout = ["clock:0:0"]
            compare(desktop.zones.length, 1)
            verify(!holderOf("system").isPlaced)
            tryVerify(() => faceOf("system") === null || faceOf("system").status === Loader.Null, 3000, "its face unloads once it has left")
            desktop.layout = ["clock:0:0", "system:4:0"]
        }

        function test_theEditorPlacesWidgetsPerMonitor() {
            scene.edited = []
            editor.layout = ["DP-1:weather:3:3"]
            compare(editor.monitor, "HDMI-A-1", "the editor starts on its own screen")
            editor.toggle("clock")
            compare(scene.edited, ["DP-1:weather:3:3", "HDMI-A-1:clock:0:0"])
            editor.toggle("clock")
            compare(scene.edited, ["DP-1:weather:3:3"])
            editor.monitor = "DP-1"
            compare(editor.placements.length, 1)
            editor.pickUp("weather", 0, 0)
            editor.follow(-editor.widgetLook.cell * editor.ratio * 3, -editor.widgetLook.cell * editor.ratio * 3)
            editor.drop(0, 0)
            compare(scene.edited, ["DP-1:weather:0:0"])
        }
    }
}
