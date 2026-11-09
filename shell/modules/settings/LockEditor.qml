import QtQuick
import qs.config
import "../../utils/Lock.js" as Lock

Column {
    id: editor

    property var layout: []
    property string picked: ""
    property string wallpaper: ""
    property real areaWidth: 0
    property real areaHeight: 0
    readonly property var look: Appearance.settings.lock
    readonly property real gridHeight: Math.max(0, Math.min(areaHeight - look.footer, areaWidth * look.aspect))
    readonly property real gridWidth: gridHeight / look.aspect
    readonly property real cellWidth: gridWidth / Lock.columns
    readonly property real cellHeight: gridHeight / Lock.rows
    readonly property var placements: Lock.parse(layout)
    readonly property var armed: Lock.moduleOf(picked)

    signal layoutRequested(var entries)
    signal pickRequested(string key)
    signal wallpaperRequested(string value)

    spacing: Appearance.unit.medium

    Piece {
        Item {
            id: frame
            width: editor.gridWidth
            height: editor.gridHeight

            Rectangle {
                anchors.fill: parent
                radius: Appearance.unit.small
                color: Appearance.color.wash
                border.width: 1
                border.color: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
            }

            Repeater {
                model: Lock.columns - 1

                Rectangle {
                    required property int index
                    x: (index + 1) * editor.cellWidth
                    width: 1
                    height: frame.height
                    color: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
                }
            }

            Repeater {
                model: Lock.rows - 1

                Rectangle {
                    required property int index
                    y: (index + 1) * editor.cellHeight
                    width: frame.width
                    height: 1
                    color: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
                }
            }

            Repeater {
                model: editor.placements

                Rectangle {
                    id: tile

                    required property var modelData
                    readonly property bool isPicked: editor.picked === modelData.key

                    x: modelData.column * editor.cellWidth
                    y: modelData.row * editor.cellHeight
                    width: modelData.columns * editor.cellWidth
                    height: modelData.rows * editor.cellHeight
                    radius: Appearance.unit.small
                    color: Qt.alpha(Appearance.color.accent, editor.look.tileAlpha)
                    border.width: isPicked ? 2 : 1
                    border.color: Appearance.color.accent
                    opacity: isPicked ? 0.5 : 1

                    Text {
                        anchors.centerIn: parent
                        text: Lock.moduleOf(tile.modelData.key).label
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
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

    Piece {
        Text {
            text: editor.armed ? "CLICK A CELL TO PLACE " + editor.armed.label : "PICK A MODULE ON THE RIGHT, OR CLICK A PLACED ONE TO MOVE IT. RIGHT CLICK REMOVES A WIDGET"
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    TextField {
        label: "WALLPAPER (IMAGE PATH)"
        value: editor.wallpaper
        onEdited: value => editor.wallpaperRequested(value)
    }
}
