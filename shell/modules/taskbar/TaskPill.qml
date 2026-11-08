import QtQuick
import qs.config
import qs.components

Item {
    id: taskPill

    required property string pillKey
    required property var tasks
    required property Item host
    property bool isRevealed: false
    property int enterDelay: 0

    readonly property real thickness: Appearance.taskbar.thickness
    readonly property real pitch: Appearance.taskbar.item + Appearance.taskbar.itemGap
    readonly property int livingCount: {
        let total = 0
        const children = column.children
        for (let position = 0; position < children.length; position++) {
            if (children[position].isLiving === true)
                total++
        }
        return total
    }
    readonly property bool isShown: isRevealed && livingCount > 0
    readonly property real fullLength: Math.max(thickness, column.height + Appearance.taskbar.padding * 2)
    readonly property real shellLength: thickness + (fullLength - thickness) * spread
    readonly property real shellTop: y + (height - shellLength * popScale) / 2
    readonly property real shellBottom: shellTop + shellLength * popScale
    readonly property real ghostExtent: {
        let total = 0
        const children = column.children
        for (let position = 0; position < children.length; position++) {
            const child = children[position]
            if (child.isGhost === true && child.isLiving)
                total += child.height
        }
        return total
    }
    readonly property real coreBottom: Math.max(shellTop, shellBottom - ghostExtent * popScale)
    readonly property real swell: Math.max(host.carryTarget === taskPill ? host.carryCloseness * Motion.carry.swell : 0, host.touchOf(spineX, shellTop, shellBottom, thickness / 2) * Appearance.taskbar.visitSwell)
    readonly property real spineX: x + thickness / 2
    readonly property Item activeTask: {
        const children = column.children
        for (let position = 0; position < children.length; position++) {
            const child = children[position]
            if (child.isActive === true && child.isLiving && !child.isGhost)
                return child
        }
        return null
    }
    readonly property real washTargetTop: activeTask ? activeTask.y + (activeTask.height - Appearance.taskbar.item) / 2 : 0

    readonly property real popScale: mutate.pop
    readonly property real spread: mutate.spread
    readonly property bool areItemsShown: mutate.isInnerShown
    readonly property bool isSpreading: spread < 1
    readonly property int outerItemDelay: Math.max(mutate.spreadAfterInner, Math.ceil((tasks.count - 1) / 2) * Motion.pill.elementStagger)
    property real washTop: NaN
    property real washBottom: NaN
    property bool isWashMovingDown: false

    signal departed()

    width: thickness
    height: livingCount > 0 ? fullLength : shellLength

    function taskAt(rootX, rootY) {
        if (!isShown || rootX < x || rootX > x + width)
            return null
        const local = rootY - y - column.y
        const children = column.children
        for (let position = 0; position < children.length; position++) {
            const child = children[position]
            if (child.appId === undefined || !child.isLiving || child.isGhost)
                continue
            if (local >= child.y && local < child.y + child.height)
                return child
        }
        return null
    }

    function itemFor(appId) {
        const children = column.children
        for (let position = 0; position < children.length; position++) {
            const child = children[position]
            if (child.appId === appId && child.isLiving)
                return child
        }
        return null
    }

    function captures(rootX, rootY) {
        const capture = Motion.carry.capture
        return isShown
            && rootX >= x - capture && rootX <= x + width + capture * 2
            && rootY >= shellTop - capture && rootY <= shellBottom + capture
    }

    function freezeGhost(appId) {
        const item = itemFor(appId)
        if (item && item.isGhost)
            item.freezeRoom()
    }

    function slotIndexAt(rootY, isOwnSlot) {
        const local = rootY - y - column.y
        const index = Math.floor(local / pitch)
        return Math.max(0, Math.min(tasks.count - (isOwnSlot ? 1 : 0), index))
    }

    function slideWash() {
        if (!activeTask)
            return
        const top = washTargetTop
        const bottom = top + Appearance.taskbar.item
        if (!Number.isFinite(washTop) || !areItemsShown) {
            topSlide.stop()
            bottomSlide.stop()
            washTop = top
            washBottom = bottom
            return
        }
        if (topSlide.running && topSlide.to === top)
            return
        if (!topSlide.running && washTop === top)
            return
        isWashMovingDown = top > washTop
        topSlide.duration = Motion.highlight.slide + (isWashMovingDown ? Motion.highlight.trail : 0)
        bottomSlide.duration = Motion.highlight.slide + (isWashMovingDown ? 0 : Motion.highlight.trail)
        topSlide.to = top
        bottomSlide.to = bottom
        topSlide.restart()
        bottomSlide.restart()
    }

    onActiveTaskChanged: slideWash()
    onWashTargetTopChanged: slideWash()

    Mutate {
        id: mutate
        isShown: taskPill.isShown
        enterDelay: taskPill.enterDelay
        onDeparted: taskPill.departed()
    }

    LiquidShape {
        id: body
        parent: taskPill.host.liquidShapes
        width: (taskPill.thickness + taskPill.swell) * taskPill.popScale
        height: (taskPill.shellLength + taskPill.swell) * taskPill.popScale
        x: taskPill.x + (taskPill.thickness - width) / 2
        y: taskPill.y + (taskPill.height - height) / 2
    }

    EdgeFuse {
        parent: taskPill.host.liquidShapes
        reach: body.x + body.width / 2
        bodyTop: body.y
        length: body.height
        share: taskPill.host.fuse
    }

    Rectangle {
        x: (taskPill.thickness - width) / 2
        y: column.y + (isNaN(taskPill.washTop) ? 0 : taskPill.washTop)
        width: Appearance.taskbar.item
        height: isNaN(taskPill.washTop) ? 0 : taskPill.washBottom - taskPill.washTop
        radius: width / 2
        color: Appearance.color.wash
        opacity: taskPill.activeTask && taskPill.areItemsShown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.pace(Motion.stateDuration)
                easing.type: Easing.OutQuad
            }
        }
    }

    Column {
        id: column
        width: taskPill.thickness
        y: (taskPill.height - height) / 2

        move: Transition {
            NumberAnimation {
                property: "y"
                duration: Motion.pace(Motion.stateDuration)
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: taskPill.tasks
            delegate: TaskItem {
                pill: taskPill
                host: taskPill.host
            }
        }
    }

    NumberAnimation {
        id: topSlide
        target: taskPill
        property: "washTop"
        duration: Motion.pace(Motion.highlight.slide)
        easing.type: Easing.OutQuad
    }

    NumberAnimation {
        id: bottomSlide
        target: taskPill
        property: "washBottom"
        duration: Motion.pace(Motion.highlight.slide)
        easing.type: Easing.OutQuad
    }
}
