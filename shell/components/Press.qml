import QtQuick
import qs.config

QtObject {
    id: press

    property Item target: null
    property bool isPressed: false
    property bool isRaised: false
    property real depth: Motion.press.button
    property real raise: Motion.press.raise
    readonly property real resting: isPressed ? depth : isRaised ? raise : 1

    readonly property NumberAnimation motion: NumberAnimation {
        target: press.target
        property: "scale"
    }

    function play() {
        if (!target)
            return
        motion.stop()
        motion.to = resting
        motion.duration = isPressed ? Motion.press.down : Motion.stateDuration
        motion.easing.type = isPressed ? Easing.OutQuad : Easing.OutBack
        motion.start()
    }

    onRestingChanged: play()
    onTargetChanged: if (target) target.scale = resting
}
