import QtQuick
import qs.config

Item {
    id: sweep

    property bool isOn: false
    property color fill: Appearance.extension.pickedWash
    property real start: 0
    property real finish: 0
    property bool isSnapping: false

    onIsOnChanged: {
        if (isOn) {
            isSnapping = true
            start = 0
            finish = 0
            isSnapping = false
            finish = 1
        } else {
            start = 1
        }
    }

    Component.onCompleted: {
        isSnapping = true
        start = isOn ? 0 : 1
        finish = 1
        isSnapping = false
    }

    Rectangle {
        x: sweep.start * sweep.width
        width: (sweep.finish - sweep.start) * sweep.width
        height: sweep.height
        radius: height / 2
        color: sweep.fill
        visible: width > 0.5
    }

    Behavior on start {
        enabled: !sweep.isSnapping
        NumberAnimation {
            duration: Motion.pace(Motion.extension.sweep)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on finish {
        enabled: !sweep.isSnapping
        NumberAnimation {
            duration: Motion.pace(Motion.extension.sweep)
            easing.type: Easing.OutCubic
        }
    }
}
