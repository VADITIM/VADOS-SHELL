import QtQuick
import qs.config
import "../utils/Liquid.js" as Liquid

WheelHandler {
    id: drift

    readonly property Flickable view: parent ? parent.parent as Flickable : null
    property bool isHorizontal: false
    property bool isReversed: false
    property real position: 0
    property real velocity: 0
    property real goal: 0
    property real written: 0
    property real sampleTime: 0
    property bool isDrifting: false

    readonly property FrameAnimation clock: FrameAnimation {
        paused: Motion.isHeld && running
        running: drift.isDrifting
        onTriggered: drift.advance(frameTime)
    }

    function current() {
        return isHorizontal ? view.contentX : view.contentY
    }

    function write(value) {
        written = value
        if (isHorizontal)
            view.contentX = value
        else
            view.contentY = value
    }

    function lowest() {
        return isHorizontal ? view.originX - view.leftMargin : view.originY - view.topMargin
    }

    function highest() {
        const end = isHorizontal
            ? view.originX + view.contentWidth + view.rightMargin - view.width
            : view.originY + view.contentHeight + view.bottomMargin - view.height
        return Math.max(lowest(), end)
    }

    function clamp(value) {
        return Math.max(lowest(), Math.min(highest(), value))
    }

    function adopt() {
        if (Math.abs(current() - written) < Motion.drift.rest)
            return
        isDrifting = false
        position = current()
        velocity = 0
        goal = position
        written = position
    }

    function settle(value) {
        isDrifting = false
        velocity = 0
        position = value
        goal = value
        write(value)
    }

    function destination() {
        adopt()
        return goal
    }

    function glideTo(value) {
        if (!view)
            return
        adopt()
        if (!isDrifting)
            velocity = 0
        goal = clamp(value)
        if (Motion.isReduced) {
            settle(goal)
            return
        }
        if (view.flicking)
            view.cancelFlick()
        isDrifting = true
    }

    function glideBy(distance) {
        adopt()
        glideTo(goal + distance)
    }

    function glideAround(move) {
        if (!view)
            return
        adopt()
        const from = current()
        move()
        const to = current()
        if (Math.abs(to - from) < Motion.drift.rest)
            return
        write(from)
        glideTo(to)
    }

    function along(delta) {
        if (!isHorizontal)
            return -delta.y
        if (delta.x !== 0)
            return -delta.x
        return isReversed ? delta.y : -delta.y
    }

    function follow(distance) {
        adopt()
        const now = Date.now()
        const elapsed = (now - sampleTime) / 1000
        sampleTime = now
        const fresh = elapsed > 0 && elapsed < Motion.drift.glide ? distance / elapsed : 0
        velocity += (fresh - velocity) * Motion.gesture.velocityBlend
        isDrifting = false
        position = clamp(position + distance)
        goal = position
        write(position)
    }

    function release() {
        if (Math.abs(velocity) < Motion.drift.restVelocity) {
            velocity = 0
            return
        }
        const moving = velocity
        glideTo(position + velocity * Motion.drift.glide)
        velocity = moving
    }

    function advance(frameTime) {
        if (!view || view.dragging || Math.abs(current() - written) >= Motion.drift.rest) {
            isDrifting = false
            return
        }
        goal = clamp(goal)
        const next = Liquid.pull(position, velocity, goal, Motion.liquid.drift, frameTime, Motion.liquid)
        position = next.value
        velocity = next.velocity
        if (Math.abs(goal - position) < Motion.drift.rest && Math.abs(velocity) < Motion.drift.restVelocity) {
            settle(goal)
            return
        }
        write(position)
    }

    target: null
    enabled: view !== null && view.interactive
    onWheel: event => {
        event.accepted = true
        if (event.phase === Qt.ScrollEnd) {
            release()
            return
        }
        const pixels = along(event.pixelDelta)
        if (pixels !== 0) {
            follow(pixels)
            return
        }
        const angle = along(event.angleDelta)
        if (angle !== 0)
            glideBy(angle / Motion.drift.notchAngle * Motion.drift.notch)
    }
}
