import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Liquid.js" as Liquid

Item {
    id: carried

    required property Item host
    property string appId: ""
    property bool isCarried: false
    property bool isLanding: false
    readonly property bool isActive: isCarried || isLanding
    property point finger: Qt.point(0, 0)
    property var landingTarget: null
    property real centerX: 0
    property real centerY: 0
    property real velocityX: 0
    property real velocityY: 0
    property real presence: 0
    property real lift: 0
    readonly property real size: Appearance.taskbar.item
    readonly property real speed: Math.hypot(velocityX, velocityY)
    readonly property real shownScale: presence * (1 + (Motion.carry.lift - 1) * lift)
    readonly property real closeness: host.carryCloseness
    readonly property real dropletScale: shownScale * (1 - Motion.carry.absorb * closeness)
    readonly property real iconScale: shownScale * (1 - Motion.carry.iconAbsorb * closeness * hold)
    property real hold: 1
    property real deform: 0
    property real deformVelocity: 0
    property real deformAxis: 0
    readonly property var neck: host.neckLine
    readonly property real tideX: neck && neck.distance > 0 ? (neck.fromX - neck.toX) / neck.distance : 0
    readonly property real tideY: neck && neck.distance > 0 ? (neck.fromY - neck.toY) / neck.distance : 0
    readonly property real tide: closeness * (1 - closeness) * 4 * Motion.carry.tide
    readonly property real lean: size / 2 * dropletScale * tide
    readonly property real meniscusX: centerX + tideX * lean
    readonly property real meniscusY: centerY + tideY * lean

    signal landed()

    x: centerX - size / 2
    y: centerY - size / 2
    width: size
    height: size
    visible: presence > 0.001

    function pickUp(fromX, fromY, fingerX, fingerY) {
        dropAnimation.stop()
        centerX = fromX
        centerY = fromY
        velocityX = 0
        velocityY = 0
        deform = 0
        deformVelocity = 0
        finger = Qt.point(fingerX, fingerY)
        presence = 1
        isLanding = false
        isCarried = true
        holdRelease.stop()
        hold = 1
        liftAnimation.to = 1
        liftAnimation.restart()
    }

    function land(target) {
        landingTarget = target
        isCarried = false
        isLanding = true
        liftAnimation.to = 0
        liftAnimation.restart()
        holdRelease.restart()
    }

    function drop() {
        isCarried = false
        isLanding = false
        dropAnimation.restart()
    }

    function advance(frameTime) {
        const target = isCarried ? finger : landingTarget()
        const character = isCarried ? Motion.liquid.follow : Motion.liquid.dock
        const alongX = Liquid.pull(centerX, velocityX, target.x, character, frameTime, Motion.liquid)
        const alongY = Liquid.pull(centerY, velocityY, target.y, character, frameTime, Motion.liquid)
        const positionX = alongX.value
        const positionY = alongY.value
        const movingX = alongX.velocity
        const movingY = alongY.velocity
        const isResting = Math.hypot(positionX - target.x, positionY - target.y) < Motion.carry.restDistance
            && Math.hypot(movingX, movingY) < Motion.carry.restVelocity
        if (isLanding && isResting) {
            centerX = target.x
            centerY = target.y
            velocityX = 0
            velocityY = 0
            isLanding = false
            landed()
            return
        }
        centerX = positionX
        centerY = positionY
        velocityX = movingX
        velocityY = movingY
        wobble(frameTime)
    }

    function wobble(frameTime) {
        const moveStretch = Math.min(Motion.carry.stretchLimit, speed * Motion.carry.stretchPerVelocity)
        const pullX = Math.cos(Math.atan2(velocityY, velocityX)) * moveStretch + tideX * tide
        const pullY = Math.sin(Math.atan2(velocityY, velocityX)) * moveStretch + tideY * tide
        const wanted = Math.hypot(pullX, pullY)
        if (wanted > 0.01) {
            let turn = Math.atan2(pullY, pullX) - deformAxis
            turn = Math.atan2(Math.sin(2 * turn), Math.cos(2 * turn)) / 2
            deformAxis += turn * Math.min(1, frameTime * 18)
        }
        const shape = Liquid.pull(deform, deformVelocity, wanted, Motion.liquid.droplet, frameTime, Motion.liquid)
        deform = Math.max(-0.35, Math.min(0.6, shape.value))
        deformVelocity = shape.velocity
    }

    FrameAnimation {
        running: carried.isActive
        onTriggered: carried.advance(frameTime)
    }

    NumberAnimation {
        id: liftAnimation
        target: carried
        property: "lift"
        duration: Motion.stateDuration
        easing.type: Easing.OutBack
    }

    NumberAnimation {
        id: holdRelease
        target: carried
        property: "hold"
        to: 0
        duration: Motion.carry.release
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: dropAnimation
        NumberAnimation {
            target: carried
            property: "presence"
            to: 0
            duration: Motion.pill.leaveElement
            easing.type: Easing.InBack
        }
        ScriptAction { script: carried.appId = "" }
    }

    LiquidShape {
        parent: carried.host.liquidShapes
        width: carried.size + 4
        height: carried.size + 4
        x: carried.meniscusX - width / 2
        y: carried.meniscusY - height / 2
        scale: carried.dropletScale
        transform: [
            Rotation {
                origin.x: (carried.size + 4) / 2
                origin.y: (carried.size + 4) / 2
                angle: -carried.deformAxis * 180 / Math.PI
            },
            Scale {
                origin.x: (carried.size + 4) / 2
                origin.y: (carried.size + 4) / 2
                xScale: 1 + carried.deform
                yScale: 1 / (1 + carried.deform)
            },
            Rotation {
                origin.x: (carried.size + 4) / 2
                origin.y: (carried.size + 4) / 2
                angle: carried.deformAxis * 180 / Math.PI
            }
        ]
    }

    Glyph {
        anchors.centerIn: parent
        width: Appearance.taskbar.glyph
        height: Appearance.taskbar.glyph
        visible: carriedIcon.status !== Image.Ready
        name: "app"
        color: Appearance.color.textMuted
        scale: carried.iconScale
        transform: Upright {
            isMirrored: carried.host.isMirrored
            axis: Appearance.taskbar.glyph / 2
        }
    }

    Image {
        id: carriedIcon
        anchors.centerIn: parent
        width: Appearance.taskbar.icon
        height: Appearance.taskbar.icon
        sourceSize: Qt.size(64, 64)
        source: carried.appId.length > 0 ? Toplevels.iconFor(carried.appId) : ""
        smooth: true
        mipmap: true
        scale: carried.iconScale
        transform: Upright {
            isMirrored: carried.host.isMirrored
            axis: Appearance.taskbar.icon / 2
        }
    }
}
