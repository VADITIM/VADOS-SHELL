import QtQuick
import qs.config
import qs.components

Item {
    id: track

    property real value: 0
    property bool isMuted: false
    property bool hasSteps: false
    property bool isFilled: true
    readonly property real stepsWidth: hasSteps ? less.width + more.width + Appearance.extension.rowGap * 2 : 0

    signal moved(real value)

    implicitWidth: Appearance.extension.trackWidth + stepsWidth
    implicitHeight: Math.max(slider.implicitHeight, hasSteps ? less.height : 0)

    GlyphButton {
        id: less
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: track.hasSteps
        label: "−"
        onClicked: slider.nudge(-1)
    }

    Slider {
        id: slider
        anchors.left: track.hasSteps ? less.right : parent.left
        anchors.right: track.hasSteps ? more.left : parent.right
        anchors.leftMargin: track.hasSteps ? Appearance.extension.rowGap : 0
        anchors.rightMargin: track.hasSteps ? Appearance.extension.rowGap : 0
        anchors.verticalCenter: parent.verticalCenter
        value: track.isFilled ? track.value : 0
        isMuted: track.isMuted
        look: ({
            track: Appearance.extension.track,
            grab: Appearance.extension.trackGrab,
            step: Appearance.extension.sliderStep
        })
        pace: ({
            settle: Motion.extension.slide,
            thicken: Motion.extension.trackHeld
        })
        onMoved: value => track.moved(value)
    }

    GlyphButton {
        id: more
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: track.hasSteps
        label: "+"
        onClicked: slider.nudge(1)
    }
}
