import QtQuick
import qs.config

Item {
    id: bars

    property bool isRunning: false
    property color color: Appearance.color.accent
    property real phase: 0
    property real level: isRunning ? 1 : 0

    implicitWidth: Appearance.activity.barCount * Appearance.activity.bar + (Appearance.activity.barCount - 1) * Appearance.activity.barGap
    implicitHeight: Appearance.activity.barHeight

    Behavior on level {
        NumberAnimation {
            duration: Motion.stateDuration
            easing.type: Easing.OutQuad
        }
    }

    NumberAnimation on phase {
        from: 0
        to: 1
        duration: Motion.activity.bars
        loops: Animation.Infinite
        running: bars.level > 0
    }

    Row {
        spacing: Appearance.activity.barGap

        Repeater {
            model: Appearance.activity.barCount

            Rectangle {
                required property int index
                readonly property real wave: Math.abs(Math.sin((bars.phase + index * Motion.activity.barOffset) * Math.PI))
                readonly property real share: Motion.activity.barRest + (1 - Motion.activity.barRest) * wave * bars.level
                width: Appearance.activity.bar
                height: Appearance.activity.bar + (bars.implicitHeight - Appearance.activity.bar) * share
                y: (bars.implicitHeight - height) / 2
                radius: width / 2
                color: bars.color
            }
        }
    }
}
