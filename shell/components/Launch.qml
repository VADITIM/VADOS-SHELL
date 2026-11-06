import QtQuick
import qs.config

Item {
    id: launch

    property bool isShown: false
    property var parts: []
    property bool isMirrored: false
    property bool isBare: false
    property rect seed: Qt.rect(0, 0, 0, 0)
    property real panelX: 0
    property real panelY: 0
    property real budX: 0
    property real budY: 0
    property real budLength: 0
    property real jolt: 0
    property var look: Appearance.settings
    property var pace: Motion.settings

    property real material: 1
    property real merge: 0
    property real shoot: 0
    property real pop: 0
    property real bud: 0
    property real extend: 0
    property real collapse: 0
    property real back: 0
    property real body: 1
    property bool isLeaving: false
    property bool isOpened: false
    property int retractDuration: 0
    property var leaveFrom: ({ x: 0, y: 0, width: 0, height: 0, radius: 0, rotation: 0 })

    readonly property bool isActive: isShown || leave.running
    readonly property bool hasMerged: isShown && !isLeaving && merge >= 1
    readonly property bool isBudOut: isOpened && extend > 0.6
    readonly property real seedX: seed.x + seed.width / 2
    readonly property real seedY: seed.y + seed.height / 2
    readonly property real panelCenterX: panelX + look.width / 2
    readonly property real panelCenterY: panelY + look.height / 2

    readonly property real flightDistance: Math.max(1, Math.hypot(panelCenterX - seedX, panelCenterY - seedY))
    readonly property real headingX: (panelCenterX - seedX) / flightDistance
    readonly property real headingY: (panelCenterY - seedY) / flightDistance
    readonly property real heading: Math.atan2(headingY, headingX)
    readonly property real launchX: seedX - headingX * look.crouchShift
    readonly property real launchY: seedY - headingY * look.crouchShift
    readonly property real popStart: look.ball * (1 + pace.inflate)

    readonly property var form: isLeaving ? leaveForm(collapse, back, leaveFrom) : enterForm(merge, shoot, pop, jolt)
    readonly property real formWidth: form.width * body
    readonly property real formHeight: form.height * body

    signal landed()

    function clampUnit(value) {
        return Math.max(0, Math.min(1, value))
    }

    function capsule(centerX, centerY, size, stretch, heading) {
        const along = size * (1 + stretch)
        const across = size / (1 + stretch)
        return { x: centerX, y: centerY, width: along, height: across, radius: Math.min(along, across) / 2, rotation: heading * 180 / Math.PI }
    }

    function flightShare(flight) {
        const carried = pace.shotCarry * flight
        return carried * (2 - carried) / (pace.shotCarry * (2 - pace.shotCarry))
    }

    function flightPoint(flight) {
        const share = flightShare(flight)
        return Qt.point(launchX + (panelCenterX - launchX) * share, launchY + (panelCenterY - launchY) * share)
    }

    function enterForm(merge, shoot, pop, jolt) {
        if (pop > 0) {
            if (pop < pace.impactShare) {
                const impact = pop / pace.impactShare
                const stretch = pace.shotStretch * (1 - pace.shotCarry) * (1 - impact) - pace.impactSquash * Math.sin(Math.PI * impact)
                const push = look.overshoot * Math.sin(Math.PI * impact)
                return capsule(panelCenterX + headingX * push, panelCenterY + headingY * push, look.ball * (1 + pace.inflate * impact), stretch, heading)
            }
            const spread = (pop - pace.impactShare) / (1 - pace.impactShare)
            const opening = 1 - Math.pow(1 - Math.min(1, spread / pace.expandShare), 3)
            const wobble = pace.wave * Math.exp(-pace.waveDecay * spread) * Math.sin(2 * Math.PI * pace.waveCycles * spread)
            const width = (popStart + (look.width - popStart) * opening) * (1 + wobble)
            const height = (popStart + (look.height - popStart) * opening) * (1 - wobble) + jolt
            const radius = Math.min(width / 2, height / 2, popStart / 2 + (look.radius - popStart / 2) * opening)
            return { x: panelCenterX, y: panelCenterY, width: width, height: height, radius: radius, rotation: 0 }
        }
        if (shoot > 0) {
            if (shoot < pace.crouchShare) {
                const crouch = Math.sin(Math.PI / 2 * shoot / pace.crouchShare)
                return capsule(seedX + (launchX - seedX) * crouch, seedY + (launchY - seedY) * crouch, look.ball, -pace.crouchSquash * crouch, heading)
            }
            const flight = (shoot - pace.crouchShare) / (1 - pace.crouchShare)
            const snap = Math.min(1, flight / pace.snapShare)
            const stretch = -pace.crouchSquash + (pace.shotStretch * (1 - pace.shotCarry * flight) + pace.crouchSquash) * snap
            const point = flightPoint(flight)
            return capsule(point.x, point.y, look.ball, stretch, heading)
        }
        const gathered = merge * merge * (3 - 2 * merge)
        return capsule(seedX, seedY, seed.width + (look.ball - seed.width) * gathered, 0, heading)
    }

    function leaveForm(collapse, back, from) {
        if (back <= 0) {
            const width = from.width + (look.ball - from.width) * collapse
            const height = from.height + (look.ball - from.height) * collapse
            const radius = Math.max(0, Math.min(width / 2, height / 2, from.radius + (look.ball / 2 - from.radius) * collapse))
            return { x: from.x, y: from.y, width: width, height: height, radius: radius, rotation: from.rotation }
        }
        return capsule(
            from.x + (seedX - from.x) * back,
            from.y + (seedY - from.y) * back,
            look.ball + (seed.width - look.ball) * back,
            pace.backStretch * Math.pow(back, 2 / 3),
            Math.atan2(seedY - from.y, seedX - from.x))
    }

    function trailForm(index, shoot, pop) {
        const lag = pace.trailLag * (index + 1)
        const size = look.ball * look.trail[index]
        if (pop > 0) {
            const absorbed = Math.min(1, pop / pace.impactShare)
            const rest = flightPoint(1 - lag)
            return { x: rest.x + (form.x - rest.x) * absorbed, y: rest.y + (form.y - rest.y) * absorbed, size: size * (1 - absorbed) }
        }
        const flight = (shoot - pace.crouchShare) / (1 - pace.crouchShare)
        if (flight <= 0)
            return { x: launchX, y: launchY, size: 0 }
        const point = flightPoint(Math.max(0, flight - lag))
        return { x: point.x, y: point.y, size: size * Math.min(1, flight / lag) }
    }

    function splashForm(index, pop) {
        const spread = (pop - pace.impactShare) / (1 - pace.impactShare)
        if (spread <= 0 || spread >= pace.splashShare)
            return { x: panelCenterX, y: panelCenterY, size: 0 }
        const angle = 2 * Math.PI * (index + 0.5) / look.splashCount
        const edge = Math.min(look.width / 2 / Math.max(0.001, Math.abs(Math.cos(angle))), look.height / 2 / Math.max(0.001, Math.abs(Math.sin(angle))))
        const opening = 1 - Math.pow(1 - Math.min(1, spread / pace.expandShare), 3)
        const settle = clampUnit((spread - pace.expandShare) / (pace.splashShare - pace.expandShare))
        const distance = (popStart / 2 + (edge - popStart / 2) * opening) * (1 + (look.splashReach - 1) * (1 - settle))
        return { x: panelCenterX + Math.cos(angle) * distance, y: panelCenterY + Math.sin(angle) * distance, size: look.splash * (1 - settle) }
    }

    function start() {
        leave.stop()
        isLeaving = false
        isOpened = false
        merge = 0
        shoot = 0
        pop = 0
        bud = 0
        extend = 0
        collapse = 0
        back = 0
        body = 1
        material = isBare ? 0 : 1
        enter.restart()
    }

    function finish() {
        enter.stop()
        leaveFrom = form
        retractDuration = bud > 0 ? pace.retract : 0
        isOpened = false
        isLeaving = true
        collapse = 0
        back = 0
        leave.restart()
    }

    onIsShownChanged: isShown ? start() : finish()
    Component.onCompleted: if (isShown) start()

    anchors.fill: parent

    Gather {
        parts: launch.parts
        isMirrored: launch.isMirrored
        isShown: !launch.isLeaving
        seedX: launch.seedX
        seedY: launch.seedY
        merge: launch.merge
        lag: launch.pace.mergeLag
    }

    Repeater {
        model: launch.look.trail.length

        LiquidShape {
            required property int index
            readonly property var drop: launch.trailForm(index, launch.shoot, launch.pop)
            visible: !launch.isLeaving && drop.size > 0.5
            width: drop.size
            height: drop.size
            x: drop.x - width / 2
            y: drop.y - height / 2
        }
    }

    Repeater {
        model: launch.look.splashCount

        LiquidShape {
            required property int index
            readonly property var drop: launch.splashForm(index, launch.pop)
            visible: !launch.isLeaving && drop.size > 0.5
            width: drop.size
            height: drop.size
            x: drop.x - width / 2
            y: drop.y - height / 2
        }
    }

    Rectangle {
        visible: launch.isActive && launch.formWidth > 0.5 && launch.formHeight > 0.5
        color: "white"
        antialiasing: true
        width: launch.formWidth
        height: launch.formHeight
        radius: launch.form.radius * launch.body
        rotation: launch.form.rotation
        x: launch.form.x - width / 2
        y: launch.form.y - height / 2
    }

    LiquidShape {
        readonly property real size: launch.look.tabBar.width * (launch.look.budSeed + (1 - launch.look.budSeed) * launch.bud)
        readonly property real startX: launch.panelX + launch.look.tabBar.width / 2
        visible: launch.bud > 0.001
        width: size
        height: size + (launch.budLength - launch.look.tabBar.width) * launch.extend
        x: startX + (launch.budX + launch.look.tabBar.width / 2 - startX) * launch.bud - width / 2
        y: launch.budY - height / 2
    }

    SequentialAnimation {
        id: enter

        ParallelAnimation {
            NumberAnimation {
                target: launch
                property: "merge"
                to: 1
                duration: launch.pace.merge
            }
            NumberAnimation {
                target: launch
                property: "material"
                to: 1
                duration: launch.pace.merge
                easing.type: Easing.OutQuad
            }
        }
        NumberAnimation {
            target: launch
            property: "shoot"
            to: 1
            duration: launch.pace.shoot
        }
        NumberAnimation {
            target: launch
            property: "pop"
            to: launch.pace.contentShare
            duration: launch.pace.pop * launch.pace.contentShare
        }
        ScriptAction { script: launch.isOpened = true }
        ParallelAnimation {
            NumberAnimation {
                target: launch
                property: "pop"
                to: 1
                duration: launch.pace.pop * (1 - launch.pace.contentShare)
            }
            SequentialAnimation {
                PauseAnimation { duration: launch.pace.budDelay }
                NumberAnimation {
                    target: launch
                    property: "bud"
                    to: 1
                    duration: launch.pace.bud
                    easing.type: Easing.OutBack
                }
                NumberAnimation {
                    target: launch
                    property: "extend"
                    to: 1
                    duration: launch.pace.extend
                    easing.type: Easing.OutBack
                }
            }
        }
    }

    SequentialAnimation {
        id: leave

        ParallelAnimation {
            NumberAnimation {
                target: launch
                property: "extend"
                to: 0
                duration: launch.retractDuration
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: launch
                property: "bud"
                to: 0
                duration: launch.retractDuration
                easing.type: Easing.InBack
            }
        }
        NumberAnimation {
            target: launch
            property: "collapse"
            to: 1
            duration: launch.pace.collapse
            easing.type: Easing.InBack
        }
        NumberAnimation {
            target: launch
            property: "back"
            to: 1
            duration: launch.pace.flyBack
            easing.type: Easing.InCubic
        }
        ScriptAction { script: launch.landed() }
        NumberAnimation {
            target: launch
            property: "body"
            to: 0
            duration: launch.pace.handBack
            easing.type: Easing.InQuad
        }
    }
}
