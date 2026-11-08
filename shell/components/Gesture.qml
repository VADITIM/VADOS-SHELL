import QtQuick
import qs.config

MouseArea {
    id: gesture

    property real threshold: Motion.gesture.slop
    property bool isHorizontal: true
    property bool isVertical: true
    property int dragButtons: Qt.LeftButton
    property point pressPoint: Qt.point(0, 0)
    property real travelX: 0
    property real travelY: 0
    property real velocityX: 0
    property real velocityY: 0
    property bool isDragging: false
    property bool canDrag: false
    property real sampleX: 0
    property real sampleY: 0
    property real sampleTime: 0
    readonly property real travel: Math.hypot(isHorizontal ? travelX : 0, isVertical ? travelY : 0)

    signal moved(real travelX, real travelY)
    signal crossed(real travelX, real travelY)
    signal thrown(real travelX, real travelY, real velocityX, real velocityY)
    signal tapped(var mouse)
    signal ended()

    function sample(x, y) {
        const now = Date.now()
        const elapsed = (now - sampleTime) / 1000
        if (elapsed > 0) {
            const blend = Motion.gesture.velocityBlend
            velocityX += ((x - sampleX) / elapsed - velocityX) * blend
            velocityY += ((y - sampleY) / elapsed - velocityY) * blend
        }
        sampleX = x
        sampleY = y
        sampleTime = now
    }

    function finish() {
        isDragging = false
        canDrag = false
        ended()
    }

    onPressed: mouse => {
        pressPoint = Qt.point(mouse.x, mouse.y)
        travelX = 0
        travelY = 0
        velocityX = 0
        velocityY = 0
        isDragging = false
        canDrag = (mouse.button & dragButtons) !== 0
        sampleX = mouse.x
        sampleY = mouse.y
        sampleTime = Date.now()
    }
    onPositionChanged: mouse => {
        if (!pressed || !canDrag)
            return
        travelX = mouse.x - pressPoint.x
        travelY = mouse.y - pressPoint.y
        sample(mouse.x, mouse.y)
        if (!isDragging && travel >= threshold) {
            isDragging = true
            crossed(travelX, travelY)
        }
        moved(travelX, travelY)
    }
    onReleased: mouse => {
        if (isDragging)
            thrown(travelX, travelY, velocityX, velocityY)
        else if (containsMouse)
            tapped(mouse)
        finish()
    }
    onCanceled: {
        if (isDragging)
            thrown(travelX, travelY, 0, 0)
        finish()
    }
}
