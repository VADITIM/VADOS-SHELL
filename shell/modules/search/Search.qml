import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Geometry.js" as Geometry

FocusScope {
    id: search

    property bool isOpen: false
    property var favoriteIds: []
    property var hiddenIds: []
    property bool isShowingHidden: false
    property var menuApp: null
    property var pinnedOrder: []
    property string syncedQuery: ""
    property point menuAt: Qt.point(0, 0)
    property string profileName: ""
    property string profilePicture: ""
    property var parts: []
    property bool shouldStream: true
    property bool isMirrored: false
    property bool canHandOff: false
    property bool isHandingOver: false
    property bool hasCircle: false
    readonly property bool isPresent: isOpen || burst.isActive || profile.isActive
    readonly property string phase: burst.phase
    readonly property bool isContentShown: burst.isOpened
    readonly property var visitor: burst.visitor
    readonly property bool isCarrying: burst.isCarrying
    property real dim: isOpen ? 1 : 0
    property real bud: burst.isOpened ? 1 : 0
    property string zone: "found"
    property int cursor: 0

    readonly property string query: input.text
    readonly property bool isSearching: query.trim().length > 0
    readonly property var results: (isSearching ? Apps.search(query) : Apps.recent()).filter(app => isShowingHidden || !isHidden(app))
    readonly property var best: results.length > 0 ? results[0] : null
    readonly property var listApps: isSearching ? results.slice(1) : pinnedFirst(results.slice(1))

    readonly property var look: Appearance.search
    readonly property real rootX: Appearance.taskbar.margin
    readonly property real formWidth: Math.round(width * look.widthShare)
    readonly property real formRight: rootX + formWidth
    readonly property real listWidth: formWidth - look.inset * 2
    readonly property real fieldY: height - look.top - look.hiddenRow - look.fieldHeight
    readonly property real listX: rootX + look.inset
    readonly property real middleY: Math.round(height / 2)
    readonly property real foundRadius: look.found / 2
    readonly property real foundCenterX: rootX + look.foundX
    readonly property real foundCenterY: Math.round(height * look.foundShare)

    readonly property real presence: bud * Math.min(1, burst.wallShare)
    readonly property var wallOutline: burst.wallOutline
    readonly property real wallReach: wallOutline.length > 0 ? Math.max(...wallOutline.map(point => point.x)) : burst.formRight
    readonly property var settledWall: look.wall.map(point => Qt.point(foundCenterX + point[0] * foundRadius, point[1] * height))
    readonly property var wallBands: settledWall.slice(1).map((point, index) => Qt.rect(0, settledWall[index].y, Math.min(point.x, settledWall[index].x), point.y - settledWall[index].y))
    readonly property var profileLook: look.profile
    readonly property real profileY: Math.round(height * profileLook.share)
    readonly property real profileTop: profileY - Math.max(profile.columnHeight, profileLook.blob) / 2
    readonly property real profileWall: wallReachBetween(profileTop, profileY + Math.max(profile.columnHeight, profileLook.blob) / 2)
    readonly property real profileButtonX: profileWall + profileLook.gap + profileLook.button / 2
    readonly property real profileX: profileButtonX + profileLook.button / 2 + profileLook.blobGap + profileLook.blob / 2

    signal closeRequested()
    signal landed()
    signal favoriteToggled(string appId)
    signal hiddenToggled(string appId)
    signal profileRequested()

    function edgeX(localX, itemWidth) {
        return isMirrored ? width - localX - itemWidth : localX
    }

    function wallAt(pointY) {
        const wall = settledWall
        for (let index = 1; index < wall.length; index++) {
            if (wall[index].y >= pointY) {
                const span = Math.max(1, wall[index].y - wall[index - 1].y)
                return Geometry.mix(wall[index - 1].x, wall[index].x, Geometry.clampUnit((pointY - wall[index - 1].y) / span))
            }
        }
        return wall.length > 0 ? wall[wall.length - 1].x : formRight
    }

    function wallReachBetween(top, bottom) {
        const inside = settledWall.filter(point => point.y > top && point.y < bottom).map(point => point.x)
        return Math.max(wallAt(top), wallAt(bottom), ...inside)
    }

    function isHidden(app) {
        return (hiddenIds || []).indexOf(app.id) >= 0
    }

    function openMenu(app, at) {
        if (!app)
            return
        menuApp = app
        menuAt = at
    }

    function openMenuForSelection() {
        const app = selectedApp()
        if (zone === "list" && listView.currentItem) {
            const row = listView.currentItem
            openMenu(app, row.mapToItem(search, row.width / 2, row.height / 2))
            return
        }
        openMenu(app, Qt.point(edgeX(foundCenterX, 0), foundCenterY))
    }

    function closeMenu() {
        menuApp = null
    }

    function chooseFromMenu(key) {
        const app = menuApp
        closeMenu()
        if (!app)
            return
        if (key === "favorite")
            favoriteToggled(app.id)
        else
            hiddenToggled(app.id)
    }

    function pinnedFirst(apps) {
        const pinned = pinnedOrder
        return apps.filter(app => pinned.indexOf(app.id) >= 0).concat(apps.filter(app => pinned.indexOf(app.id) < 0))
    }

    function syncList(isReset) {
        const ids = listApps.map(app => app.id)
        if (isReset) {
            listModel.clear()
            ids.forEach(appId => listModel.append({ appId: appId }))
            return
        }
        for (let index = listModel.count - 1; index >= 0; index--) {
            if (ids.indexOf(listModel.get(index).appId) < 0)
                listModel.remove(index)
        }
        for (let index = 0; index < ids.length; index++) {
            if (index < listModel.count && listModel.get(index).appId === ids[index])
                continue
            let found = -1
            for (let later = index + 1; later < listModel.count; later++) {
                if (listModel.get(later).appId === ids[index]) {
                    found = later
                    break
                }
            }
            if (found >= 0)
                listModel.move(found, index, 1)
            else
                listModel.insert(index, { appId: ids[index] })
        }
    }

    function requestProfile() {
        profileRequested()
        closeRequested()
    }

    function selectedApp() {
        if (zone === "list")
            return listApps[cursor] ?? null
        return best
    }

    function select(nextZone, index) {
        zone = nextZone
        cursor = index
    }

    function launch(app) {
        if (!app)
            return
        Apps.launch(app.id)
        closeRequested()
    }

    function enter(nextZone) {
        const count = nextZone === "list" ? listApps.length : nextZone === "profile" ? profile.count : 1
        if (count > 0)
            select(nextZone, 0)
    }

    function cycle(step) {
        const order = ["list", "found", "profile"].filter(name => name !== "list" || listApps.length > 0)
        const at = order.indexOf(zone)
        select(order[(at + step + order.length) % order.length], 0)
    }

    function move(stepX, stepY) {
        const towardFar = isMirrored ? -stepX : stepX
        if (zone === "found") {
            if (towardFar < 0 || stepY > 0)
                enter("list")
            else if (towardFar > 0 || stepY < 0)
                enter("profile")
            return
        }
        if (zone === "profile") {
            if (towardFar < 0)
                select("found", 0)
            else if (stepY !== 0)
                cursor = Math.max(0, Math.min(profile.count - 1, cursor + stepY))
            return
        }
        if (zone === "list") {
            if (towardFar > 0)
                select("found", 0)
            else if (stepY !== 0)
                cursor = Math.max(0, Math.min(listApps.length - 1, cursor + stepY))
        }
    }

    function rowRoom(rowTop) {
        const rowBottom = rowTop + look.row
        const reach = foundRadius + look.lobeGap
        const distance = Math.max(0, foundCenterY - rowBottom, rowTop - foundCenterY)
        if (distance >= reach)
            return listWidth
        const limit = Math.min(listX + listWidth, foundCenterX - Math.sqrt(reach * reach - distance * distance))
        return listWidth - (listX + listWidth - limit) * presence
    }

    function rowFade(rowTop) {
        return Math.max(0, Math.min(1, (rowTop - look.top + look.topFade) / look.topFade))
    }

    function keepRowShown(index) {
        const rowY = index * look.row
        const lowest = rowY + look.row - listView.height
        const highest = rowY
        listDrift.glideTo(Math.max(lowest, Math.min(highest, listDrift.destination())))
    }

    function revealDelay(localX, row) {
        if (isSearching)
            return row * Motion.search.settledStagger
        return Math.round((localX - rootX) * Motion.search.ripple) + row * Motion.pill.elementStagger
    }

    onQueryChanged: {
        pinnedOrder = (favoriteIds || []).slice()
        select("found", 0)
    }
    onListAppsChanged: {
        syncList(query !== syncedQuery)
        syncedQuery = query
        if (zone === "list" && cursor >= listApps.length)
            select(listApps.length > 0 ? "list" : "found", Math.max(0, listApps.length - 1))
    }
    onIsOpenChanged: {
        closeMenu()
        if (isOpen) {
            input.text = ""
            isShowingHidden = false
            pinnedOrder = (favoriteIds || []).slice()
            syncList(true)
            select("found", 0)
            input.forceActiveFocus()
        }
    }

    Behavior on dim {
        SequentialAnimation {
            PauseAnimation { duration: Motion.pace(search.isOpen ? 0 : Motion.burst.leaveHold) }
            NumberAnimation {
                duration: Motion.pace(search.isOpen ? Motion.search.dim : Motion.search.dimOut)
                easing.type: search.isOpen ? Easing.OutQuad : Easing.InQuad
            }
        }
    }

    Behavior on bud {
        NumberAnimation {
            duration: Motion.pace(burst.isOpened ? Motion.search.bud : Motion.search.budOut)
            easing.type: burst.isOpened ? Easing.OutBack : Easing.InQuad
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.color.shadow
        opacity: search.dim * search.look.dim
    }

    MouseArea {
        anchors.fill: parent
        enabled: search.isOpen
        onClicked: search.closeRequested()
    }

    Repeater {
        model: search.wallBands

        MouseArea {
            required property rect modelData
            x: search.edgeX(modelData.x, modelData.width)
            y: modelData.y
            width: modelData.width
            height: modelData.height
            enabled: search.isOpen
            onClicked: input.forceActiveFocus()
        }
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: burst.isActive || profile.isActive
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: search.look.melt

        Item {
            id: shapeRoot
            parent: liquid.shapes
            anchors.fill: parent
            transform: Upright {
                isMirrored: search.isMirrored
                axis: liquid.width / 2
            }

            Burst {
                id: burst
                label: "search burst"
                isShown: search.isOpen
                parts: search.parts
                shouldStream: search.shouldStream
                rootX: search.rootX
                seedX: search.rootX + Appearance.taskbar.thickness / 2
                seedY: search.middleY
                formWidth: search.formWidth
                formHeight: search.height
                leftCorner: search.look.rootCorner
                rightCorner: search.look.corner
                edgePad: search.look.melt
                screenHeight: search.height
                canHandOff: search.canHandOff
                isHandingOver: search.isHandingOver
                hasCircle: search.hasCircle
                hasSteps: false
                wall: search.look.wall.map(point => Qt.point(search.foundCenterX + point[0] * search.foundRadius - search.formRight, point[1]))
                onLanded: {
                    input.text = ""
                    search.landed()
                }
            }

            LiquidShape {
                visible: burst.isActive && width > 0.5
                x: search.wallReach + search.look.nameReach
                y: search.foundCenterY - height / 2
                width: foundCard.nameSpan
                height: foundCard.nameThickness
            }
        }
    }

    Item {
        id: bodyClip

        readonly property real formLeft: burst.form.x - burst.form.width / 2

        x: search.edgeX(formLeft, width)
        y: burst.form.y - burst.form.height / 2
        width: Math.max(0, burst.form.width)
        height: Math.max(0, burst.form.height)
        opacity: burst.isLeaving ? 1 - Geometry.smooth(Geometry.clampUnit(burst.exit / Motion.burst.leaveFade)) : 1
        clip: true

        Item {
            x: -bodyClip.x
            y: -bodyClip.y
            width: search.width
            height: search.height

            ListView {
                id: listView
                x: search.edgeX(search.listX, width)
                y: search.look.top
                width: search.listWidth
                height: search.fieldY - search.look.sectionGap - y
                clip: true
                boundsBehavior: Flickable.DragOverBounds
                model: ListModel {
                    id: listModel
                }
                currentIndex: search.zone === "list" ? search.cursor : -1
                onCurrentIndexChanged: if (currentIndex >= 0) search.keepRowShown(currentIndex)

                Drift {
                    id: listDrift
                }

                delegate: ResultRow {
                    required property string appId
                    required property int index
                    readonly property var entry: Apps.byId(appId)
                    readonly property real rowTop: listView.y + y - listView.contentY
                    width: listView.width
                    fade: search.rowFade(rowTop)
                    room: search.rowRoom(rowTop)
                    isMirrored: search.isMirrored
                    app: entry
                    isShown: search.isContentShown && entry !== null
                    isSelected: search.zone === "list" && search.cursor === index
                    isFavorite: search.favoriteIds.indexOf(appId) >= 0
                    isHidden: (search.hiddenIds || []).indexOf(appId) >= 0
                    enterDelay: search.revealDelay(search.listX, index)
                    onActivated: search.launch(entry)
                    onMenuRequested: at => search.openMenu(entry, at)
                    onPointed: search.select("list", index)
                }
            }

            Turn {
                id: field
                x: search.edgeX(search.rootX + search.look.inset, width)
                y: search.fieldY
                width: search.listWidth
                height: search.look.fieldHeight
                isShown: search.isContentShown
                enterDelay: search.revealDelay(search.rootX + search.look.inset, 0)
                enterDuration: Motion.search.tileEnter
                enterEasing: Easing.OutBack
                leaveWindow: 0

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Appearance.color.wash
                    border.width: 1
                    border.color: input.activeFocus ? Appearance.color.hairline : "transparent"
                }

                TextInput {
                    id: input
                    x: search.look.fieldPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - count.width - search.look.fieldPadding * 3 - Appearance.taskbar.glyph
                    focus: true
                    clip: true
                    color: Appearance.color.text
                    selectionColor: Appearance.color.accent
                    selectedTextColor: Appearance.color.ground
                    font.family: Appearance.font.mono
                    font.pixelSize: search.look.fieldText

                    Keys.onPressed: event => {
                        if (search.menuApp !== null) {
                            switch (event.key) {
                            case Qt.Key_Up:
                            case Qt.Key_Backtab:
                                appMenu.moveHighlight(-1)
                                break
                            case Qt.Key_Down:
                            case Qt.Key_Tab:
                                appMenu.moveHighlight(1)
                                break
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                                search.chooseFromMenu(appMenu.actions[appMenu.highlighted].key)
                                break
                            default:
                                search.closeMenu()
                                if (event.key !== Qt.Key_Escape && event.key !== Qt.Key_Menu)
                                    return
                            }
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
                            search.isShowingHidden = !search.isShowingHidden
                            event.accepted = true
                            return
                        }
                        switch (event.key) {
                        case Qt.Key_Menu:
                            if (search.zone !== "profile")
                                search.openMenuForSelection()
                            break
                        case Qt.Key_Escape:
                            if (input.text.length > 0)
                                input.text = ""
                            else
                                search.closeRequested()
                            break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (search.zone === "profile")
                                profile.activate(search.cursor)
                            else
                                search.launch(search.selectedApp())
                            break
                        case Qt.Key_Tab:
                            search.cycle(1)
                            break
                        case Qt.Key_Backtab:
                            search.cycle(-1)
                            break
                        case Qt.Key_Left:
                            search.move(-1, 0)
                            break
                        case Qt.Key_Right:
                            search.move(1, 0)
                            break
                        case Qt.Key_Up:
                            search.move(0, -1)
                            break
                        case Qt.Key_Down:
                            search.move(0, 1)
                            break
                        default:
                            return
                        }
                        event.accepted = true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SEARCH"
                        visible: input.text.length === 0
                        color: Appearance.color.textFaint
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }
                }

                Text {
                    id: count
                    anchors.right: glyph.left
                    anchors.rightMargin: search.look.fieldPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: search.isSearching ? String(search.results.length) : ""
                    color: Appearance.color.textFaint
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }

                Glyph {
                    id: glyph
                    anchors.right: parent.right
                    anchors.rightMargin: search.look.fieldPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: Appearance.taskbar.glyph
                    height: Appearance.taskbar.glyph
                    name: "search"
                    color: search.isSearching ? Appearance.color.accent : Appearance.color.textMuted
                }
            }

            Turn {
                id: hiddenToggle
                x: search.edgeX(search.listX + search.look.fieldPadding, width)
                y: search.fieldY + search.look.fieldHeight + (search.look.top + search.look.hiddenRow - height) / 2
                width: hiddenLabel.implicitWidth
                height: hiddenLabel.implicitHeight
                isShown: search.isContentShown
                enterDelay: search.revealDelay(search.listX, 1)
                leaveWindow: 0

                Text {
                    id: hiddenLabel
                    text: (search.hiddenIds || []).length > 0 ? "HIDDEN " + search.hiddenIds.length : "HIDDEN"
                    color: search.isShowingHidden ? Appearance.color.accent : hiddenArea.containsMouse ? Appearance.color.textMuted : Appearance.color.textFaint
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.hoverIn)
                        }
                    }
                }

                MouseArea {
                    id: hiddenArea
                    anchors.fill: parent
                    anchors.margins: -search.look.fieldPadding / 2
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: search.isShowingHidden = !search.isShowingHidden
                }
            }
        }
    }

    FoundCard {
        id: foundCard
        x: search.edgeX(search.foundCenterX - width / 2, width)
        y: search.foundCenterY - height / 2
        isMirrored: search.isMirrored
        nameX: search.wallReach - search.foundCenterX + search.foundRadius + search.look.nameReach
        app: search.best
        isSearching: search.isSearching
        isShown: search.isContentShown
        isSelected: search.zone === "found"
        enterDelay: search.revealDelay(search.foundCenterX, 1)
        onActivated: search.launch(app)
        onMenuRequested: at => search.openMenu(search.best, at)
        onPointed: search.select("found", 0)
    }

    ProfileBlob {
        id: profile
        anchors.fill: parent
        isWanted: search.isOpen && burst.isCarrying && !burst.isLeaving
        isMirrored: search.isMirrored
        liquidParent: shapeRoot
        centerX: search.profileX
        centerY: search.profileY
        buttonX: search.profileButtonX
        homeX: search.rootX + Appearance.taskbar.thickness / 2
        homeY: search.middleY
        edgeY: Math.round(search.height * search.profileLook.throwEdge)
        apexY: search.profileLook.throwApexY
        riseX: search.profileLook.enterApexX
        riseY: search.height + search.profileLook.enterApexY
        name: search.profileName
        picture: search.profilePicture
        selected: search.zone === "profile" ? search.cursor : -1
        onPointed: index => search.select("profile", index)
        onProfileRequested: search.requestProfile()
    }

    MouseArea {
        anchors.fill: parent
        enabled: search.menuApp !== null
        acceptedButtons: Qt.AllButtons
        onPressed: search.closeMenu()
    }

    AppMenu {
        id: appMenu
        x: Math.max(0, Math.min(search.width - width, search.menuAt.x))
        y: Math.max(0, Math.min(search.height - height, search.menuAt.y))
        isOpen: search.menuApp !== null && search.isOpen
        isFavorite: search.menuApp !== null && search.favoriteIds.indexOf(search.menuApp.id) >= 0
        isHidden: search.menuApp !== null && search.isHidden(search.menuApp)
        onChosen: key => search.chooseFromMenu(key)
    }
}
