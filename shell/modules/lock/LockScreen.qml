import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Locking.js" as Locking
import "../../utils/Liquid.js" as Liquid
import "../../utils/Geometry.js" as Geometry

Item {
    id: lockScreen

    property bool isLocked: false
    property bool isMain: true
    property var layout: []
    property string wallpaper: ""
    property var parts: []
    property var origin: null
    property bool isMirrored: false
    property int passwordLength: 0
    property bool isChecking: false
    property string message: ""
    property bool isMessageError: false
    property bool isBlank: false
    property string profileName: ""
    property string profilePicture: ""

    readonly property var look: Appearance.lock
    readonly property var pace: Motion.lock
    readonly property string phase: lifecycle.phase
    readonly property bool isPresent: lifecycle.isPresent
    readonly property bool isOpen: phase === "entering" || phase === "active" || phase === "exiting"
    readonly property var placements: isMain ? Locking.layoutOf(layout) : []
    readonly property var frames: placements.map(placement => Locking.rectOf(placement, width, height, look.gap))
    readonly property var delays: Locking.delays(placements.length, pace.stagger, Math.random)
    readonly property int longestDelay: delays.reduce((longest, delay) => Math.max(longest, delay), 0)
    readonly property int scatterSpan: pace.scatter + longestDelay
    readonly property real contentAt: Liquid.arrival(Motion.liquid.sling) * 1000 - pace.contentLead
    readonly property point center: Qt.point(width / 2, height / 2)
    readonly property point edgeSeed: origin ?? Qt.point(Appearance.taskbar.thickness / 2, height / 2)
    readonly property point seed: Qt.point(isMirrored ? width - edgeSeed.x : edgeSeed.x, edgeSeed.y)
    readonly property point target: isMain ? center : seed
    readonly property point control: Qt.point(Geometry.mix(seed.x, target.x, 0.5), Math.min(seed.y, target.y) - height * look.arcLift)
    readonly property point dropPoint: Geometry.arcAt(seed, control, target, sling.share)
    readonly property point dropAhead: Geometry.arcAt(seed, control, target, Math.min(1, sling.share + look.headingStep))
    readonly property real fillSize: isMain ? look.fill : 0
    readonly property real dropSize: scatter.isThrown ? fillSize * (1 - Geometry.clampUnit(scatter.share * scatterSpan / pace.scatter))
        : filling.isThrown ? Geometry.mix(look.drop, fillSize, filling.share)
        : look.drop * Geometry.clampUnit(gathering.share * look.dropGrowth)
    readonly property real stretch: sling.isThrown && !sling.isLanded ? Math.sin(Math.PI * sling.share) * look.stretchLimit : 0
    readonly property real heading: Geometry.headingOf(dropPoint.x, dropPoint.y, dropAhead.x, dropAhead.y) * 180 / Math.PI
    readonly property int profileIndex: placements.findIndex(placement => placement.key === "profile")
    readonly property var profileFrame: profileIndex >= 0 ? frames[profileIndex] : null
    readonly property string bumpKey: ["call", "media", "recording", "notifications"].find(key => Activities.liveKeys.indexOf(key) >= 0) ?? ""
    readonly property bool hasBump: bumpKey.length > 0 && profileIndex >= 0 && isContentShownAt(profileIndex) && !fading.isThrown
    property real bumpShare: hasBump ? 1 : 0
    readonly property bool isReady: isMain ? placements.some((placement, index) => isContentShownAt(index)) : phase === "active"
    readonly property bool isDark: cover.opacity >= 1
    readonly property var emptyFrame: ({ x: 0, y: 0, width: 0, height: 0 })

    function progressOf(index) {
        if (scatter.isLanded)
            return 1
        if (!scatter.isThrown)
            return 0
        return Liquid.rise(Motion.liquid.sling, Math.max(0, scatter.share * scatterSpan - (delays[index] ?? 0)) / 1000)
    }

    function isContentShownAt(index) {
        if (scatter.isLanded)
            return true
        return scatter.isThrown && scatter.share * scatterSpan - (delays[index] ?? 0) >= contentAt
    }

    Behavior on bumpShare {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.OutBack
        }
    }

    Lifecycle {
        id: lifecycle
        name: "lock"
        onMoved: (from, to, event) => {
            if (to === "preparing")
                send("prepared")
        }
    }

    Throw {
        id: gathering
        label: "lock gather"
        isThrown: lockScreen.isOpen
        span: lockScreen.pace.gather
    }

    Throw {
        id: sling
        label: "lock sling"
        isThrown: gathering.isLanded
        span: lockScreen.pace.sling
    }

    Throw {
        id: filling
        label: "lock fill"
        isThrown: sling.isLanded
        span: lockScreen.pace.fill
        easing: Easing.OutBack
        overshoot: lockScreen.pace.fillBack
    }

    Throw {
        id: scatter
        label: "lock scatter"
        isThrown: filling.isLanded
        span: lockScreen.scatterSpan
        easing: Easing.Linear
        onIsLandedChanged: if (isLanded) Qt.callLater(lifecycle.send, "entered")
    }

    Throw {
        id: fading
        label: "lock leave"
        isThrown: lifecycle.isLeaving
        span: lockScreen.pace.evaporate
        onIsLandedChanged: if (isLanded) Qt.callLater(lifecycle.send, "exited")
    }

    onIsLockedChanged: lifecycle.send(isLocked ? "show" : "hide")
    Component.onCompleted: if (isLocked) lifecycle.send("show")

    Backdrop {
        anchors.fill: parent
        isShown: !lockScreen.isDark
        source: lockScreen.wallpaper
        blur: lockScreen.look.blur
        detail: lockScreen.look.backdropScale
        ground: Appearance.color.shadow
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.color.shadow
        opacity: lockScreen.look.dim
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: lockScreen.isPresent && !lockScreen.isDark
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: lockScreen.look.melt
        opacity: 1 - fading.share

        Gather {
            parent: liquid.shapes
            parts: lockScreen.parts
            isMirrored: lockScreen.isMirrored
            isShown: lockScreen.isOpen && !gathering.isLanded
            seedX: lockScreen.seed.x
            seedY: lockScreen.seed.y
            merge: gathering.share
        }

        LiquidShape {
            parent: liquid.shapes
            visible: lockScreen.isOpen && lockScreen.dropSize > 0.5
            width: lockScreen.dropSize * (1 + lockScreen.stretch)
            height: lockScreen.dropSize * (1 - lockScreen.stretch / 2)
            x: lockScreen.dropPoint.x - width / 2
            y: lockScreen.dropPoint.y - height / 2
            rotation: lockScreen.heading
        }

        Item {
            parent: liquid.shapes
            anchors.fill: parent

            Repeater {
                model: lockScreen.placements

                Squircle {
                    required property int index
                    readonly property var frame: lockScreen.frames[index] ?? lockScreen.emptyFrame
                    readonly property real progress: lockScreen.progressOf(index)
                    readonly property real centerX: Geometry.mix(lockScreen.center.x, frame.x + frame.width / 2, progress)
                    readonly property real centerY: Geometry.mix(lockScreen.center.y, frame.y + frame.height / 2, progress)

                    visible: scatter.isThrown
                    color: "white"
                    corner: lockScreen.look.corner
                    width: Math.max(1, Geometry.mix(lockScreen.look.drop, frame.width, progress))
                    height: Math.max(1, Geometry.mix(lockScreen.look.drop, frame.height, progress))
                    x: centerX - width / 2
                    y: centerY - height / 2
                }
            }

            LiquidShape {
                visible: lockScreen.profileFrame !== null && lockScreen.bumpShare > 0.01
                width: lockScreen.look.bumpWidth * lockScreen.bumpShare
                height: lockScreen.look.bumpHeight * lockScreen.bumpShare
                x: lockScreen.profileFrame ? lockScreen.profileFrame.x + (lockScreen.profileFrame.width - width) / 2 : 0
                y: lockScreen.profileFrame ? lockScreen.profileFrame.y - height + lockScreen.look.bumpGap : 0
            }
        }
    }

    Repeater {
        model: lockScreen.placements

        Item {
            id: slot

            required property var modelData
            required property int index
            readonly property var frame: lockScreen.frames[index] ?? lockScreen.emptyFrame

            x: frame.x
            y: frame.y
            width: frame.width
            height: frame.height
            opacity: 1 - fading.share

            Loader {
                id: content
                anchors.fill: parent
                source: Qt.resolvedUrl(Locking.fileOf(slot.modelData.key))
            }

            Binding {
                target: content.item
                property: "host"
                value: lockScreen
                when: content.item !== null
            }

            Binding {
                target: content.item
                property: "isShown"
                value: lockScreen.isContentShownAt(slot.index) && !fading.isThrown
                when: content.item !== null
            }
        }
    }

    Rectangle {
        id: cover
        anchors.fill: parent
        color: Appearance.color.shadow
        opacity: lockScreen.isBlank ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.pace(lockScreen.pace.blankFade)
                easing.type: Easing.InOutQuad
            }
        }
    }
}
