import QtQuick
import qs.config
import "../utils/Geometry.js" as Geometry

Item {
    id: slider

    required property var look
    required property var pace
    property real value: 0
    property bool isMuted: false
    property real fromValue: 0
    readonly property real shown: Geometry.clampUnit(value)
    readonly property bool isDragging: gesture.isDragging
    readonly property bool isHeld: gesture.pressed
    readonly property color ink: isMuted ? Appearance.color.textFaint : Appearance.color.accent
    readonly property real reach: width - knob.width

    signal moved(real value)

    function nudge(direction) {
        const stepped = Math.round((shown + direction * look.step) / look.step) * look.step
        moved(Geometry.clampUnit(stepped))
    }

    property real thickness: isHeld ? look.track * pace.thicken : look.track

    implicitHeight: Math.max(look.knob * pace.held, look.track * pace.thicken)

    Behavior on thickness {
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: slider.thickness
        radius: height / 2
        color: Appearance.color.hairline
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: knob.x + knob.width / 2
        height: slider.thickness
        radius: height / 2
        color: Qt.rgba(slider.ink.r, slider.ink.g, slider.ink.b, slider.look.fillAlpha)
    }

    Rectangle {
        id: knob
        anchors.verticalCenter: parent.verticalCenter
        width: slider.look.knob
        height: width
        radius: width / 2
        x: slider.shown * slider.reach
        color: Appearance.color.ground
        border.width: slider.look.ring
        border.color: slider.ink
        scale: slider.isHeld ? slider.pace.held : 1

        Behavior on x {
            enabled: !slider.isDragging
            NumberAnimation {
                duration: Motion.pace(slider.pace.settle)
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Motion.pace(Motion.stateDuration)
                easing.type: Easing.OutBack
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Motion.pace(Motion.stateDuration)
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
            if (isDragging && slider.reach > 0)
                slider.moved(Geometry.clampUnit(slider.fromValue + travelX / slider.reach))
        }
    }
}
