import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Geometry.js" as Geometry

FocusScope {
    id: menu

    property bool isOpen: false
    property var parts: []
    property bool isMirrored: false
    property bool canHandOff: false
    property bool isHandingOver: false
    property bool hasCircle: false
    property bool isQuiet: false
    readonly property bool isPresent: isOpen || burst.isActive
    readonly property string phase: burst.phase
    readonly property bool isContentShown: burst.isOpened
    readonly property bool isSendShown: isContentShown && canSend && burst.splitShare >= Motion.notifications.sendShown
    readonly property var visitor: burst.visitor
    readonly property bool isCarrying: burst.isCarrying
    property real dim: isOpen ? 1 : 0
    property string zone: "list"
    property int cursor: 0
    property int deviceIndex: -1

    readonly property var entries: Notifications.history
    readonly property var devices: Transfer.devices
    readonly property bool canSend: Transfer.isAvailable
    readonly property string appName: Transfer.appName

    readonly property var look: Appearance.notifications
    readonly property real rootX: Appearance.taskbar.margin
    readonly property real formWidth: Math.round(width * look.widthShare)
    readonly property real formRight: rootX + formWidth
    readonly property real middleY: Math.round(height / 2)
    readonly property var wallShape: canSend ? look.wall : look.wholeWall
    readonly property real listX: rootX + look.inset
    readonly property real listWidth: formWidth * look.wallOnly - look.inset * 2
    readonly property real listBottom: Math.round(height * (canSend ? look.listEnd : look.wholeListEnd))
    readonly property real sendTop: burst.splitBottom
    readonly property real lowerHeight: height - sendTop
    readonly property real devicesY: Math.round(height * look.splitAt + look.splitGap / 2 + (height * (1 - look.splitAt)) * look.devicesShare)
    readonly property real sendY: Math.round(height * look.splitAt + look.splitGap / 2 + (height * (1 - look.splitAt)) * look.sendShare)
    readonly property int sendSlots: devices.length + 2

    signal closeRequested()
    signal landed()
    signal quietRequested(bool isQuiet)
    signal appRequested()

    function edgeX(localX, itemWidth) {
        return isMirrored ? width - localX - itemWidth : localX
    }

    function wallAt(y) {
        return burst.hasWall ? burst.wallXAt(y) : burst.formRight
    }

    function zones() {
        const order = []
        if (entries.length > 0)
            order.push("list")
        order.push("actions")
        if (canSend)
            order.push("send")
        return order
    }

    function select(nextZone, index) {
        zone = nextZone
        cursor = index
    }

    function cycle(step) {
        const order = zones()
        const at = Math.max(0, order.indexOf(zone))
        select(order[(at + step + order.length) % order.length], 0)
    }

    function move(step) {
        const count = zone === "list" ? entries.length : zone === "actions" ? 2 : sendSlots
        if (count > 0)
            cursor = Math.max(0, Math.min(count - 1, cursor + step))
    }

    function entryOf(key) {
        return entries.find(entry => entry.key === key) ?? null
    }

    function syncRows() {
        const keys = entries.map(entry => entry.key)
        for (let index = rows.count - 1; index >= 0; index--) {
            if (keys.indexOf(rows.get(index).key) < 0)
                rows.remove(index)
        }
        for (let index = 0; index < entries.length; index++) {
            const entry = entries[index]
            if (index < rows.count && rows.get(index).key === entry.key)
                continue
            rows.insert(index, { key: entry.key, appName: entry.appName, desktopEntry: entry.desktopEntry, summary: entry.summary, body: entry.body, icon: entry.icon })
        }
    }

    function openEntry(entry) {
        if (!entry)
            return
        Notifications.openEntry(entry)
        closeRequested()
    }

    function forgetEntry(entry) {
        if (entry)
            Notifications.forget(entry)
    }

    function clearAll() {
        Notifications.clear()
        select(zones()[0], 0)
    }

    function chooseDevice(index) {
        deviceIndex = deviceIndex === index ? -1 : index
    }

    function send() {
        const peer = deviceIndex >= 0 && deviceIndex < devices.length ? devices[deviceIndex].peer : ""
        closeRequested()
        Transfer.send(peer)
    }

    function press() {
        if (zone === "list")
            openEntry(entries[cursor])
        else if (zone === "actions" && cursor === 0)
            clearAll()
        else if (zone === "actions")
            quietRequested(!isQuiet)
        else if (cursor < devices.length)
            chooseDevice(cursor)
        else if (cursor === devices.length)
            send()
        else
            appRequested()
    }

    onEntriesChanged: {
        syncRows()
        if (zone === "list" && cursor >= entries.length)
            select(entries.length > 0 ? "list" : "actions", Math.max(0, entries.length - 1))
    }
    onIsOpenChanged: {
        if (!isOpen)
            return
        deviceIndex = -1
        select(zones()[0], 0)
        listView.positionViewAtBeginning()
        forceActiveFocus()
    }

    Component.onCompleted: syncRows()

    ListModel {
        id: rows
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            menu.closeRequested()
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            menu.press()
            break
        case Qt.Key_Tab:
            menu.cycle(1)
            break
        case Qt.Key_Backtab:
            menu.cycle(-1)
            break
        case Qt.Key_Up:
            if (menu.zone === "list")
                menu.move(-1)
            else
                menu.cycle(-1)
            break
        case Qt.Key_Down:
            if (menu.zone === "list" && menu.cursor < menu.entries.length - 1)
                menu.move(1)
            else
                menu.cycle(1)
            break
        case Qt.Key_Left:
            menu.move(menu.isMirrored ? 1 : -1)
            break
        case Qt.Key_Right:
            menu.move(menu.isMirrored ? -1 : 1)
            break
        case Qt.Key_Delete:
        case Qt.Key_Backspace:
            if (menu.zone === "list")
                menu.forgetEntry(menu.entries[menu.cursor])
            break
        default:
            return
        }
        event.accepted = true
    }

    Behavior on dim {
        SequentialAnimation {
            PauseAnimation { duration: Motion.pace(menu.isOpen ? 0 : Motion.burst.leaveHold) }
            NumberAnimation {
                duration: Motion.pace(menu.isOpen ? Motion.notifications.dim : Motion.notifications.dimOut)
                easing.type: menu.isOpen ? Easing.OutQuad : Easing.InQuad
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.color.shadow
        opacity: menu.dim * menu.look.dim
    }

    MouseArea {
        anchors.fill: parent
        enabled: menu.isOpen
        onClicked: menu.closeRequested()
    }

    MouseArea {
        x: menu.edgeX(0, width)
        width: menu.formRight
        height: menu.height
        enabled: menu.isOpen
        onClicked: menu.forceActiveFocus()
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: burst.isActive
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: menu.look.melt

        Item {
            id: liquidFrame
            parent: liquid.shapes
            anchors.fill: parent
            transform: Upright {
                isMirrored: menu.isMirrored
                axis: liquid.width / 2
            }

            Burst {
                id: burst
                label: "notifications burst"
                isShown: menu.isOpen
                parts: menu.parts
                rootX: menu.rootX
                seedX: menu.rootX + Appearance.taskbar.thickness / 2
                seedY: menu.middleY
                formWidth: menu.formWidth
                formHeight: menu.height
                leftCorner: menu.look.rootCorner
                rightCorner: menu.look.corner
                edgePad: menu.look.melt
                screenHeight: menu.height
                canHandOff: menu.canHandOff
                isHandingOver: menu.isHandingOver
                hasCircle: menu.hasCircle
                hasSteps: false
                splitAt: menu.canSend ? menu.look.splitAt : 0
                splitGap: menu.look.splitGap
                wall: menu.wallShape.map(point => Qt.point((point[0] - 1) * menu.formWidth, point[1]))
                onLanded: menu.landed()
            }
        }
    }

    Item {
        id: listClip

        readonly property real formLeft: burst.form.x - burst.form.width / 2

        x: menu.edgeX(Math.max(0, formLeft), width)
        y: 0
        width: Math.max(0, Math.min(menu.formRight, burst.form.width))
        height: menu.height
        opacity: burst.isLeaving ? 1 - Geometry.smooth(Geometry.clampUnit(burst.exit / Motion.burst.leaveFade)) : 1
        clip: true

        Item {
            x: -listClip.x
            width: menu.width
            height: menu.height

            ListView {
                id: listView
                x: menu.edgeX(menu.listX, width)
                y: menu.look.top
                width: menu.listWidth
                height: menu.listBottom - y
                clip: true
                spacing: 0
                boundsBehavior: Flickable.DragOverBounds
                model: rows
                currentIndex: menu.zone === "list" ? menu.cursor : -1
                onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: NotificationRow {
                    required property string key
                    required property string appName
                    required property string desktopEntry
                    required property string summary
                    required property string body
                    required property string icon
                    required property int index
                    width: listView.width
                    entry: ({ key: key, appName: appName, desktopEntry: desktopEntry, summary: summary, body: body, icon: icon })
                    isShown: menu.isContentShown
                    isSelected: menu.zone === "list" && menu.cursor === index
                    enterDelay: Math.min(index, menu.look.staggerRows) * Motion.notifications.stagger
                    onActivated: menu.openEntry(menu.entryOf(key))
                    onForgotten: Qt.callLater(menu.forgetEntry, menu.entryOf(key))
                    onPointed: menu.select("list", index)
                }
            }

            Turn {
                x: menu.edgeX(menu.listX, width)
                y: menu.look.top + (menu.look.row - height) / 2
                isShown: menu.isContentShown && menu.entries.length === 0
                enterDuration: Motion.notifications.rowEnter
                leaveWindow: 0

                TypedText {
                    target: "NOTHING NEW"
                    isShown: parent.isShown
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    leaveBudget: Motion.notifications.rowLeave
                    color: Appearance.color.textFaint
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }

            Row {
                id: deviceRow
                x: menu.edgeX(menu.listX, width)
                y: menu.devicesY
                spacing: menu.look.deviceGap
                layoutDirection: menu.isMirrored ? Qt.RightToLeft : Qt.LeftToRight
                visible: menu.canSend

                Repeater {
                    model: menu.devices

                    Turn {
                        id: device
                        required property var modelData
                        required property int index
                        readonly property bool isChosen: menu.deviceIndex === index
                        readonly property bool isSelected: menu.zone === "send" && menu.cursor === index
                        width: menu.look.device
                        height: menu.look.device + menu.look.deviceName * 2
                        isShown: menu.isSendShown
                        enterDelay: (index + 1) * Motion.notifications.stagger
                        enterEasing: Easing.OutBack
                        leaveWindow: 0

                        Press {
                            target: device
                            isPressed: deviceArea.pressed
                            depth: Motion.press.glyph
                        }

                        Rectangle {
                            width: menu.look.device
                            height: menu.look.device
                            radius: width / 2
                            color: device.isChosen ? Appearance.color.accent : Appearance.color.wash
                            border.width: device.isSelected || deviceArea.containsMouse ? menu.look.ring : 0
                            border.color: Appearance.color.accent

                            Text {
                                anchors.centerIn: parent
                                text: device.modelData.name.charAt(0).toUpperCase()
                                color: device.isChosen ? Appearance.color.ground : Appearance.color.text
                                font.family: Appearance.font.mono
                                font.pixelSize: Appearance.font.body
                                font.bold: true
                            }
                        }

                        Text {
                            y: menu.look.device + menu.look.deviceName / 2
                            width: menu.look.device
                            horizontalAlignment: Text.AlignHCenter
                            text: device.modelData.name.toUpperCase()
                            elide: Text.ElideRight
                            color: device.isChosen ? Appearance.color.accent : Appearance.color.textMuted
                            font.family: Appearance.font.mono
                            font.pixelSize: menu.look.deviceName
                            font.letterSpacing: Appearance.font.labelSpacing
                        }

                        MouseArea {
                            id: deviceArea
                            width: menu.look.device
                            height: menu.look.device
                            enabled: menu.isSendShown
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                menu.select("send", device.index)
                                menu.chooseDevice(device.index)
                            }
                        }
                    }
                }

                Turn {
                    visible: menu.devices.length === 0
                    height: menu.look.device
                    width: noDevices.implicitWidth
                    isShown: menu.isSendShown && menu.devices.length === 0
                    leaveWindow: 0

                    TypedText {
                        id: noDevices
                        anchors.verticalCenter: parent.verticalCenter
                        target: "NO DEVICES, " + menu.appName + " PICKS"
                        isShown: parent.isShown
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        leaveBudget: Motion.notifications.rowLeave
                        color: Appearance.color.textFaint
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }
                }
            }

            Turn {
                id: sendButton

                readonly property bool isSelected: menu.zone === "send" && menu.cursor === menu.devices.length

                x: menu.edgeX(menu.listX, width)
                y: menu.sendY
                width: menu.look.sendWidth
                height: menu.look.sendHeight
                visible: menu.canSend
                isShown: menu.isSendShown
                enterDelay: (menu.devices.length + 1) * Motion.notifications.stagger
                enterEasing: Easing.OutBack
                leaveWindow: 0

                Press {
                    target: sendButton
                    isPressed: sendArea.pressed
                    depth: Motion.press.glyph
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: sendArea.containsMouse || sendButton.isSelected ? Appearance.color.accent : "transparent"
                    border.width: 1
                    border.color: Appearance.color.hairline
                }

                TypedText {
                    anchors.centerIn: parent
                    target: "SEND"
                    isShown: sendButton.isShown
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    leaveBudget: Motion.notifications.rowLeave
                    color: sendArea.containsMouse || sendButton.isSelected ? Appearance.color.ground : Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }

                MouseArea {
                    id: sendArea
                    anchors.fill: parent
                    enabled: menu.isSendShown && !Transfer.isPicking
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: menu.send()
                }
            }
        }
    }

    Repeater {
        id: bubbles
        model: [
            { key: "clear", glyph: "trash", share: menu.look.bubbleShares[0], isLower: false },
            { key: "quiet", glyph: "muted", share: menu.look.bubbleShares[1], isLower: false },
            { key: "app", glyph: "settings", share: menu.look.gearShare, isLower: true }
        ]

        Turn {
            id: bubble

            required property var modelData
            required property int index
            readonly property real centerY: Math.round(menu.height * modelData.share)
            readonly property real size: menu.look.bubble * presence
            readonly property real restX: menu.wallAt(centerY) + menu.look.bubbleReach + menu.look.bubble / 2
            readonly property real liquidX: menu.wallAt(centerY) + (restX - menu.wallAt(centerY)) * presence
            readonly property bool isLiquid: size > 0.5
            readonly property bool isSelected: modelData.isLower ? menu.zone === "send" && menu.cursor === menu.devices.length + 1 : menu.zone === "actions" && menu.cursor === index
            readonly property bool isActive: modelData.key === "quiet" && menu.isQuiet

            x: menu.edgeX(liquidX - menu.look.bubble / 2, width)
            y: centerY - height / 2
            width: menu.look.bubble
            height: menu.look.bubble
            isShown: modelData.isLower ? menu.isSendShown : menu.isContentShown
            isFlipping: false
            enterDelay: (modelData.isLower ? menu.devices.length + 2 : index + 1) * Motion.notifications.bubbleStagger
            enterDuration: Motion.notifications.bud
            leaveDuration: Motion.notifications.budOut
            enterEasing: Easing.OutBack
            leaveWindow: 0

            LiquidShape {
                parent: liquidFrame
                visible: burst.isActive && bubble.isLiquid
                width: bubble.size
                height: width
                x: bubble.liquidX - width / 2
                y: bubble.centerY - height / 2
            }

            Rectangle {
                anchors.centerIn: parent
                width: bubble.size
                height: width
                radius: width / 2
                color: bubble.isActive ? Appearance.color.accent : "transparent"
                border.width: bubble.isSelected || bubbleArea.containsMouse ? menu.look.ring : 0
                border.color: Appearance.color.accent
            }

            Glyph {
                anchors.centerIn: parent
                width: menu.look.bubbleGlyph
                height: width
                opacity: bubble.presence
                name: bubble.modelData.glyph
                color: bubble.isActive ? Appearance.color.ground : bubbleArea.containsMouse && bubble.modelData.key === "clear" ? Appearance.color.danger : Appearance.color.text
            }

            TypedText {
                visible: bubble.modelData.isLower
                x: menu.isMirrored ? -implicitWidth - menu.look.appGap : bubble.width + menu.look.appGap
                anchors.verticalCenter: parent.verticalCenter
                target: menu.appName
                isShown: bubble.isShown && bubble.modelData.isLower
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                leaveBudget: Motion.notifications.budOut
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }

            Press {
                target: bubble
                isPressed: bubbleArea.pressed
                depth: Motion.press.glyph
            }

            MouseArea {
                id: bubbleArea
                anchors.fill: parent
                enabled: bubble.isShown && bubble.presence > 0.5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (bubble.modelData.key === "clear")
                        menu.clearAll()
                    else if (bubble.modelData.key === "quiet")
                        menu.quietRequested(!menu.isQuiet)
                    else
                        menu.appRequested()
                }
            }
        }
    }
}
