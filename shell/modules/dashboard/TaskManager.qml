import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Processes.js" as ProcessTable

FocusScope {
    id: manager

    property bool isShown: false
    property string tab: "processes"
    property var sorts: ({ processes: { key: "cpu", isDescending: true }, history: { key: "cpuTime", isDescending: true } })
    property string selectedKey: ""
    property string menuKey: ""
    readonly property var look: Appearance.dashboard.task
    readonly property var columns: ProcessTable.columns[tab]
    readonly property var sort: sorts[tab]
    readonly property bool isHistory: tab === "history"
    readonly property var source: isHistory ? Processes.historyRows : Processes.groups
    readonly property var rows: ProcessTable.sorted(source, sort)
    readonly property real listWidth: width - look.padding * 2
    readonly property real nameWidth: listWidth - (columns.length - 1) * look.cell
    readonly property var menuRow: rows.find(row => row.key === menuKey) ?? null
    readonly property var totals: {
        const largest = key => source.reduce((most, row) => Math.max(most, row[key]), 0)
        return isHistory
            ? { cpuTime: largest("cpuTime"), memory: Hardware.memoryTotal, disk: largest("disk"), network: 0 }
            : { cpu: 1, memory: Hardware.memoryTotal, disk: Math.max(Processes.diskRate, largest("disk")), network: 0 }
    }
    readonly property var summary: isHistory
        ? {
            name: String(source.length),
            cpuTime: ProcessTable.duration(source.reduce((total, row) => total + row.cpuTime, 0)),
            memory: "",
            disk: ProcessTable.bytes(source.reduce((total, row) => total + row.disk, 0)),
            network: "--"
        }
        : {
            name: String(source.reduce((total, row) => total + row.pids.length, 0)),
            cpu: ProcessTable.percent(Hardware.cpuLoad),
            memory: ProcessTable.percent(Hardware.memoryTotal > 0 ? Hardware.memoryUsed / Hardware.memoryTotal : 0),
            disk: ProcessTable.rate(Processes.diskRate),
            network: ProcessTable.rate(Traffic.download + Traffic.upload)
        }

    function refill() {
        ProcessTable.sync(listModel, rows)
    }

    function pickTab(key) {
        if (key === tab)
            return
        closeMenu()
        listModel.clear()
        selectedKey = ""
        tab = key
    }

    function sortBy(key) {
        const next = Object.assign({}, sorts)
        next[tab] = ProcessTable.nextSort(sort, key)
        sorts = next
    }

    function openMenu(key, x, y) {
        selectedKey = key
        menuKey = key
        menu.x = Math.min(x, width - menu.width - look.padding)
        menu.y = Math.min(y, height - menu.height - look.padding)
    }

    function openMenuAtSelection() {
        const at = rows.findIndex(row => row.key === selectedKey)
        if (at < 0)
            return
        list.positionViewAtIndex(at, ListView.Contain)
        const item = list.itemAtIndex(at)
        const point = item ? item.mapToItem(manager, look.padding * 2, item.height) : Qt.point(look.padding * 2, list.y)
        openMenu(selectedKey, point.x, point.y)
    }

    function closeMenu() {
        menuKey = ""
    }

    function act(key) {
        const row = menuRow
        closeMenu()
        if (!row)
            return
        if (key === "kill")
            Processes.kill(row)
        else if (key === "open")
            Processes.open(row)
        else
            Processes.find(row)
    }

    function stepSelection(offset) {
        selectedKey = ProcessTable.step(rows, selectedKey, offset)
        const at = rows.findIndex(row => row.key === selectedKey)
        if (at >= 0)
            list.positionViewAtIndex(at, ListView.Contain)
    }

    onRowsChanged: if (isShown) refill()
    onIsShownChanged: {
        closeMenu()
        if (isShown)
            refill()
    }

    Keys.onPressed: event => {
        if (!isShown)
            return
        const isMenuOpen = menuKey.length > 0
        if (event.key === Qt.Key_Escape && isMenuOpen) {
            closeMenu()
        } else if (isMenuOpen && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
            menu.moveHighlight(event.key === Qt.Key_Up ? -1 : 1)
        } else if (isMenuOpen && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            menu.choose(menu.highlighted)
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            stepSelection(event.key === Qt.Key_Up ? -1 : 1)
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            pickTab(isHistory ? "processes" : "history")
        } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
            openMenuAtSelection()
        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && selectedKey.length > 0) {
            menuKey = selectedKey
            act("open")
        } else if (event.key === Qt.Key_Delete && selectedKey.length > 0 && !isHistory) {
            menuKey = selectedKey
            act("kill")
        } else {
            return
        }
        event.accepted = true
    }

    ListModel {
        id: listModel
    }

    Item {
        id: tabs
        x: manager.look.padding
        y: manager.look.padding
        width: manager.listWidth
        height: manager.look.tab

        Rectangle {
            readonly property Item current: tabRepeater.count > 0 ? tabRepeater.itemAt(manager.isHistory ? 1 : 0) : null

            x: current ? current.x : 0
            width: current ? current.width : 0
            height: parent.height
            radius: height / 2
            color: Appearance.color.accent
            scale: tabTurn.presence

            Behavior on x {
                NumberAnimation {
                    duration: Motion.pace(Motion.dashboard.taskTab)
                    easing.type: Easing.OutBack
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: Motion.pace(Motion.dashboard.taskTab)
                    easing.type: Easing.OutCubic
                }
            }

            Turn {
                id: tabTurn
                isShown: manager.isShown
                isFlipping: false
                enterEasing: Easing.OutBack
                leaveWindow: 0
            }
        }

        Row {
            id: tabRow
            height: parent.height
            spacing: manager.look.tabGap

            Repeater {
                id: tabRepeater
                model: ProcessTable.tabs

                Item {
                    id: tabItem

                    required property var modelData
                    required property int index
                    readonly property bool isCurrent: manager.tab === modelData.key

                    width: tabLabel.fullWidth + manager.look.tabPadding * 2
                    height: tabRow.height

                    TypedText {
                        id: tabLabel
                        x: manager.look.tabPadding
                        anchors.verticalCenter: parent.verticalCenter
                        target: tabItem.modelData.label
                        isShown: manager.isShown
                        holdsWidth: true
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        color: tabItem.isCurrent ? Appearance.color.ground : Appearance.color.textMuted
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: manager.pickTab(tabItem.modelData.key)
                    }
                }
            }
        }
    }

    Item {
        id: header
        x: manager.look.padding
        y: tabs.y + tabs.height + manager.look.headerGap
        width: manager.listWidth
        height: manager.look.header

        Repeater {
            model: manager.columns

            Item {
                id: headerCell

                required property var modelData
                required property int index
                readonly property bool isName: index === 0
                readonly property bool isSorted: manager.sort.key === modelData.key

                x: isName ? 0 : manager.nameWidth + (index - 1) * manager.look.cell
                width: isName ? manager.nameWidth : manager.look.cell
                height: header.height

                Turn {
                    width: parent.width
                    height: parent.height
                    isShown: manager.isShown
                    enterDelay: headerCell.index * Motion.dashboard.taskStagger
                    leaveWindow: 0

                    Text {
                        anchors.right: headerCell.isName ? undefined : parent.right
                        anchors.rightMargin: manager.look.cellPadding
                        x: headerCell.isName ? manager.look.cellPadding : 0
                        y: 0
                        text: manager.summary[headerCell.modelData.key] ?? ""
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.body
                        font.bold: true
                    }

                    Row {
                        anchors.right: headerCell.isName ? undefined : parent.right
                        anchors.rightMargin: manager.look.cellPadding
                        x: headerCell.isName ? manager.look.cellPadding : 0
                        anchors.bottom: parent.bottom
                        spacing: manager.look.sortMark

                        Text {
                            text: headerCell.modelData.label
                            color: headerCell.isSorted ? Appearance.color.accent : Appearance.color.textMuted
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.font.chip
                            font.letterSpacing: Appearance.font.labelSpacing / 2
                        }

                        Text {
                            visible: headerCell.isSorted
                            text: manager.sort.isDescending ? "▼" : "▲"
                            color: Appearance.color.accent
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.font.chip
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: manager.sortBy(headerCell.modelData.key)
                }
            }
        }
    }

    Rectangle {
        x: manager.look.padding
        y: header.y + header.height + manager.look.cellPadding
        width: manager.listWidth * divider.presence
        height: 1
        color: Appearance.color.hairline

        Turn {
            id: divider
            isShown: manager.isShown
            enterDuration: Motion.dashboard.level
            enterEasing: Easing.OutCubic
            leaveWindow: 0
        }
    }

    ListView {
        id: list
        x: manager.look.padding
        y: header.y + header.height + manager.look.cellPadding * 2
        width: manager.listWidth
        height: manager.height - y - manager.look.padding
        clip: true
        model: listModel
        boundsBehavior: Flickable.StopAtBounds
        interactive: manager.menuKey.length === 0

        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Motion.pace(Motion.dashboard.taskMove)
                easing.type: Easing.OutCubic
            }
        }

        moveDisplaced: Transition {
            NumberAnimation {
                property: "y"
                duration: Motion.pace(Motion.dashboard.taskMove)
                easing.type: Easing.OutCubic
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: Motion.pace(Motion.dashboard.taskMove)
                easing.type: Easing.OutCubic
            }
        }

        delegate: TaskRow {
            id: taskRow
            width: list.width
            columns: manager.columns
            totals: manager.totals
            nameWidth: manager.nameWidth
            isShown: manager.isShown
            isSelected: manager.selectedKey === key
            isMenuTarget: manager.menuKey === key
            onPicked: {
                manager.closeMenu()
                manager.selectedKey = key
                manager.forceActiveFocus()
            }
            onOpened: {
                manager.menuKey = key
                manager.act("open")
            }
            onMenuRequested: (x, y) => {
                const point = taskRow.mapToItem(manager, x, y)
                manager.openMenu(key, point.x, point.y)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: manager.menuKey.length > 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: manager.closeMenu()
    }

    TaskMenu {
        id: menu
        isOpen: manager.menuKey.length > 0 && manager.isShown
        canKill: !manager.isHistory
        onChosen: key => manager.act(key)
    }
}
