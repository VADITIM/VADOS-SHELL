import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.config
import qs.services
import qs.components

FocusScope {
    id: search

    property bool isOpen: false
    property var favoriteIds: []
    property string profileName: ""
    property string profilePicture: ""
    property var parts: []
    property bool isMirrored: false
    property bool canHandOff: false
    readonly property bool isPresent: isOpen || burst.isActive
    readonly property string phase: burst.phase
    readonly property bool isContentShown: burst.isOpened
    readonly property var visitor: burst.visitor
    property real dim: isOpen ? 1 : 0
    property real bud: burst.isOpened ? 1 : 0
    property string zone: "found"
    property int cursor: 0

    readonly property string query: input.text
    readonly property bool isSearching: query.trim().length > 0
    readonly property var results: isSearching ? Apps.search(query) : Apps.recent()
    readonly property var best: results.length > 0 ? results[0] : null
    readonly property var listApps: results.slice(1)
    readonly property var favorites: (favoriteIds || []).map(appId => Apps.byId(appId)).filter(app => app !== null)

    readonly property var look: Appearance.search
    readonly property real rootX: Appearance.taskbar.margin
    readonly property real formWidth: Math.round(width * look.widthShare)
    readonly property real formRight: rootX + formWidth
    readonly property real cellWidth: look.tile + look.tileGap
    readonly property real cellHeight: look.tile + look.label + look.tileGap
    readonly property real listWidth: formWidth - look.inset * 2
    readonly property real fieldY: height - look.top - look.fieldHeight
    readonly property real favoritesHeight: cellHeight * look.favoriteRows - look.tileGap
    readonly property real listLead: favoritesHeight + look.sectionGap
    readonly property int favoriteColumns: Math.max(look.favoriteColumns, Math.ceil(favorites.length / look.favoriteRows))
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
    readonly property real maskTop: wallOutline.length === 0 ? 0 : wallOutline[0].y - look.wallOverhang * burst.flare
    readonly property real maskBottom: wallOutline.length === 0 ? 0 : wallOutline[wallOutline.length - 1].y + look.wallOverhang * burst.flare
    readonly property var maskOutline: wallOutline.length === 0 ? [] : [Qt.point(-look.wallOverhang, maskTop), Qt.point(wallOutline[0].x, maskTop)]
        .concat(wallOutline, [Qt.point(wallOutline[wallOutline.length - 1].x, maskBottom), Qt.point(-look.wallOverhang, maskBottom)])

    signal closeRequested()
    signal landed()
    signal favoriteToggled(string appId)

    function edgeX(localX, itemWidth) {
        return isMirrored ? width - localX - itemWidth : localX
    }

    function selectedApp() {
        if (zone === "list")
            return listApps[cursor] ?? null
        if (zone === "fav")
            return favorites[cursor] ?? null
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
        const count = nextZone === "list" ? listApps.length : nextZone === "fav" ? favorites.length : 1
        if (count > 0)
            select(nextZone, 0)
    }

    function cycle(step) {
        const order = ["list", "found", "fav"].filter(name => name === "found" || (name === "list" ? listApps.length : favorites.length) > 0)
        const at = order.indexOf(zone)
        select(order[(at + step + order.length) % order.length], 0)
    }

    function move(stepX, stepY) {
        const towardFar = isMirrored ? -stepX : stepX
        if (zone === "found") {
            if (towardFar < 0 || stepY > 0)
                enter("list")
            else if (stepY < 0)
                enter("fav")
            return
        }
        if (zone === "list") {
            if (towardFar > 0)
                select("found", 0)
            else if (stepY < 0 && cursor === 0)
                enter("fav")
            else if (stepY !== 0)
                cursor = Math.max(0, Math.min(listApps.length - 1, cursor + stepY))
            return
        }
        const columns = favoriteColumns
        if (stepY > 0 && cursor + columns >= favorites.length) {
            enter("list")
            return
        }
        const next = cursor + towardFar + stepY * columns
        if (next >= 0 && next < favorites.length)
            cursor = next
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
        return Math.max(0, Math.min(1, (rowTop - look.top) / listLead))
    }

    function keepFavoriteShown(index) {
        const column = index % favoriteColumns
        const start = favoriteView.lead + column * cellWidth
        const shown = isMirrored ? favoriteView.contentWidth - start - cellWidth : start
        const lowest = shown + cellWidth - favoriteView.width
        const highest = shown - favoriteView.lead
        favoriteView.contentX = Math.max(0, Math.max(lowest, Math.min(highest, favoriteView.contentX)))
    }

    function keepRowShown(index) {
        const rowY = index * look.row
        const lowest = rowY + look.row - listView.height
        const highest = rowY - listLead
        listView.contentY = Math.max(lowest, Math.min(highest, listView.contentY))
    }

    function revealDelay(localX, row) {
        if (isSearching)
            return row * Motion.search.settledStagger
        return Math.round((localX - rootX) * Motion.search.ripple) + row * Motion.pill.elementStagger
    }

    onResultsChanged: select("found", 0)
    onFavoritesChanged: {
        if (zone === "fav" && cursor >= favorites.length)
            select(favorites.length > 0 ? "fav" : "found", Math.max(0, favorites.length - 1))
    }
    onIsOpenChanged: {
        if (isOpen) {
            input.text = ""
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
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: search.look.melt

        Item {
            parent: liquid.shapes
            anchors.fill: parent
            transform: Upright {
                isMirrored: search.isMirrored
                axis: liquid.width / 2
            }

            Burst {
                id: burst
                isShown: search.isOpen
                parts: search.parts
                rootX: search.rootX
                seedX: search.rootX + Appearance.taskbar.thickness / 2
                seedY: search.middleY
                formWidth: search.formWidth
                formHeight: search.height
                leftCorner: search.look.rootCorner
                rightCorner: search.look.corner
                edgePad: search.look.melt
                canHandOff: search.canHandOff
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
        id: wallMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Item {
            anchors.fill: parent
            transform: Upright {
                isMirrored: search.isMirrored
                axis: wallMask.width / 2
            }

            Shape {
                anchors.fill: parent

                ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"
                    strokeWidth: 0
                    PathPolyline { path: search.maskOutline }
                }
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
                topMargin: search.listLead
                clip: true
                boundsBehavior: Flickable.DragOverBounds
                model: search.listApps
                currentIndex: search.zone === "list" ? search.cursor : -1
                onCurrentIndexChanged: if (currentIndex >= 0) search.keepRowShown(currentIndex)

                delegate: ResultRow {
                    required property var modelData
                    required property int index
                    readonly property real rowTop: listView.y + y - listView.contentY
                    width: listView.width
                    fade: search.rowFade(rowTop)
                    room: search.rowRoom(rowTop)
                    isMirrored: search.isMirrored
                    app: modelData
                    isShown: search.isContentShown
                    isSelected: search.zone === "list" && search.cursor === index
                    isFavorite: search.favoriteIds.indexOf(modelData.id) >= 0
                    enterDelay: search.revealDelay(search.listX, index)
                    onActivated: search.launch(modelData)
                    onPinToggled: search.favoriteToggled(modelData.id)
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
                        switch (event.key) {
                        case Qt.Key_Escape:
                            if (input.text.length > 0)
                                input.text = ""
                            else
                                search.closeRequested()
                            break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
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
        profileName: search.profileName
        profilePicture: search.profilePicture
        isShown: search.isContentShown
        isSelected: search.zone === "found"
        enterDelay: search.revealDelay(search.foundCenterX, 1)
        onActivated: search.launch(app)
        onPinToggled: search.favoriteToggled(app.id)
        onPointed: search.select("found", 0)
    }

    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: wallMask
        }

        Flickable {
            id: favoriteView

            readonly property real lead: search.look.inset - search.look.tileGap / 2

            x: search.edgeX(search.rootX, width)
            y: search.look.top - search.look.tileGap / 2
            width: Math.max(0, search.wallReach - search.rootX)
            height: search.cellHeight * search.look.favoriteRows
            contentWidth: lead + favoriteGrid.width
            contentHeight: height
            contentX: search.isMirrored ? contentWidth - width : 0
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.DragOverBounds

            GridView {
                id: favoriteGrid
                x: search.isMirrored ? favoriteView.contentWidth - favoriteView.lead - width : favoriteView.lead
                width: search.cellWidth * search.favoriteColumns
                height: favoriteView.height
                interactive: false
                cellWidth: search.cellWidth
                cellHeight: search.cellHeight
                layoutDirection: search.isMirrored ? Qt.RightToLeft : Qt.LeftToRight
                model: search.favorites
                currentIndex: search.zone === "fav" ? search.cursor : -1
                onCurrentIndexChanged: if (currentIndex >= 0) search.keepFavoriteShown(currentIndex)

                delegate: AppTile {
                    id: favorite
                    required property var modelData
                    required property int index
                    readonly property real start: {
                        favoriteView.contentX
                        const position = favorite.mapToItem(favoriteView, 0, 0).x
                        return search.isMirrored ? favoriteView.width - position - width : position
                    }
                    opacity: Math.max(0, Math.min(1, (start - favoriteView.lead + search.cellWidth) / search.cellWidth))
                    app: modelData
                    isShown: search.isContentShown
                    isSelected: search.zone === "fav" && search.cursor === index
                    enterDelay: search.revealDelay(search.listX + (index % search.favoriteColumns) * search.cellWidth, Math.floor(index / search.favoriteColumns))
                    onActivated: search.launch(modelData)
                    onPinToggled: search.favoriteToggled(modelData.id)
                    onPointed: search.select("fav", index)
                }
            }
        }

        Turn {
            x: search.edgeX(search.listX, width)
            y: search.look.top + (search.favoritesHeight - height) / 2
            isShown: search.isContentShown && search.favorites.length === 0
            enterDelay: search.revealDelay(search.listX, 0)

            Text {
                text: "RIGHT CLICK TO PIN"
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }
}
