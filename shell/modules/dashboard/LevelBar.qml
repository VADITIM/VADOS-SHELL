import QtQuick
import qs.config

Rectangle {
    id: bar

    property real level: 0
    property bool isShown: false
    property color fill: Appearance.color.levelCool
    property real drawn: isShown ? Math.max(0, Math.min(1, level)) : 0

    radius: width / 2
    color: Appearance.color.textBody

    Behavior on drawn {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.level)
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(bar.width * bar.drawn, parent.height * bar.drawn)
        radius: width / 2
        color: bar.fill

        Behavior on color {
            ColorAnimation {
                duration: Motion.pace(Motion.stateDuration)
            }
        }
    }
}
