import QtQuick
import qs.config
import qs.components

Gesture {
    required property Item host
    property bool isWheelFolding: true

    signal wheelTaken(real delta)

    threshold: Motion.fold.threshold
    isHorizontal: false
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onCrossed: (travelX, travelY) => host.foldIdles(travelY > 0)
    onWheel: wheel => {
        const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y
        if (isWheelFolding)
            host.scrollIdles(delta)
        else
            wheelTaken(delta)
    }
}
