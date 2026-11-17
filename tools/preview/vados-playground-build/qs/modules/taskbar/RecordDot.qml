import QtQuick
import qs.config
import qs.components

Item {
    id: dot

    property real size: Appearance.capture.dot
    property bool isPaused: false
    property bool isPulsing: false
    property color pauseColor: Appearance.color.textBody
    property real pulse: 1

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.centerIn: parent
        visible: !dot.isPaused
        width: dot.size
        height: width
        radius: width / 2
        color: Appearance.capture.tint
        scale: dot.pulse
    }

    Glyph {
        anchors.centerIn: parent
        visible: dot.isPaused
        width: dot.size * 1.6
        height: width
        name: "pause"
        color: dot.pauseColor
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        running: dot.isPulsing && !dot.isPaused && !Motion.isReduced
        loops: Animation.Infinite
        onRunningChanged: {
            if (!running)
                dot.pulse = 1
        }

        NumberAnimation {
            target: dot
            property: "pulse"
            to: 1 - Motion.capture.pulseDepth
            duration: Motion.pace(Motion.capture.pulse / 2)
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: dot
            property: "pulse"
            to: 1
            duration: Motion.pace(Motion.capture.pulse / 2)
            easing.type: Easing.InOutSine
        }
    }
}
