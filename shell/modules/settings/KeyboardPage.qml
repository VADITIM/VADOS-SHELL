import QtQuick
import qs.config
import qs.components
import qs.services
import "../../utils/Geometry.js" as Geometry
import "../../utils/Keyboards.js" as KeyboardLayouts
import "../../utils/Keymap.js" as Keymap

Flow {
    id: page

    property bool isShown: false
    property var layouts: []
    property string device: KeyboardLayouts.everyKeyboard
    property string query: ""
    property var picked: null
    property string boardPath: ""
    property int shownLayer: 0
    property var selectedKey: null
    property string keyQuery: ""
    property var edits: ({})
    property bool isArmed: false
    readonly property var look: Appearance.settings.section
    readonly property var keyLook: Appearance.settings.keyboard
    readonly property bool canLayout: Compositor.capabilities.keyboardLayout === true
    readonly property bool canPerDevice: Compositor.capabilities.deviceKeyboardLayout === true
    readonly property string everyLabel: "ALL KEYBOARDS"
    readonly property var deviceOptions: [everyLabel].concat(canPerDevice ? Keyboards.devices.map(entry => entry.name) : [])
    readonly property var override: KeyboardLayouts.overrideFor(layouts, device)
    readonly property var shownChoices: Keyboards.choices.filter(choice => KeyboardLayouts.matches(choice, query))
    readonly property var board: Keyboards.boardPath === boardPath ? Keyboards.board : ({})
    readonly property int protocol: board.protocol ?? 0
    readonly property bool hasKeymap: (board.keymap ?? []).length > 0
    readonly property var keys: hasKeymap && (board.layout ?? []).length > 0 ? Keymap.parseLayout(board.layout) : Keymap.fallback()
    readonly property var extent: Keymap.extentOf(keys)
    readonly property real keyUnit: Math.min(keyLook.key, keyLook.canvasWidth / Math.max(1, extent.width))
    readonly property var codes: Keymap.catalogue(protocol).filter(entry => Keymap.matches(entry, keyQuery))
    readonly property var changes: Keymap.changesOf(edits)

    signal layoutsRequested(var entries)

    spacing: look.columnGap

    function deviceOf(option) {
        return option === everyLabel ? KeyboardLayouts.everyKeyboard : option
    }

    function codeOf(key) {
        const name = Keymap.keyName(shownLayer, key.row, key.column)
        if (edits[name] !== undefined)
            return edits[name]
        return hasKeymap ? Keymap.codeAt(board.keymap, shownLayer, key.row, key.column) : (key.code ?? 0)
    }

    function assign(code) {
        if (!hasKeymap || selectedKey === null)
            return
        const original = Keymap.codeAt(board.keymap, shownLayer, selectedKey.row, selectedKey.column)
        edits = Keymap.withEdit(edits, shownLayer, selectedKey.row, selectedKey.column, code, original)
        isArmed = false
    }

    function applyLayout(layout, variant) {
        layoutsRequested(KeyboardLayouts.withOverride(layouts, { device: device, layout: layout, variant: variant }))
        picked = null
    }

    function write() {
        if (!isArmed) {
            isArmed = true
            return
        }
        isArmed = false
        Keyboards.writeKeys(changes)
        edits = ({})
    }

    onIsShownChanged: {
        Keyboards.isWatching = isShown
        if (!isShown) {
            picked = null
            isArmed = false
        }
    }
    onBoardPathChanged: {
        edits = ({})
        selectedKey = null
        shownLayer = 0
        isArmed = false
    }

    Section {
        title: "LAYOUT"
        visible: page.canLayout

        OptionGroup {
            width: parent.width
            label: "KEYBOARD"
            options: page.deviceOptions
            current: page.device === KeyboardLayouts.everyKeyboard ? page.everyLabel : page.device
            onPicked: option => {
                page.device = page.deviceOf(option)
                page.picked = null
            }
        }

        Item {
            width: parent.width
            height: Appearance.settings.option

            Piece {
                role: "label"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "CURRENT"
                    color: Appearance.color.textBody
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }
            }

            Piece {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: page.override !== null ? KeyboardLayouts.keyOf(page.override).toUpperCase() : "SYSTEM"
                    color: page.override !== null ? Appearance.color.accent : Appearance.color.text
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }
        }

        TextField {
            label: "FIND"
            value: page.query
            placeholder: "de, dvorak, french"
            fieldWidth: parent.width
            onEdited: text => page.query = text
        }

        Piece {
            id: layoutPiece
            width: parent.width
            height: page.keyLook.list
            isFlipping: false
            enterDuration: Motion.settings.listRun
            enterEasing: Easing.OutCubic

            ListView {
                id: layoutList
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: page.shownChoices

                Drift {}

                delegate: Item {
                    id: layoutRow

                    required property var modelData
                    required property int index
                    readonly property real arrival: Geometry.clampUnit(layoutPiece.presence * (1 + Motion.settings.listSpread) - Math.min(index, page.look.listReach) / page.look.listReach * Motion.settings.listSpread)
                    readonly property bool isPicked: page.picked !== null && KeyboardLayouts.keyOf(page.picked) === KeyboardLayouts.keyOf(modelData)

                    width: layoutList.width
                    height: page.look.listRow
                    opacity: arrival

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Appearance.color.wash
                        opacity: layoutArea.containsMouse || layoutRow.isPicked ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.pace(layoutArea.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    Text {
                        x: Appearance.settings.fieldPadding
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x * 2
                        elide: Text.ElideRight
                        text: layoutRow.modelData.description + "  " + KeyboardLayouts.keyOf(layoutRow.modelData)
                        color: layoutRow.isPicked ? Appearance.color.accent : layoutRow.modelData.variant.length > 0 ? Appearance.color.textMuted : Appearance.color.textBody
                        font.family: Appearance.font.sans
                        font.pixelSize: Appearance.font.body
                    }

                    MouseArea {
                        id: layoutArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.picked = layoutRow.modelData
                    }
                }
            }
        }

        Row {
            x: Math.round((parent.width - width) / 2)
            spacing: Appearance.unit.small

            Piece {
                Action {
                    label: "APPLY"
                    isPrimary: true
                    isAvailable: page.picked !== null
                    onClicked: page.applyLayout(page.picked.layout, page.picked.variant)
                }
            }

            Piece {
                Action {
                    label: "RESET"
                    isAvailable: page.override !== null
                    onClicked: page.applyLayout("", "")
                }
            }
        }
    }

    Section {
        title: "REMAP"

        Hint {
            text: Keyboards.boards.length === 0 ? "NO VIA OR VIAL KEYBOARD FOUND" : Keyboards.problem
        }

        OptionGroup {
            width: parent.width
            visible: Keyboards.boards.length > 0
            label: "BOARD"
            options: Keyboards.boards.map(entry => entry.name.trim())
            current: (Keyboards.boards.find(entry => entry.path === page.boardPath)?.name ?? "").trim()
            onPicked: option => page.boardPath = Keyboards.boards.find(entry => entry.name.trim() === option)?.path ?? ""
        }

        Row {
            visible: page.boardPath.length > 0
            x: Math.round((parent.width - width) / 2)
            spacing: Appearance.unit.small

            Piece {
                Action {
                    label: "READ"
                    isAvailable: !Keyboards.isBusy
                    onClicked: Keyboards.readBoard(page.boardPath, false)
                }
            }

            Piece {
                visible: Keyboards.isDenied
                Action {
                    label: "READ AS ADMIN"
                    isAvailable: !Keyboards.isBusy
                    onClicked: Keyboards.readBoard(page.boardPath, true)
                }
            }
        }

        OptionGroup {
            width: parent.width
            visible: page.hasKeymap && (page.board.layers ?? 0) > 1
            label: "LAYER"
            options: Array.from({ length: page.board.layers ?? 0 }, (unused, index) => String(index))
            current: String(page.shownLayer)
            onPicked: option => page.shownLayer = parseInt(option, 10)
        }

        Hint {
            text: page.boardPath.length > 0 && !page.hasKeymap && (page.board.protocol ?? 0) > 0 ? "NO LAYOUT DEFINITION ON THIS BOARD, SHOWN AS ANSI" : ""
        }
    }

    Section {
        title: "KEYS"
        width: page.keyLook.canvasWidth

        Piece {
            role: "surface"
            width: page.keyUnit * page.extent.width
            height: page.keyUnit * page.extent.height

            Repeater {
                model: page.keys

                delegate: Piece {
                    id: keyPiece

                    required property var modelData
                    readonly property int code: page.codeOf(modelData)
                    readonly property bool isSelected: page.selectedKey !== null && page.selectedKey.row === modelData.row && page.selectedKey.column === modelData.column
                    readonly property bool isEdited: page.edits[Keymap.keyName(page.shownLayer, modelData.row, modelData.column)] !== undefined

                    x: modelData.x * page.keyUnit
                    y: modelData.y * page.keyUnit
                    width: modelData.width * page.keyUnit - page.keyLook.keyGap
                    height: modelData.height * page.keyUnit - page.keyLook.keyGap

                    Rectangle {
                        anchors.fill: parent
                        radius: page.keyLook.keyRadius
                        color: keyArea.containsMouse ? Appearance.color.wash : Appearance.color.raised
                        border.width: keyPiece.isSelected || keyPiece.isEdited ? Appearance.settings.action.ring : 0
                        border.color: keyPiece.isSelected ? Appearance.color.accent : Appearance.color.textMuted

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - page.keyLook.keyGap * 2
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: Keymap.labelOf(keyPiece.code, page.protocol)
                            color: keyPiece.isEdited ? Appearance.color.accent : Appearance.color.textBody
                            font.family: Appearance.font.sans
                            font.pixelSize: page.keyLook.legend
                        }
                    }

                    MouseArea {
                        id: keyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: page.hasKeymap
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.selectedKey = keyPiece.modelData
                    }
                }
            }
        }

        TextField {
            visible: page.selectedKey !== null
            label: "ASSIGN"
            value: page.keyQuery
            placeholder: "a, enter, volume, hold 1"
            fieldWidth: parent.width
            onEdited: text => page.keyQuery = text
        }

        Piece {
            visible: page.selectedKey !== null
            width: parent.width
            height: page.keyLook.pickerList

            GridView {
                id: codeGrid
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: page.keyLook.key * 3
                cellHeight: page.keyLook.key
                model: page.codes

                Drift {}

                delegate: Item {
                    id: codeCell

                    required property var modelData

                    width: codeGrid.cellWidth
                    height: codeGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: page.keyLook.keyGap
                        radius: page.keyLook.keyRadius
                        color: codeArea.containsMouse ? Appearance.color.wash : Appearance.color.raised

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - page.keyLook.keyGap * 2
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: codeCell.modelData.label
                            color: Appearance.color.textBody
                            font.family: Appearance.font.sans
                            font.pixelSize: page.keyLook.legend
                        }
                    }

                    MouseArea {
                        id: codeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.assign(codeCell.modelData.code)
                    }
                }
            }
        }

        Row {
            visible: page.hasKeymap
            x: Math.round((parent.width - width) / 2)
            spacing: Appearance.unit.small

            Piece {
                Action {
                    label: page.isArmed ? "CONFIRM " + page.changes.length + " KEYS" : "WRITE TO KEYBOARD"
                    isPrimary: true
                    isArmed: page.isArmed
                    isAvailable: page.changes.length > 0 && !Keyboards.isBusy
                    onClicked: page.write()
                }
            }

            Piece {
                Action {
                    label: "DISCARD"
                    isAvailable: page.changes.length > 0
                    onClicked: {
                        page.edits = ({})
                        page.isArmed = false
                    }
                }
            }
        }
    }
}
