import QtQuick
import qs.config
import qs.components
import "../../utils/Locking.js" as Locking
import "../../utils/Veil.js" as Veil
import "../../utils/Sling.js" as Sling

Item {
    id: veil

    property bool isShown: false
    property bool isInstant: false
    property bool isMain: true
    property var layout: []
    property string wallpaper: ""
    property var parts: []
    property var groups: ({})
    property bool isMirrored: false
    property bool hasLanded: false
    property bool canHandOff: true
    property bool isSmashing: false

    readonly property var look: Appearance.lock
    readonly property var pace: Motion.lock
    readonly property string phase: lifecycle.phase
    readonly property bool isPresent: lifecycle.isPresent
    readonly property bool isRising: lifecycle.isShowing
    readonly property bool isReturning: lifecycle.isLeaving
    readonly property bool isCovered: phase === "active"
    readonly property var placements: isMain ? Locking.layoutOf(layout) : []
    readonly property var frames: placements.map(placement => Locking.rectOf(placement, width, height, look.gap))
    readonly property real spineEdge: parts.length > 0 ? parts[0].x + parts[0].width / 2 : Appearance.taskbar.margin + Appearance.taskbar.thickness / 2
    readonly property real gatherEdge: spineEdge + look.gatherReach
    readonly property var placedParts: (parts ?? []).map(part => Veil.placedOf(part, width, isMirrored))
    property var enterSources: []
    property var leaveSources: []
    property int enterSeed: 1
    property int leaveSeed: 1
    readonly property var setup: ({
        width: width,
        height: height,
        isMirrored: isMirrored,
        frames: frames,
        groups: groups,
        look: look,
        pace: pace,
        knock: Motion.liquid.knock,
        snap: Motion.liquid.snap
    })
    readonly property bool isPlanning: isShown || isPresent
    readonly property var restingPlan: ({ total: 0, handOff: 0, shots: [], arrivals: [] })
    readonly property var enterPlan: !isPlanning ? restingPlan : Sling.enterOf(Object.assign({}, setup, {
        sources: enterSources.length > 0 ? enterSources : placedParts,
        gather: Qt.point(isMirrored ? width - gatherEdge : gatherEdge, height / 2)
    }), enterSeed)
    readonly property var leavePlan: !isPlanning ? restingPlan : Sling.leaveOf(Object.assign({}, setup, {
        sources: leaveSources.length > 0 ? leaveSources : frames,
        isSmashing: isSmashing
    }), leaveSeed)
    readonly property real enterClock: isCovered || isInstant ? enterPlan.total : rising.share * enterPlan.total
    readonly property real leaveClock: returning.share * leavePlan.total
    readonly property var stage: isReturning ? Sling.leaveAt(leavePlan, leaveClock, setup)
        : isRising ? Sling.enterAt(enterPlan, enterClock, setup)
        : ({ drops: [], core: Sling.hiddenForm(), bubbles: [], bodies: [], pills: [] })
    readonly property var visitor: isReturning && leaveClock > leavePlan.handOff && leavePlan.shots.length > 0 ? ({
        x: -width * 4,
        y: 0,
        width: 0,
        height: 0,
        isHandedOff: false,
        hasReleased: returning.isLanded,
        isReleasing: true,
        release: Sling.releaseOf(leavePlan, leaveClock),
        arrivals: leavePlan.arrivals
    }) : null
    readonly property bool isReady: isCovered || (isRising && slice.coverage >= pace.readyCover)
    readonly property bool isSettled: isRising && slice.isCovered && rising.isLanded
    readonly property bool isGone: isReturning && slice.isCleared && returning.isLanded

    signal covered()
    signal landed()

    function bodyOf(index) {
        return stage.bodies[index] ?? Sling.hiddenForm()
    }

    function seedOf() {
        return Math.floor(Math.random() * 4294967295)
    }

    function land() {
        if (hasLanded)
            return
        hasLanded = true
        landed()
    }

    onIsShownChanged: {
        const forms = isPresent && !isInstant ? Sling.formsOf(stage) : []
        if (isShown) {
            enterSources = forms
            enterSeed = seedOf()
        } else {
            leaveSources = forms
            leaveSeed = seedOf()
            isSmashing = !canHandOff
        }
        lifecycle.send(isShown ? "show" : "hide")
    }
    onIsSettledChanged: if (isSettled) Qt.callLater(lifecycle.send, "entered")
    onIsGoneChanged: if (isGone) Qt.callLater(lifecycle.send, "exited")
    Component.onCompleted: {
        enterSeed = seedOf()
        leaveSeed = seedOf()
        if (isShown)
            lifecycle.send("show")
    }

    Lifecycle {
        id: lifecycle
        name: "lock veil"
        onMoved: (from, to, event) => {
            if (to === "preparing") {
                veil.hasLanded = false
                send("prepared")
            } else if (to === "active") {
                veil.covered()
            } else if (to === "idle") {
                veil.leaveSources = []
                veil.enterSources = []
                veil.land()
            }
        }
    }

    Throw {
        id: rising
        label: "lock enter"
        isThrown: veil.isRising
        span: veil.isInstant ? 0 : veil.enterPlan.total
        easing: Easing.Linear
    }

    Throw {
        id: returning
        label: "lock leave"
        isThrown: veil.isReturning
        span: veil.leavePlan.total
        easing: Easing.Linear
    }

    Cut {
        id: slice
        anchors.fill: parent
        label: "lock slice"
        isShown: veil.isRising
        isInstant: veil.isInstant
        isMirrored: veil.isMirrored
        lean: veil.look.cutLean
        enterSpan: veil.pace.slice
        leaveSpan: veil.pace.sliceAway
        edgeWidth: veil.look.cutLine
        edgeColor: Appearance.color.hairline

        Backdrop {
            anchors.fill: parent
            isShown: slice.coverage > 0
            source: veil.wallpaper
            blur: veil.look.blur
            detail: veil.look.backdropScale
            ground: Appearance.color.shadow
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.color.shadow
            opacity: veil.look.dim
        }
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: veil.isPresent
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: veil.look.melt

        Item {
            parent: liquid.shapes
            anchors.fill: parent

            Repeater {
                model: veil.stage.drops.length

                Squircle {
                    required property int index
                    readonly property var form: veil.stage.drops[index] ?? Sling.hiddenForm()

                    visible: form.isShown
                    color: "white"
                    corner: form.corner
                    x: form.x
                    y: form.y
                    width: Math.max(1, form.width)
                    height: Math.max(1, form.height)
                    rotation: form.rotation
                }
            }

            LiquidShape {
                visible: veil.stage.core.isShown
                x: veil.stage.core.x
                y: veil.stage.core.y
                width: veil.stage.core.width
                height: veil.stage.core.height
                rotation: veil.stage.core.rotation
            }

            Repeater {
                model: veil.frames.length

                Squircle {
                    required property int index
                    readonly property var form: veil.bodyOf(index)

                    visible: form.isShown
                    color: "white"
                    corner: form.corner
                    x: form.x
                    y: form.y
                    width: Math.max(1, form.width)
                    height: Math.max(1, form.height)
                    rotation: form.rotation
                }
            }

            Repeater {
                model: veil.stage.pills.length

                LiquidShape {
                    required property int index
                    readonly property var form: veil.stage.pills[index] ?? Sling.hiddenForm()

                    visible: form.isShown
                    x: form.x
                    y: form.y
                    width: form.width
                    height: form.height
                    rotation: form.rotation
                }
            }

            Repeater {
                model: veil.stage.bubbles.length

                LiquidShape {
                    required property int index
                    readonly property var form: veil.stage.bubbles[index] ?? Sling.hiddenForm()

                    visible: form.isShown
                    x: form.x
                    y: form.y
                    width: form.width
                    height: form.height
                }
            }
        }
    }
}
