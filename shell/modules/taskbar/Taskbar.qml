import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Liquid.js" as Liquid
import "../../utils/Geometry.js" as Geometry

Item {
    id: shell

    property bool isCovered: false
    property var hostWindow: null
    property bool isSummoned: false
    property string expandedIdle: ""
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

    property bool isMirrored: false
    property bool isAway: false
    property bool isVeiled: false
    property bool isEaten: false
    property var visitor: null
    readonly property bool isArriving: visitor !== null && visitor.isReleasing === true && visitor.release > 0
    property string activityMode: "idle"
    property string activityLead: "media"
    property bool isAlerting: false
    property size alertSize: Qt.size(0, 0)

    signal compactRequested(bool isCompact)
    signal settingsRequested()
    signal dashboardRequested()
    signal extensionRequested(string key, rect origin)
    signal activityModeRequested(string mode)
    signal activityLeadRequested(int direction)

    readonly property bool isRevealed: (!isCovered || isSummoned) && !isAway
    readonly property bool isHeld: rootHover.hovered || carried.isActive || taskPointer.pressed
    readonly property Item liquidShapes: liquid.shapes
    readonly property Arrangement arrangement: Arrangement {}
    readonly property real pitch: Appearance.taskbar.item + Appearance.taskbar.itemGap
    readonly property bool isCarrying: carried.isActive
    readonly property real inputWidth: inputZone.width
    readonly property rect alertRect: activityPill.alertRect
    readonly property bool isAlertShown: activityPill.isAlertShown
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

    function liquidParts() {
        if (isBare)
            return []
        const parts = []
        for (const pill of allPills()) {
            if (pill.isShown && pill.popScale > 0.5)
                parts.push(Qt.rect(pill.x + pill.thickness * (1 - pill.popScale) / 2, pill.shellTop, pill.thickness * pill.popScale, pill.shellLength * pill.popScale))
        }
        if (activityPill.isShown && activityPill.popScale > 0.5)
            parts.push(activityPill.bodyRect())
        const idles = idleColumn.children
        for (let position = 0; position < idles.length; position++) {
            const idle = idles[position]
            if (!idle.isShown || idle.popScale < 0.5)
                continue
            const size = idle.size * idle.popScale
            const left = idleColumn.x + idle.x + idle.circleX + (idle.size - size) / 2
            const top = idleColumn.y + idle.y + (idle.height - size) / 2
            parts.push(Qt.rect(left, top, idle.shellWidth * idle.popScale, size))
        }
        return parts
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
        const idles = idleColumn.children
        for (let position = 0; position < idles.length; position++) {
            if (idles[position].idleKey === idleKey)
                return idles[position]
        }
        return null
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
        const slack = Appearance.taskbar.hoverSlack
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
        if (!isCovered)
            isSummoned = false
        else if (rootHover.hovered)
            isSummoned = true
    }
    onIsRevealedChanged: {
        if (!isRevealed) {
            expandedIdle = ""
            collapseActivity()
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
        if (isAway)
            veilDelay.restart()
        else {
            veilDelay.stop()
            isVeiled = false
        }
    }

    Timer {
        id: veilDelay
        interval: Motion.pill.awayHold
        onTriggered: shell.isVeiled = shell.isAway
    }

    transform: Upright {
        isMirrored: shell.isMirrored
        axis: shell.width / 2
    }

    HoverHandler {
        id: rootHover
        onPointChanged: shell.followPointer(point.position)
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
        isShown: true
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: Appearance.taskbar.melt
        opacity: shell.isBare || shell.isAway ? 0 : 1

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
            isRevealed: shell.isRevealed && !shell.isEaten
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
        isRevealed: shell.isRevealed && !shell.isEaten
        x: shell.inset
        y: Appearance.taskbar.margin
    }

    ActivityPill {
        id: activityPill
        host: shell
        mode: shell.activityMode
        leadKey: shell.activityLead
        liveKeys: Activities.liveKeys
        isAlerting: shell.isAlerting
        alertSize: shell.alertSize
        x: shell.inset
        y: shell.activityCenter
        onModeRequested: mode => shell.activityModeRequested(mode)
        onLeadRequested: direction => shell.activityLeadRequested(direction)
    }

    Column {
        id: idleColumn
        x: shell.inset
        anchors.bottom: clock.top
        anchors.bottomMargin: Appearance.taskbar.idleGap

        FoldDot {
            host: shell
            origin: idleColumn
        }

        UsbIdle {
            host: shell
            origin: idleColumn
            order: 1
        }

        AudioIdle {
            host: shell
            origin: idleColumn
            order: 2
            isKeptCompact: true
        }

        NetworkIdle {
            host: shell
            origin: idleColumn
            order: 3
        }

        BatteryIdle {
            host: shell
            origin: idleColumn
            order: 4
        }

        SettingsIdle {
            id: settingsIdle
            host: shell
            origin: idleColumn
            order: 5
        }

        PowerIdle {
            host: shell
            origin: idleColumn
            order: 6
            isKeptCompact: true
        }
    }

    Clock {
        id: clock
        x: Appearance.taskbar.margin + 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.taskbar.margin
        isShown: (shell.isRevealed || shell.isAway) && !shell.isEaten
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
            return reach
        }

        width: !shell.isRevealed
            ? Math.max(Appearance.taskbar.edgeStrip, activityPill.isShown ? activityPill.reachRight : 0)
            : carried.isActive
                ? shell.width
                : Math.min(shell.width, Math.max(Appearance.taskbar.reach, idleReach + Appearance.taskbar.idleGap, tip.reachRight + Appearance.taskbar.tipGap, activityPill.isShown ? activityPill.reachRight : 0))
        height: parent.height
    }
}
