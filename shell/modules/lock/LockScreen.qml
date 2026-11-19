import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Locking.js" as Locking

Item {
    id: lockScreen

    property bool isLocked: false
    property bool isMain: true
    property var layout: []
    property string wallpaper: ""
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
    readonly property bool isOpen: phase === "entering" || phase === "active"
    readonly property var placements: isMain ? Locking.layoutOf(layout) : []
    readonly property var frames: placements.map(placement => Locking.rectOf(placement, width, height, look.gap))
    readonly property var delays: Locking.delays(placements.length, pace.contentStagger, Math.random)
    readonly property int contentSpan: delays.reduce((longest, delay) => Math.max(longest, delay), 0) + pace.contentStagger
    readonly property int profileIndex: placements.findIndex(placement => placement.key === "profile")
    readonly property var profileFrame: profileIndex >= 0 ? frames[profileIndex] : null
    readonly property string bumpKey: ["call", "media", "recording", "notifications"].find(key => Activities.liveKeys.indexOf(key) >= 0) ?? ""
    readonly property bool hasBump: bumpKey.length > 0 && profileIndex >= 0 && isContentShownAt(profileIndex) && !fading.isThrown
    property real bumpShare: hasBump ? 1 : 0
    readonly property bool isReady: isMain ? placements.some((placement, index) => isContentShownAt(index)) : phase === "active"
    readonly property bool isDark: cover.opacity >= 1
    readonly property var emptyFrame: ({ x: 0, y: 0, width: 0, height: 0 })

    function isContentShownAt(index) {
        if (arrival.isLanded)
            return true
        return arrival.isThrown && arrival.share * contentSpan >= (delays[index] ?? 0)
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
        id: arrival
        label: "lock contents"
        isThrown: lockScreen.isOpen
        span: lockScreen.contentSpan
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
        isImmediate: true
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
        isShown: lockScreen.isPresent && !lockScreen.isDark && lockScreen.placements.length > 0
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: lockScreen.look.melt
        opacity: 1 - fading.share

        Item {
            parent: liquid.shapes
            anchors.fill: parent

            Repeater {
                model: lockScreen.placements

                Squircle {
                    required property int index
                    readonly property var frame: lockScreen.frames[index] ?? lockScreen.emptyFrame

                    color: "white"
                    corner: lockScreen.look.corner
                    x: frame.x
                    y: frame.y
                    width: Math.max(1, frame.width)
                    height: Math.max(1, frame.height)
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
