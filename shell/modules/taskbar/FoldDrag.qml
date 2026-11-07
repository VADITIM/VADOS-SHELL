import QtQuick
import qs.config
import qs.components

Gesture {
    required property Item host

    threshold: Motion.fold.threshold
    isHorizontal: false
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onCrossed: (travelX, travelY) => host.foldIdles(travelY > 0)
}
