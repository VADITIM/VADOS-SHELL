import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Liquid.js" as Liquid
import "../../utils/Geometry.js" as Geometry
import "../../utils/PillOrder.js" as PillOrder

Item {
    id: shell

    property bool isCovered: false
    property var hostWindow: null
    property bool isSummoned: false
    property bool isEngaged: false
    property string expandedIdle: ""
    readonly property string preparedExtension: expandedIdle.length > 0 && idleFor(expandedIdle) !== null ? idleFor(expandedIdle).extensionKey : ""
    property string hoverOpenedKey: ""
    property Item hoveredIdle: null
    property point safeApex: Qt.point(0, 0)
    property string pressedAppId: ""
    property var carryOrigin: null
    property Item hoveredTask: null
    property var neckLine: null
    property Item carryTarget: null
    property real carryCloseness: 0
    property bool isNecked: false
    property string barStyle: "floating"
    readonly property bool isFused: barStyle === "fused"
    readonly property bool isBare: barStyle === "bare"
    property real inset: isFused ? 0 : Appearance.taskbar.margin
    property real fuse: isFused ? 1 : 0
    readonly property Item tipShapes: tipLiquid.shapes
    property bool isCompact: false
    property var idleOrder: PillOrder.keys
    property var hiddenIdles: []
    property bool isReordering: false

    property bool isMirrored: false
    property string frostSource: ""
    property real screenWidth: width
    property bool isAway: false
    property bool isGathering: false
    property bool isMerging: true
    readonly property bool isHoldingParts: isGathering && isMerging
    readonly property bool isShrinking: isAway && !isMerging
    property bool hasSlung: false
    readonly property bool isVeiled: isAway && hasSlung && !isGathering
    property bool wasRevealed: false
    property bool isEaten: false
    property string extensionKey: ""
    property string heldExtensionKey: ""
    property real extensionFoot: 0
    readonly property Item extensionIdle: heldExtensionKey.length > 0 ? idleExtending(heldExtensionKey) : null
    readonly property real clockTop: clock.y
    readonly property rect extensionRect: extensionIdle ? extensionIdle.bodyRect() : Qt.rect(0, 0, 0, 0)
    readonly property real extensionLift: extensionIdle ? extensionIdle.lift : 0
    property var visitor: null
    readonly property bool isArriving: visitor !== null && visitor.isReleasing === true && visitor.release > 0
    property string activityMode: "idle"
    property string activityLead: "media"
    property bool isAlerting: false
    property size alertSize: Qt.size(0, 0)
    property bool isClipboardOpen: false
    property size clipboardSize: Qt.size(0, 0)

    signal compactRequested(bool isCompact)
    signal settingsRequested()
    signal dashboardRequested()
    signal extensionRequested(string key)
    signal activityModeRequested(string mode)
    signal activityFoldRequested
    signal activityLeadRequested(int direction)
    signal activityTabRequested(string key)
    signal clipboardCloseRequested()

    readonly property bool isRevealed: (!isCovered || isSummoned) && !isAway
    readonly property bool isHeld: rootHover.hovered || carried.isActive || taskPointer.pressed || isEngaged
    readonly property Item liquidShapes: liquid.shapes
    readonly property Arrangement arrangement: Arrangement {}
    readonly property real pitch: Appearance.taskbar.item + Appearance.taskbar.itemGap
    readonly property bool isCarrying: carried.isActive
    readonly property real inputWidth: inputZone.width
    readonly property rect alertRect: activityPill.spreadRect
    readonly property bool isAlertShown: activityPill.isAlertShown
    readonly property rect clipboardRect: activityPill.spreadRect
    readonly property bool isClipboardShown: activityPill.isClipboardShown
    readonly property bool isSwallowing: activityPill.isClipboardBody && clipboardSize.height > 0
    readonly property real swallowTop: activityCenter - clipboardSize.height / 2 - Appearance.taskbar.pillGap
    readonly property real swallowBottom: activityCenter + clipboardSize.height / 2 + Appearance.taskbar.pillGap
    readonly property var activityPlace: ({
        spineX: inset + Appearance.taskbar.thickness / 2,
        centerY: activityCenter,
        width: activityPill.isShown ? activityPill.bodyWidth : 0,
        height: activityPill.isShown ? activityPill.bodyHeight : 0,
        glyph: activityPill.isShown && activityPill.face === "active" ? Appearance.activity.glyphs[activityPill.leadKey] ?? "" : ""
    })
    readonly property real activityCenter: {
        let stackBottom = Appearance.taskbar.margin
        for (const pill of allPills()) {
            if (pill.livingCount > 0)
                stackBottom = Math.max(stackBottom, pill.y + pill.height)
        }
        const highest = stackBottom + Appearance.taskbar.pillGap + Appearance.activity.length / 2
        const lowest = idleColumn.y - Appearance.taskbar.pillGap - activityPill.extent
        return Math.max(highest, Math.min(lowest, height / 2))
    }

    function touchOf(centerX, top, bottom, halfWidth) {
        if (!visitor)
            return 0
        const awayX = Math.max(0, Math.abs(visitor.x - centerX) - visitor.width / 2 - halfWidth)
        const awayY = Math.max(0, Math.abs(visitor.y - (top + bottom) / 2) - visitor.height / 2 - (bottom - top) / 2)
        return Geometry.clampUnit(1 - Math.hypot(awayX, awayY) / Appearance.taskbar.visitReach)
    }

    function swallows(top, bottom) {
        return (isSwallowing && bottom > swallowTop && top < swallowBottom) 
    }

    function hasArrivedAt(centerY) {
        if (!isArriving)
            return true
        let nearest = null
        for (const part of visitor.arrivals) {
            if (!nearest || Math.abs(part.y - centerY) < Math.abs(nearest.y - centerY))
                nearest = part
        }
        return nearest === null || visitor.release >= nearest.arrival
    }

    function originPoints() {
        const size = powerIdle.size
        return {
            power: Qt.point(idleColumn.x + powerIdle.x + powerIdle.circleX + size / 2, idleColumn.y + powerIdle.y + powerIdle.height / 2)
        }
    }

    function liquidGroups() {
        const groups = { tasks: [], activity: [], system: [] }
        if (isBare)
            return groups
        for (const pill of allPills()) {
            if (pill.isShown && pill.popScale > 0.5)
                groups.tasks.push(Qt.rect(pill.x + pill.thickness * (1 - pill.popScale) / 2, pill.shellTop, pill.thickness * pill.popScale, pill.shellLength * pill.popScale))
        }
        if (activityPill.isShown && activityPill.popScale > 0.5)
            groups.activity.push(activityPill.bodyRect())
        if (trayIdle.isShown && trayIdle.popScale >= 0.5) {
            const traySize = trayIdle.size * trayIdle.popScale
            groups.tasks.unshift(Qt.rect(trayHolder.x + trayIdle.circleX + (trayIdle.size - traySize) / 2, trayHolder.y + (trayIdle.height - traySize) / 2, trayIdle.shellWidth * trayIdle.popScale, traySize))
        }
        const idles = idleColumn.children
        for (let position = 0; position < idles.length; position++) {
            const idle = idles[position]
            if (!idle.isShown || idle.popScale < 0.5)
                continue
            const size = idle.size * idle.popScale
            const left = idleColumn.x + idle.x + idle.circleX + (idle.size - size) / 2
            const top = idleColumn.y + idle.y + (idle.height - size) / 2
            groups.system.push(Qt.rect(left, top, idle.shellWidth * idle.popScale, size))
        }
        return groups
    }

    function liquidParts() {
        const groups = liquidGroups()
        return groups.tasks.concat(groups.activity, groups.system)
    }

    function allPills() {
        const pills = [mainPill]
        for (let position = 0; position < detachedRepeater.count; position++) {
            const pill = detachedRepeater.itemAt(position)
            if (pill)
                pills.push(pill)
        }
        return pills
    }

    function stackTop(index) {
        let top = mainPill.y + (mainPill.livingCount > 0 ? mainPill.height + Appearance.taskbar.pillGap : 0)
        for (let position = 0; position < Math.min(index, detachedRepeater.count); position++) {
            const pill = detachedRepeater.itemAt(position)
            if (pill)
                top += pill.height + Appearance.taskbar.pillGap
        }
        return top
    }

    function titleFor(appId) {
        const group = arrangement.groupFor(appId)
        if (!group || group.windows.length === 0)
            return appId
        const window = group.windows.find(candidate => candidate.activated) ?? group.windows[0]
        return window.title || appId
    }

    function toggleIdle(idleKey) {
        if (hoverOpenedKey === idleKey && expandedIdle === idleKey) {
            hoverOpenedKey = ""
            return
        }
        expandedIdle = expandedIdle === idleKey ? "" : idleKey
    }

    function foldIdles(isFolding) {
        hoverOpen.stop()
        closeHoverOpened()
        expandedIdle = ""
        if (isFolding !== isCompact)
            compactRequested(isFolding)
    }

    function scrollIdles(delta) {
        if (delta === 0 || (delta < 0) === isCompact)
            return
        foldIdles(delta < 0)
    }

    function idleRank(idleKey) {
        return PillOrder.rankOf(idleOrder, idleKey)
    }

    function keepsCompact(idleKey) {
        return PillOrder.isKeptCompact(idleOrder, idleKey)
    }

    function isIdleHidden(idleKey) {
        return hiddenIdles.indexOf(idleKey) >= 0
    }

    onIdleOrderChanged: {
        isReordering = true
        reorderSettle.restart()
    }

    function hoverIdle(idle, isHovered) {
        if (isHovered) {
            hoveredIdle = idle
            hoverOpen.restart()
        } else if (hoveredIdle === idle) {
            hoveredIdle = null
            hoverOpen.stop()
        }
    }

    function idleFor(idleKey) {
        if (idleKey === trayIdle.idleKey)
            return trayIdle
        const idles = idleColumn.children
        for (let position = 0; position < idles.length; position++) {
            if (idles[position].idleKey === idleKey)
                return idles[position]
        }
        return null
    }

    function idleExtending(extensionKey) {
        const idles = idleColumn.children
        for (let position = 0; position < idles.length; position++) {
            if (idles[position].extensionKey === extensionKey)
                return idles[position]
        }
        return null
    }

    function isUnderExtension(idle, top, bottom) {
        if (extensionIdle === null || extensionIdle === idle || extensionLift < 0.001)
            return false
        return bottom > extensionRect.y && top < extensionRect.y + extensionRect.height
    }

    function closeHoverOpened() {
        hoverClose.stop()
        hoverGrace.stop()
        if (expandedIdle === hoverOpenedKey)
            expandedIdle = ""
        hoverOpenedKey = ""
    }

    function isInsideTriangle(point, first, second, third) {
        const sign = (from, to) => (point.x - to.x) * (from.y - to.y) - (from.x - to.x) * (point.y - to.y)
        const sideFirst = sign(first, second)
        const sideSecond = sign(second, third)
        const sideThird = sign(third, first)
        const hasNegative = sideFirst < 0 || sideSecond < 0 || sideThird < 0
        const hasPositive = sideFirst > 0 || sideSecond > 0 || sideThird > 0
        return !(hasNegative && hasPositive)
    }

    function followPointer(point) {
        const idle = hoverOpenedKey !== "" ? idleFor(hoverOpenedKey) : null
        if (!idle)
            return
        const body = idle.bodyRect()
        const slack = shell.height * Appearance.taskbar.hoverSlackShare
        const isInside = point.x >= body.x - slack && point.x <= body.x + body.width + slack
            && point.y >= body.y - slack && point.y <= body.y + body.height + slack
        if (isInside) {
            safeApex = point
            hoverClose.stop()
            hoverGrace.stop()
            return
        }
        const farTop = Qt.point(body.x + body.width, body.y - slack)
        const farBottom = Qt.point(body.x + body.width, body.y + body.height + slack)
        if (isInsideTriangle(point, safeApex, farTop, farBottom)) {
            hoverClose.stop()
            hoverGrace.restart()
        } else {
            hoverGrace.stop()
            if (!hoverClose.running)
                hoverClose.start()
        }
    }

    function hoverTask(task, isHovered) {
        if (isHovered)
            hoveredTask = task
        else if (hoveredTask === task)
            hoveredTask = null
    }

    function collapseActivity() {
        if (activityMode === "expanded")
            activityModeRequested("active")
        if (isClipboardOpen)
            clipboardCloseRequested()
    }

    function summon() {
        if (isCovered)
            isSummoned = true
    }

    function taskAt(pointX, pointY) {
        for (const pill of allPills()) {
            const task = pill.taskAt(pointX, pointY)
            if (task)
                return task
        }
        return null
    }

    function slotCenter(appId) {
        for (const pill of allPills()) {
            const task = pill.itemFor(appId)
            if (task)
                return task.mapToItem(shell, task.width / 2, task.height / 2)
        }
        return Qt.point(carried.centerX, carried.centerY)
    }

    function settleCarry() {
        closenessRelease.stop()
        arrangement.settleGhost(carried.appId)
        arrangement.carriedAppId = ""
        carryTarget = null
        carryCloseness = 0
        isNecked = false
        neckLine = null
        carried.isLanding = false
        carried.presence = 0
        carried.appId = ""
    }

    function beginCarry(task, pointX, pointY) {
        if (carried.isLanding)
            settleCarry()
        const center = task.mapToItem(shell, task.width / 2, task.height / 2)
        carryOrigin = { pillKey: task.pill.pillKey, index: arrangement.livingPlace(task.appId)?.index ?? 0 }
        arrangement.carriedAppId = task.appId
        arrangement.markGhost(task.appId)
        pressedAppId = ""
        hoveredTask = null
        carried.appId = task.appId
        carried.pickUp(center.x, center.y, pointX, pointY)
    }

    function moveCarry(pointX, pointY) {
        carried.finger = Qt.point(pointX, pointY)
        trackCarry()
    }

    function trackCarry() {
        const nearest = measureNeck()
        neckLine = nearest
        if (!carried.isCarried)
            return
        const appId = carried.appId
        const reach = nearest ? Geometry.clampUnit(1 - nearest.gap / Motion.carry.pinch) : 0
        const target = nearest && nearest.gap < Motion.carry.pinch ? nearest.pill : null
        if (target !== carryTarget && carryTarget)
            carryTarget.freezeGhost(appId)
        carryCloseness = Geometry.smooth(reach)
        const isNowNecked = Liquid.isMerged(isNecked, reach, Motion.liquid.neck)
        if (isNowNecked !== isNecked) {
            isNecked = isNowNecked
            carried.deformVelocity += Liquid.neckKick(isNowNecked, Motion.liquid.neck)
        }
        carryTarget = target
        if (target) {
            const isOwnSlot = target.itemFor(appId) !== null
            arrangement.placeGhost(appId, target.pillKey, target.slotIndexAt(carried.centerY, isOwnSlot))
        } else {
            arrangement.vacate(appId)
        }
    }

    function endCarry(pointY) {
        const appId = carried.appId
        trackCarry()
        if (!arrangement.livingPlace(appId)) {
            if (pointY > mainPill.shellBottom + Appearance.taskbar.pillGap || mainPill.livingCount === 0) {
                let index = 0
                for (const pill of allPills()) {
                    if (pill !== mainPill && pill.y + pill.height / 2 < pointY)
                        index++
                }
                arrangement.placeGhost(appId, arrangement.createPill(index), 0)
            } else {
                const isOriginAlive = arrangement.modelFor(carryOrigin.pillKey) !== null
                arrangement.placeGhost(appId, isOriginAlive ? carryOrigin.pillKey : "main", isOriginAlive ? carryOrigin.index : arrangement.mainTasks.count)
            }
        }
        closenessRelease.from = carryCloseness
        closenessRelease.restart()
        carried.land(() => slotCenter(appId))
    }

    function measureNeck() {
        if (!carried.isActive || carried.presence <= 0)
            return null
        const centerX = carried.centerX
        const centerY = carried.centerY
        const half = Appearance.taskbar.thickness / 2
        let best = null
        for (const pill of allPills()) {
            if (!pill.isShown || pill.popScale < 0.5)
                continue
            const spineTop = pill.shellTop + half
            const spineBottom = Math.max(spineTop, pill.coreBottom - half)
            const anchorY = Math.max(spineTop, Math.min(spineBottom, centerY))
            const distance = Math.hypot(centerX - pill.spineX, centerY - anchorY)
            const gap = distance - half - carried.size / 2
            if (!best || gap < best.gap)
                best = { pill: pill, fromX: pill.spineX, fromY: anchorY, toX: centerX, toY: centerY, distance: distance, gap: gap }
        }
        return best
    }

    onIsCoveredChanged: {
        if (!isCovered && !isEngaged)
            isSummoned = false
        else if (isCovered && rootHover.hovered)
            isSummoned = true
    }
    onIsRevealedChanged: {
        if (!isRevealed) {
            expandedIdle = ""
            collapseActivity()
            if (extensionKey.length > 0)
                extensionRequested("")
        }
    }
    onExtensionKeyChanged: {
        if (extensionKey.length > 0) {
            heldExtensionKey = extensionKey
            hoverOpen.stop()
            closeHoverOpened()
            expandedIdle = ""
            hoveredTask = null
        }
    }
    onIsEatenChanged: {
        if (isEaten) {
            expandedIdle = ""
            hoveredTask = null
            collapseActivity()
        }
    }
    onExpandedIdleChanged: {
        if (expandedIdle !== hoverOpenedKey)
            hoverOpenedKey = ""
    }
    onIsHeldChanged: isHeld ? linger.stop() : linger.restart()
    onHoveredTaskChanged: {
        if (hoveredTask && !carried.isActive) {
            tipGrace.stop()
            if (tip.isShown)
                tip.task = hoveredTask
            else
                tipDelay.restart()
        } else {
            tipDelay.stop()
            if (tip.isShown && !carried.isActive)
                tipGrace.restart()
            else
                tip.isShown = false
        }
    }

    Connections {
        target: shell.arrangement

        function onGroupsChanged() {
            if (carried.isActive && !shell.arrangement.groupFor(carried.appId)) {
                shell.arrangement.vacate(carried.appId)
                shell.arrangement.carriedAppId = ""
                carried.drop()
            }
        }
    }

    FrameAnimation {
        paused: Motion.isHeld && running
        running: carried.isActive
        onTriggered: shell.trackCarry()
    }

    NumberAnimation {
        paused: Motion.isHeld && running
        id: closenessRelease
        target: shell
        property: "carryCloseness"
        to: 1
        duration: Motion.pace(Motion.carry.release)
        easing.type: Easing.OutCubic
    }

    Timer {
        id: linger
        interval: Motion.reveal.linger
        onTriggered: {
            shell.expandedIdle = ""
            shell.isSummoned = false
        }
    }

    Timer {
        id: hoverOpen
        interval: Motion.hover.openDelay
        onTriggered: {
            const idle = shell.hoveredIdle
            if (!idle || carried.isActive || shell.expandedIdle === idle.idleKey)
                return
            shell.safeApex = rootHover.point.position
            shell.hoverOpenedKey = idle.idleKey
            shell.expandedIdle = idle.idleKey
        }
    }

    Timer {
        id: hoverClose
        interval: Motion.hover.closeDelay
        onTriggered: shell.closeHoverOpened()
    }

    Timer {
        id: hoverGrace
        interval: Motion.hover.triangleGrace
        onTriggered: shell.closeHoverOpened()
    }

    Timer {
        id: tipGrace
        interval: Motion.tip.grace
        onTriggered: tip.isShown = false
    }

    Timer {
        id: tipDelay
        interval: Motion.reveal.tipDelay
        onTriggered: {
            tip.task = shell.hoveredTask
            tip.isShown = shell.hoveredTask !== null
        }
    }

    opacity: isVeiled ? 0 : 1
    onIsAwayChanged: {
        if (isAway) {
            wasRevealed = !isCovered || isSummoned
            hasSlung = false
            veilDelay.restart()
        } else {
            veilDelay.stop()
            hasSlung = false
        }
    }

    Timer {
        id: veilDelay
        interval: shell.isMerging ? Motion.pill.awayHold : Motion.pill.shrinkHold
        onTriggered: shell.hasSlung = shell.isAway
    }

    transform: Upright {
        isMirrored: shell.isMirrored
        axis: shell.width / 2
    }

    HoverHandler {
        id: rootHover
        onPointChanged: shell.followPointer(point.position)
        onHoveredChanged: {
            if (!hovered && shell.hoverOpenedKey !== "" && !hoverClose.running)
                hoverClose.start()
        }
    }

    Rectangle {
        width: Appearance.taskbar.backdropWidth
        height: parent.height
        opacity: shell.isRevealed ? 1 : 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.62) }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.3) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.pace(shell.isRevealed ? Motion.reveal.backdropEnter : Motion.reveal.backdropLeave)
                easing.type: shell.isRevealed ? Easing.OutQuad : Easing.InQuad
            }
        }
    }

    Behavior on inset {
        NumberAnimation {
            duration: Motion.pace(Motion.pill.sizeFollow)
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on fuse {
        NumberAnimation {
            duration: Motion.pace(Motion.pill.sizeFollow)
            easing.type: Easing.InOutCubic
        }
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        frostSource: shell.frostSource
        frostSize: Qt.size(shell.screenWidth, shell.height)
        isFrostMirrored: shell.isMirrored
        isShown: true
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: Appearance.taskbar.melt
        opacity: shell.isBare || (shell.isAway && !shell.isGathering && (shell.isMerging || shell.hasSlung)) ? 0 : 1

        Lobe {
            readonly property var visitor: shell.visitor
            parent: liquid.shapes
            visible: visitor !== null && visitor.isHandedOff && visitor.x > 0
            side: 1
            edge: -Appearance.taskbar.melt
            tip: visitor ? visitor.x : 0
            centerY: visitor ? visitor.y : 0
            innerHalf: visitor ? visitor.height / 2 : 0
            outerHalf: visitor ? visitor.height / 2 + Math.min(Appearance.burst.rootSwell, visitor.height * Appearance.burst.swellShare) : 0
            capShare: Appearance.burst.rootCap
        }

        LiquidShape {
            readonly property var visitor: shell.visitor
            parent: liquid.shapes
            visible: visitor !== null && visitor.isHandedOff
            width: visitor ? visitor.width : 0
            height: visitor ? visitor.height : 0
            x: visitor ? visitor.x - width / 2 : 0
            y: visitor ? visitor.y - height / 2 : 0
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.pace(shell.isAway || shell.isArriving ? 0 : Motion.stateDuration)
                easing.type: Easing.OutQuad
            }
        }
    }

    LiquidLayer {
        id: tipLiquid
        anchors.fill: parent
        frostSource: shell.frostSource
        frostSize: Qt.size(shell.screenWidth, shell.height)
        isFrostMirrored: shell.isMirrored
        isShown: shell.isBare && tip.visible
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: Appearance.taskbar.melt
    }

    LiquidBridge {
        id: neck
        readonly property var line: shell.neckLine
        readonly property real share: line ? Geometry.clampUnit(1 - line.gap / Motion.carry.pinch) : 0
        parent: shell.liquidShapes
        fromX: line ? line.fromX : 0
        fromY: line ? line.fromY : 0
        fromRadius: Appearance.taskbar.thickness / 2 + (shell.carryTarget ? shell.carryTarget.swell : 0)
        toX: carried.meniscusX
        toY: carried.meniscusY
        toRadius: carried.size / 2 * carried.dropletScale
        readonly property real hold: Geometry.clampUnit((share - Motion.liquid.neck.separate) / (1 - Motion.liquid.neck.separate))
        spread: shell.isNecked || carried.isLanding ? Motion.carry.spread * (Motion.carry.snapSpread + (1 - Motion.carry.snapSpread) * Math.sqrt(hold)) : 0
        handle: Motion.carry.handle
    }

    Gesture {
        id: taskPointer

        property Item pressedTask: null

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: mouse => {
            const task = shell.taskAt(mouse.x, mouse.y)
            if (!task) {
                mouse.accepted = false
                return
            }
            pressedTask = task
            shell.pressedAppId = task.appId
        }
        onCrossed: (travelX, travelY) => {
            if (!pressedTask)
                return
            shell.beginCarry(pressedTask, pressPoint.x + travelX, pressPoint.y + travelY)
            pressedTask = null
        }
        onMoved: (travelX, travelY) => {
            if (carried.isCarried)
                shell.moveCarry(pressPoint.x + travelX, pressPoint.y + travelY)
        }
        onThrown: (travelX, travelY) => {
            if (carried.isCarried)
                shell.endCarry(pressPoint.y + travelY)
        }
        onTapped: mouse => {
            if (!pressedTask || !pressedTask.group)
                return
            if (mouse.button === Qt.MiddleButton)
                Toplevels.close(pressedTask.group)
            else
                Toplevels.activate(pressedTask.group)
        }
        onEnded: {
            pressedTask = null
            shell.pressedAppId = ""
        }
    }

    Repeater {
        id: detachedRepeater
        model: shell.arrangement.detachedPills

        delegate: TaskPill {
            id: detachedPill
            required property int index
            tasks: shell.arrangement.modelFor(pillKey)
            host: shell
            isRevealed: shell.isRevealed && !shell.isEaten && !shell.swallows(y, y + height)
            enterDelay: (Math.max(0, index) + 1) * Motion.reveal.stagger
            x: shell.inset
            y: shell.stackTop(index)
            onDeparted: {
                if (livingCount === 0)
                    Qt.callLater(() => shell.arrangement.removePill(detachedPill.pillKey))
            }
        }
    }

    TaskPill {
        id: mainPill
        pillKey: "main"
        tasks: shell.arrangement.mainTasks
        host: shell
        isRevealed: shell.isRevealed && !shell.isEaten && !shell.swallows(y, y + height)
        x: shell.inset
        y: Appearance.taskbar.margin + trayIdle.height
    }

    Item {
        id: trayHolder
        x: shell.inset
        y: Appearance.taskbar.margin
        width: Appearance.taskbar.thickness
        height: trayIdle.height

        TrayIdle {
            id: trayIdle
            host: shell
            origin: trayHolder
        }
    }

    ActivityPill {
        id: activityPill
        host: shell
        mode: shell.activityMode
        leadKey: shell.activityLead
        liveKeys: Activities.liveKeys
        isAlerting: shell.isAlerting
        alertSize: shell.alertSize
        isClipboardOpen: shell.isClipboardOpen
        clipboardSize: shell.clipboardSize
        x: shell.inset
        y: shell.activityCenter
        z: activityPill.isSpreadBody ? 1 : 0
        onModeRequested: mode => shell.activityModeRequested(mode)
        onFoldRequested: shell.activityFoldRequested()
        onLeadRequested: direction => shell.activityLeadRequested(direction)
        onTabRequested: key => shell.activityTabRequested(key)
    }

    Item {
        id: idleColumn

        readonly property var heights: ({
            usb: usbIdle.height,
            audio: audioIdle.height,
            network: networkIdle.height,
            battery: batteryIdle.height,
            settings: settingsIdle.height,
            power: powerIdle.height
        })
        readonly property var offsets: PillOrder.offsetsFor(shell.idleOrder, heights)

        function slotOf(idleKey) {
            return foldDot.height + offsets[idleKey]
        }

        x: shell.inset
        width: Appearance.taskbar.thickness
        height: foldDot.height + offsets.total
        anchors.bottom: clock.top
        anchors.bottomMargin: Appearance.taskbar.idleGap

        FoldDot {
            id: foldDot
            host: shell
            origin: idleColumn
        }

        UsbIdle {
            id: usbIdle
            host: shell
            origin: idleColumn
            y: idleColumn.slotOf(idleKey)
        }

        AudioIdle {
            id: audioIdle
            host: shell
            origin: idleColumn
            y: idleColumn.slotOf(idleKey)
        }

        NetworkIdle {
            id: networkIdle
            host: shell
            origin: idleColumn
            y: idleColumn.slotOf(idleKey)
        }

        BatteryIdle {
            id: batteryIdle
            host: shell
            origin: idleColumn
            y: idleColumn.slotOf(idleKey)
        }

        SettingsIdle {
            id: settingsIdle
            host: shell
            origin: idleColumn
            y: idleColumn.slotOf(idleKey)
        }

        PowerIdle {
            id: powerIdle
            host: shell
            origin: idleColumn
            y: idleColumn.slotOf(idleKey)
        }
    }

    Timer {
        id: reorderSettle
        interval: Motion.fold.settle
        onTriggered: shell.isReordering = false
    }

    Clock {
        id: clock
        x: Appearance.taskbar.margin + 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.taskbar.margin
        isShown: (shell.isRevealed || (shell.isAway && shell.wasRevealed)) && !shell.isEaten && !shell.swallows(y, y + height) && !shell.isUnderExtension(null, y, y + height)
        transform: Upright {
            isMirrored: shell.isMirrored
            axis: clock.width / 2
        }

        TapHandler {
            enabled: shell.isRevealed
            onTapped: shell.dashboardRequested()
        }
    }

    TitleTip {
        id: tip
        host: shell
    }

    Carried {
        id: carried
        host: shell
        onLanded: shell.settleCarry()
    }

    EdgePull {
        anchors.fill: parent
        look: Appearance.taskbar
        pace: Motion.reveal
        isEnabled: !shell.isRevealed
        shapes: shell.liquidShapes
        onSummoned: shell.summon()
    }

    Item {
        id: inputZone

        readonly property real idleReach: {
            let reach = 0
            const children = idleColumn.children
            for (let position = 0; position < children.length; position++)
                reach = Math.max(reach, children[position].reachRight ?? 0)
            return Math.max(reach, trayIdle.reachRight)
        }

        width: !shell.isRevealed
            ? Math.max(Appearance.taskbar.edgeStrip, activityPill.isShown ? activityPill.reachRight : 0)
            : carried.isActive
                ? shell.width
                : Math.min(shell.width, Math.max(Appearance.taskbar.reach, idleReach + Appearance.taskbar.idleGap, tip.reachRight + Appearance.taskbar.tipGap, activityPill.isShown ? activityPill.reachRight : 0))
        height: parent.height
    }
}
