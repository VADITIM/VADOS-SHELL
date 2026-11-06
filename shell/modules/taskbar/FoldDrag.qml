import QtQuick
import qs.config

MouseArea {
    id: drag

    required property Item host
    property real pressY: 0
    property bool hasFolded: false

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => {
        pressY = mouse.y
        hasFolded = false
    }
    onPositionChanged: mouse => {
        if (!pressed || hasFolded)
            return
        const travel = mouse.y - pressY
        if (Math.abs(travel) < Motion.fold.threshold)
            return
        hasFolded = true
        host.foldIdles(travel > 0)
    }
}
