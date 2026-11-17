import QtQuick
import qs.config
import "../utils/Geometry.js" as Geometry

Item {
    id: slider

    required property var look
    required property var pace
    property real value: 0
    property bool isMuted: false
    property bool canScroll: false
    property real fromValue: 0
    readonly property real shown: Geometry.clampUnit(value)
    readonly property bool isDragging: gesture.isDragging
    readonly property bool isHeld: gesture.pressed
    readonly property color ink: isMuted ? Appearance.color.textFaint : Appearance.color.accent
    property real thickness: isHeld ? look.track * pace.thicken : look.track

    signal moved(real value)
    signal scrolled(real steps)

    function nudge(direction) {
        const stepped = Math.round((shown + direction * look.step) / look.step) * look.step
        moved(Geometry.clampUnit(stepped))
    }

    implicitHeight: Math.max(look.track * pace.thicken, look.grab)

    Behavior on thickness {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: bar
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: slider.thickness
        radius: height / 2
        color: Appearance.color.hairline

        Rectangle {
            width: Math.min(bar.width, Math.max(bar.height, bar.width * slider.shown))
            height: parent.height
            radius: height / 2
            color: slider.ink

            Behavior on width {
                enabled: !slider.isDragging
                NumberAnimation {
                    duration: Motion.pace(slider.pace.settle)
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.stateDuration)
                }
            }
        }
    }

    Gesture {
        id: gesture
        anchors.fill: parent
        isVertical: false
        cursorShape: Qt.SizeHorCursor
        onCrossed: slider.fromValue = slider.shown
        onMoved: travelX => {
            if (isDragging && slider.width > 0)
                slider.moved(Geometry.clampUnit(slider.fromValue + travelX / slider.width))
        }
        onWheel: wheel => {
            wheel.accepted = slider.canScroll
            if (slider.canScroll)
                slider.scrolled(wheel.angleDelta.y / 120)
        }
    }
}
