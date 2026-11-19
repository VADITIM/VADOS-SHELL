import QtQuick
import qs.config
import qs.components
import "../../utils/PillOrder.js" as PillOrder

Item {
    id: arrangement

    property var order: []
    property var hidden: []
    readonly property var keys: PillOrder.normalise(order)
    readonly property var look: Appearance.settings.arrangement
    readonly property var heights: heightsOf()
    readonly property var names: ({
        usb: { glyph: "usb", label: "USB" },
        audio: { glyph: "speaker", label: "AUDIO" },
        network: { glyph: "wifi", label: "WI-FI" },
        battery: { glyph: "battery", label: "BATTERY" },
        settings: { glyph: "settings", label: "SETTINGS" },
        power: { glyph: "power", label: "POWER" }
    })
    property string draggedKey: ""
    property real dragTop: 0
    readonly property var shownKeys: draggedKey.length > 0 ? PillOrder.move(keys, draggedKey, PillOrder.slotFor(keys, draggedKey, dragTop + heightOf(draggedKey) / 2, heights)) : keys
    readonly property var offsets: PillOrder.offsetsFor(shownKeys, heights)

    signal orderRequested(var order)
    signal hiddenRequested(var hidden)

    width: parent ? parent.width : look.cell
    height: PillOrder.offsetsFor(keys, heights).total - look.gap

    function heightOf(key) {
        return key === PillOrder.fold ? look.fold : look.cell
    }

    function heightsOf() {
        const result = {}
        for (const key of PillOrder.keys)
            result[key] = heightOf(key) + look.gap
        return result
    }

    function topOf(key) {
        return PillOrder.offsetsFor(keys, heights)[key]
    }

    function toggleHidden(key) {
        const isHidden = hidden.indexOf(key) >= 0
        hiddenRequested(isHidden ? hidden.filter(entry => entry !== key) : hidden.concat([key]))
    }

    Repeater {
        model: PillOrder.keys

        Piece {
            id: row

            required property string modelData
            readonly property bool isFold: modelData === PillOrder.fold
            readonly property bool isDragged: arrangement.draggedKey === modelData
            readonly property bool isHidden: arrangement.hidden.indexOf(modelData) >= 0

            width: arrangement.width
            height: arrangement.heightOf(modelData)
            y: isDragged ? arrangement.dragTop : arrangement.offsets[modelData]
            z: isDragged ? 1 : 0

            Behavior on y {
                enabled: !row.isDragged
                NumberAnimation {
                    duration: Motion.pace(Motion.fold.reorder)
                    easing.type: Easing.OutBack
                }
            }

            Rectangle {
                visible: row.isFold
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: arrangement.look.foldLine
                radius: height / 2
                color: row.isDragged ? Appearance.color.accent : Appearance.color.hairline

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }
            }

            Item {
                visible: !row.isFold
                anchors.fill: parent
                opacity: row.isHidden && !row.isDragged ? arrangement.look.hiddenOpacity : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }

                Rectangle {
                    id: cell
                    width: arrangement.look.cell
                    height: arrangement.look.cell
                    radius: width / 2
                    color: row.isDragged ? Appearance.color.accent : Appearance.color.raised
                    scale: row.isDragged ? arrangement.look.lift : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                            easing.type: Easing.OutBack
                        }
                    }

                    Glyph {
                        anchors.centerIn: parent
                        width: arrangement.look.glyph
                        height: width
                        name: row.isFold ? "" : arrangement.names[row.modelData].glyph
                        color: row.isDragged ? Appearance.color.ground : Appearance.color.text
                    }
                }

                Text {
                    x: cell.width + arrangement.look.gap * 2
                    anchors.verticalCenter: cell.verticalCenter
                    text: row.isFold ? "" : arrangement.names[row.modelData].label
                    color: Appearance.color.textBody
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }
            }

            Rectangle {
                id: toggle
                visible: !row.isFold
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: arrangement.look.toggleWidth
                height: arrangement.look.toggleHeight
                radius: height / 2
                color: row.isHidden ? Appearance.color.hairline : Appearance.color.accent

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                        easing.type: Easing.OutQuad
                    }
                }

                Rectangle {
                    readonly property real size: toggle.height - arrangement.look.toggleInset * 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: row.isHidden ? arrangement.look.toggleInset : toggle.width - size - arrangement.look.toggleInset
                    width: size
                    height: size
                    radius: size / 2
                    color: row.isHidden ? Appearance.color.textBody : Appearance.color.panel

                    Behavior on x {
                        NumberAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                            easing.type: Easing.OutBack
                        }
                    }
                }
            }
        }
    }

    Gesture {
        id: drag

        property string pressedKey: ""

        anchors.fill: parent
        isHorizontal: false
        cursorShape: pressed && isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onPressed: mouse => pressedKey = PillOrder.keyAt(arrangement.keys, arrangement.heights, mouse.y)
        onTapped: mouse => {
            const key = PillOrder.keyAt(arrangement.keys, arrangement.heights, mouse.y)
            if (key !== PillOrder.fold && mouse.x > arrangement.width - arrangement.look.toggleReach)
                arrangement.toggleHidden(key)
        }
        onCrossed: (travelX, travelY) => {
            if (pressedKey.length === 0)
                return
            arrangement.dragTop = arrangement.topOf(pressedKey) + travelY
            arrangement.draggedKey = pressedKey
        }
        onMoved: (travelX, travelY) => {
            if (arrangement.draggedKey.length > 0)
                arrangement.dragTop = Math.max(0, Math.min(arrangement.height - arrangement.heightOf(arrangement.draggedKey), arrangement.topOf(arrangement.draggedKey) + travelY))
        }
        onThrown: (travelX, travelY) => {
            if (arrangement.draggedKey.length === 0)
                return
            const moved = arrangement.shownKeys
            arrangement.draggedKey = ""
            if (moved.join() !== arrangement.keys.join())
                arrangement.orderRequested(moved)
        }
        onEnded: {
            pressedKey = ""
            arrangement.draggedKey = ""
        }
    }
}
