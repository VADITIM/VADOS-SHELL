import QtQuick
import qs.config
import qs.components
import "../../utils/Widgets.js" as Widgets

Row {
    id: editor

    property var layout: []
    property var screens: []
    property string startScreen: ""
    property string wallpaper: ""
    property real areaWidth: 0
    property real areaHeight: 0
    property Item side: null
    readonly property real sideHeight: sideColumn.height
    property string monitor: startScreen
    property string carried: ""
    property real carryX: 0
    property real carryY: 0
    property real carryFromX: 0
    property real carryFromY: 0
    readonly property var look: Appearance.settings.widgets
    readonly property var section: Appearance.settings.section
    readonly property var widgetLook: look.grid
    readonly property var shown: screens.find(entry => entry.name === monitor) ?? screens[0] ?? null
    readonly property real aspect: shown && shown.width > 0 ? shown.height / shown.width : 0
    readonly property real frameWidth: aspect > 0 ? Math.max(0, Math.min(areaWidth - (side ? 0 : section.width + section.columnGap), areaHeight / aspect)) : 0
    readonly property real frameHeight: frameWidth * aspect
    readonly property real ratio: shown ? frameWidth / shown.width : 0
    readonly property var screenGrid: shown ? Widgets.gridOn(shown.width, shown.height, widgetLook) : ({ columns: 0, rows: 0 })
    readonly property var origin: shown ? Widgets.originOn(shown.width, shown.height, screenGrid, widgetLook) : ({ x: 0, y: 0 })
    readonly property var placements: shown ? Widgets.placedOn(layout, shown.name, screenGrid) : []
    readonly property string pressedKey: gesture.pressed ? keyAt(gesture.pressPoint.x, gesture.pressPoint.y) : ""

    signal layoutRequested(var entries)

    spacing: section.columnGap

    function rectOf(placement) {
        const rect = Widgets.rectOf(placement, origin, widgetLook)
        return { x: rect.x * ratio, y: rect.y * ratio, width: rect.width * ratio, height: rect.height * ratio }
    }

    function placementOf(key) {
        return placements.find(placement => placement.key === key) ?? null
    }

    function keyAt(x, y) {
        const hit = placements.find(placement => {
            const rect = rectOf(placement)
            return x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height
        })
        return hit ? hit.key : ""
    }

    function write(entries) {
        if (shown)
            layoutRequested(Widgets.withLayout(layout, shown.name, entries))
    }

    function toggle(key) {
        if (placementOf(key))
            write(Widgets.removed(placements, key))
        else
            write(Widgets.added(placements, screenGrid, key))
    }

    function pickUp(key, travelX, travelY) {
        const placement = placementOf(key)
        if (!placement)
            return
        const rect = rectOf(placement)
        carryFromX = rect.x
        carryFromY = rect.y
        carry(rect, travelX, travelY)
        carried = key
    }

    function carry(rect, travelX, travelY) {
        carryX = Math.max(0, Math.min(frameWidth - rect.width, carryFromX + travelX))
        carryY = Math.max(0, Math.min(frameHeight - rect.height, carryFromY + travelY))
    }

    function follow(travelX, travelY) {
        const placement = placementOf(carried)
        if (placement)
            carry(rectOf(placement), travelX, travelY)
    }

    function drop(velocityX, velocityY) {
        const key = carried
        if (!key || ratio <= 0)
            return
        const column = Math.round(((carryX + velocityX * Motion.settings.widgetFling) / ratio - origin.x) / widgetLook.cell)
        const row = Math.round(((carryY + velocityY * Motion.settings.widgetFling) / ratio - origin.y) / widgetLook.cell)
        carried = ""
        write(Widgets.moved(placements, screenGrid, key, column, row))
    }

    onStartScreenChanged: monitor = startScreen

    Column {
        spacing: editor.section.rowGap
        y: Math.max(0, Math.round((editor.areaHeight - editor.frameHeight) / 2))

        Piece {
            role: "surface"
            width: editor.frameWidth
            height: editor.frameHeight

            Item {
                id: frame
                width: editor.frameWidth
                height: editor.frameHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.unit.small
                    color: Appearance.color.raised
                }

                Masked {
                    anchors.fill: parent
                    visible: editor.wallpaper.length > 0

                    mask: Rectangle {
                        anchors.fill: parent
                        radius: Appearance.unit.small
                    }

                    Image {
                        anchors.fill: parent
                        source: !editor.visible || editor.wallpaper.length === 0 ? "" : editor.wallpaper.startsWith("/") ? "file://" + editor.wallpaper : editor.wallpaper
                        sourceSize.width: Appearance.settings.wallpaper.previewWidth
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: editor.look.wallpaperShade
                    }
                }

                Lattice {
                    anchors.fill: parent
                    columnLines: editor.screenGrid.columns + 1
                    rowLines: editor.screenGrid.rows + 1
                    firstX: (editor.origin.x - editor.widgetLook.gap / 2) * editor.ratio
                    firstY: (editor.origin.y - editor.widgetLook.gap / 2) * editor.ratio
                    stepX: editor.widgetLook.cell * editor.ratio
                    stepY: editor.widgetLook.cell * editor.ratio
                    columnStart: firstY
                    rowStart: firstX
                    columnLength: editor.screenGrid.rows * editor.widgetLook.cell * editor.ratio
                    rowLength: editor.screenGrid.columns * editor.widgetLook.cell * editor.ratio
                    stroke: editor.look.line
                    ink: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.unit.small
                    color: "transparent"
                    border.width: editor.look.line
                    border.color: Qt.alpha(Appearance.color.text, editor.look.lineAlpha * 2)
                }

                Repeater {
                    model: Widgets.widgets

                    Item {
                        id: tile

                        required property var modelData
                        readonly property var placement: editor.placementOf(modelData.key)
                        readonly property var rect: placement ? editor.rectOf(placement) : null
                        readonly property bool isCarried: editor.carried === modelData.key
                        property real restX: 0
                        property real restY: 0
                        property bool isSettled: false

                        function rest() {
                            if (!rect)
                                return
                            restX = rect.x
                            restY = rect.y
                            isSettled = true
                        }

                        function land() {
                            isSettled = false
                            restX = editor.carryX
                            restY = editor.carryY
                            isSettled = true
                            Qt.callLater(rest)
                        }

                        x: isCarried ? editor.carryX : restX
                        y: isCarried ? editor.carryY : restY
                        z: isCarried ? 1 : 0
                        width: (modelData.columns * editor.widgetLook.cell - editor.widgetLook.gap) * editor.ratio
                        height: (modelData.rows * editor.widgetLook.cell - editor.widgetLook.gap) * editor.ratio

                        onRectChanged: rest()
                        onIsCarriedChanged: if (!isCarried) land()
                        Component.onCompleted: rest()

                        Behavior on restX {
                            enabled: tile.isSettled
                            NumberAnimation {
                                duration: Motion.pace(Motion.settings.widgetGlide)
                                easing.type: Easing.OutBack
                            }
                        }

                        Behavior on restY {
                            enabled: tile.isSettled
                            NumberAnimation {
                                duration: Motion.pace(Motion.settings.widgetGlide)
                                easing.type: Easing.OutBack
                            }
                        }

                        Piece {
                            width: tile.width
                            height: tile.height
                            isWanted: tile.placement !== null
                            isCentered: true
                            onDeparted: tile.isSettled = false

                            Rectangle {
                                id: tileBody
                                width: tile.width
                                height: tile.height
                                radius: Appearance.unit.small
                                color: Qt.alpha(Appearance.color.accent, editor.look.tileAlpha)
                                border.width: tile.isCarried ? editor.look.outline : editor.look.line
                                border.color: Appearance.color.accent

                                Press {
                                    target: tileBody
                                    isPressed: editor.pressedKey === tile.modelData.key && !tile.isCarried
                                    isRaised: tile.isCarried
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - Appearance.unit.small
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: tile.modelData.label
                                    color: Appearance.color.text
                                    font.family: Appearance.font.sans
                                    font.pixelSize: Appearance.font.chip
                                    font.letterSpacing: Appearance.font.labelSpacing
                                }
                            }
                        }
                    }
                }

                Gesture {
                    id: gesture
                    anchors.fill: parent
                    cursorShape: editor.carried.length > 0 ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onCrossed: (travelX, travelY) => {
                        const key = editor.keyAt(pressPoint.x, pressPoint.y)
                        if (key.length > 0)
                            editor.pickUp(key, travelX, travelY)
                    }
                    onMoved: (travelX, travelY) => {
                        if (editor.carried.length > 0)
                            editor.follow(travelX, travelY)
                    }
                    onThrown: (travelX, travelY, velocityX, velocityY) => editor.drop(velocityX, velocityY)
                }
            }
        }
    }

    Column {
        id: sideColumn
        parent: editor.side ?? editor
        y: editor.side ? Math.max(0, Math.round((editor.side.height - height) / 2)) : 0
        spacing: editor.section.gap

        Section {
            title: "MONITOR"

            OptionGroup {
                options: editor.screens.map(entry => entry.name)
                current: editor.shown ? editor.shown.name : ""
                onPicked: option => editor.monitor = option
            }
        }

        Section {
            title: "WIDGETS"

            Repeater {
                model: Widgets.widgets

                OptionGroup {
                    required property var modelData

                    label: modelData.label + "  " + modelData.columns + " X " + modelData.rows
                    options: ["on", "off"]
                    current: editor.placements.some(placement => placement.key === modelData.key) ? "on" : "off"
                    onPicked: option => {
                        if ((option === "on") !== (current === "on"))
                            editor.toggle(modelData.key)
                    }
                }
            }
        }
    }
}
