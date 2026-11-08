import QtQuick
import qs.config

Item {
    id: rising

    property bool isRunning: false
    property real fromX: 0
    property real toX: 0
    property real ceiling: 0
    property real floor: 0
    property int living: 0
    readonly property bool isEmitting: isRunning && !Motion.isReduced
    readonly property bool isActive: isEmitting || living > 0
    readonly property var look: Appearance.rising
    readonly property var pace: Motion.rising

    property var pool: []
    property real clock: 0

    function between(low, high) {
        return low + Math.random() * (high - low)
    }

    function spawn() {
        let index = -1
        for (let slot = 0; slot < look.count; slot++) {
            if (!pool[slot] || !pool[slot].isAlive) {
                index = slot
                break
            }
        }
        if (index < 0 || toX <= fromX)
            return
        const direction = Math.random() < 0.5 ? -1 : 1
        const size = between(look.low, look.high)
        const startY = direction < 0 ? ceiling + look.sink : floor - look.sink
        const endY = direction < 0 ? -size : height + size
        pool[index] = {
            isAlive: true,
            age: 0,
            direction: direction,
            baseX: between(fromX, toX),
            y: startY,
            startY: startY,
            distance: Math.max(1, Math.abs(endY - startY)),
            velocity: between(0.7, 1.2) * pace.speed,
            lift: between(0.8, 1.3) * pace.lift,
            sway: between(look.swayLow, look.swayHigh),
            swayRate: between(1.2, 2.6),
            phase: between(0, Math.PI * 2),
            size: size
        }
    }

    function drain() {
        for (const bubble of pool) {
            if (bubble && bubble.isAlive && bubble.drainFrom === undefined)
                bubble.drainFrom = bubble.age
        }
    }

    function advance(step) {
        if (isEmitting) {
            clock += step * 1000
            if (clock >= pace.interval) {
                clock = 0
                spawn()
            }
        }
        let count = 0
        for (let index = 0; index < look.count; index++) {
            const bubble = pool[index]
            const item = repeater.itemAt(index)
            if (!item)
                continue
            if (!bubble || !bubble.isAlive) {
                item.visible = false
                continue
            }
            bubble.age += step
            bubble.velocity += bubble.lift * step
            bubble.y += bubble.direction * bubble.velocity * step
            const progress = Math.min(1, Math.abs(bubble.y - bubble.startY) / bubble.distance)
            const growth = Math.min(1, bubble.age / pace.grow)
            const fade = bubble.drainFrom === undefined ? 1 : Math.max(0, 1 - (bubble.age - bubble.drainFrom) / pace.drain)
            const size = bubble.size * (0.5 + 0.5 * growth) * (1 - look.shrink * progress * progress) * fade
            const pointX = bubble.baseX + Math.sin(bubble.age * bubble.swayRate + bubble.phase) * bubble.sway * growth
            if (progress >= 1 || fade <= 0 || bubble.age >= pace.life)
                bubble.isAlive = false
            item.visible = bubble.isAlive && size > 0.5
            item.width = size
            item.height = size
            item.x = pointX - size / 2
            item.y = bubble.y - size / 2
            if (bubble.isAlive)
                count++
        }
        living = count
    }

    onIsEmittingChanged: {
        clock = 0
        if (!isEmitting)
            drain()
    }

    FrameAnimation {
        running: rising.isActive
        onTriggered: rising.advance(Math.min(frameTime, Motion.liquid.frameCap))
    }

    Repeater {
        id: repeater
        model: rising.look.count

        delegate: LiquidShape {
            visible: false
        }
    }
}
