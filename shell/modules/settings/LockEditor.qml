import QtQuick
import qs.config
import qs.components
import "../../utils/Lock.js" as Lock

Item {
    id: editor

    required property var carousel
    property var layout: []
    property string picked: ""
    property int blankAfter: 60
    property bool isEditing: false
    readonly property var look: Appearance.settings.lock
    readonly property real gridWidth: carousel.mainWidth
    readonly property real gridHeight: carousel.mainHeight
    readonly property real cellWidth: gridWidth / Lock.columns
    readonly property real cellHeight: gridHeight / Lock.rows
    readonly property var placements: Lock.parse(layout)
    readonly property var armed: Lock.moduleOf(picked)
    readonly property var blankChoices: ({ "never": 0, "30 s": 30, "1 min": 60, "5 min": 300, "10 min": 600 })

    signal layoutRequested(var entries)
    signal pickRequested(string key)
    signal blankAfterRequested(int seconds)
    signal editingRequested(bool isOn)

    OptionGroup {
        x: editor.carousel.mainLeft + editor.gridWidth - width
        y: editor.carousel.mainTop - Appearance.settings.wallpaper.captionGap - height
        width: Math.min(Appearance.settings.wallpaper.fieldWidth, editor.gridWidth)
        label: "WIDGETS EDIT MODE"
        options: ["off", "on"]
        current: editor.isEditing ? "on" : "off"
        onPicked: option => editor.editingRequested(option === "on")
    }

    Piece {
        role: "surface"
        x: editor.carousel.mainLeft
        y: editor.carousel.mainTop

        Item {
            id: frame
            width: editor.gridWidth
            height: editor.gridHeight

            Rectangle {
                anchors.fill: parent
                radius: Appearance.unit.small
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
            }

            Lattice {
                anchors.fill: parent
                visible: editor.isEditing
                columnLines: Lock.columns - 1
                rowLines: Lock.rows - 1
                firstX: editor.cellWidth
                firstY: editor.cellHeight
                stepX: editor.cellWidth
                stepY: editor.cellHeight
                ink: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
            }

            Repeater {
                model: editor.placements

                Piece {
                    id: tile

                    required property var modelData
                    readonly property bool isPicked: editor.picked === modelData.key

                    x: modelData.column * editor.cellWidth
                    y: modelData.row * editor.cellHeight
                    width: modelData.columns * editor.cellWidth
                    height: modelData.rows * editor.cellHeight
                    isCentered: true
                    opacity: editor.isEditing ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.unit.small
                        color: Qt.alpha(Appearance.color.accent, editor.look.tileAlpha)
                        border.width: tile.isPicked ? editor.look.outline : 1
                        border.color: Appearance.color.text
                        opacity: tile.isPicked ? editor.look.pickedShade : 1

                        Text {
                            anchors.centerIn: parent
                            text: Lock.moduleOf(tile.modelData.key).label
                            color: Appearance.color.text
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                        }
                    }
                }
            }

            Rectangle {
                id: ghost

                property int column: Math.max(0, Math.min(Lock.columns - (editor.armed?.columns ?? 1), Math.floor(area.mouseX / editor.cellWidth)))
                property int row: Math.max(0, Math.min(Lock.rows - (editor.armed?.rows ?? 1), Math.floor(area.mouseY / editor.cellHeight)))
                readonly property bool isFree: editor.armed !== null && Lock.fits(editor.layout, editor.picked, column, row)

                visible: editor.armed !== null && area.containsMouse
                x: column * editor.cellWidth
                y: row * editor.cellHeight
                width: (editor.armed?.columns ?? 0) * editor.cellWidth
                height: (editor.armed?.rows ?? 0) * editor.cellHeight
                radius: Appearance.unit.small
                color: Qt.alpha(isFree ? Appearance.color.accent : Appearance.color.danger, editor.look.tileAlpha * 2)
                border.width: 2
                border.color: isFree ? Appearance.color.accent : Appearance.color.danger
            }

            MouseArea {
                id: area
                anchors.fill: parent
                enabled: editor.isEditing
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    const column = Math.floor(mouse.x / editor.cellWidth)
                    const row = Math.floor(mouse.y / editor.cellHeight)
                    const hit = editor.placements.find(placement => column >= placement.column && column < placement.column + placement.columns && row >= placement.row && row < placement.row + placement.rows)
                    if (mouse.button === Qt.RightButton) {
                        if (hit)
                            editor.layoutRequested(Lock.remove(editor.layout, hit.key))
                        return
                    }
                    if (editor.armed === null) {
                        editor.pickRequested(hit ? hit.key : "")
                        return
                    }
                    if (ghost.isFree)
                        editor.layoutRequested(Lock.place(editor.layout, editor.picked, ghost.column, ghost.row))
                    editor.pickRequested("")
                }
            }
        }
    }

    OptionGroup {
        x: editor.carousel.mainLeft + editor.gridWidth - width
        y: editor.carousel.mainTop + editor.gridHeight + Appearance.settings.wallpaper.captionGap
        width: Math.min(Appearance.settings.wallpaper.fieldWidth, editor.gridWidth)
        canInline: false
        label: "SCREEN OFF AFTER"
        options: Object.keys(editor.blankChoices)
        current: Object.keys(editor.blankChoices).find(option => editor.blankChoices[option] === editor.blankAfter) ?? ""
        onPicked: option => editor.blankAfterRequested(editor.blankChoices[option])
    }
}
