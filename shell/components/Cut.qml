import QtQuick
import qs.config
import "../utils/Veil.js" as Veil
import "../utils/Playing.js" as Playing

Item {
    id: cut

    property string label: "cut"
    property bool isShown: false
    property bool isMirrored: false
    property bool isInstant: false
    property real lean: 0
    property int enterSpan: 0
    property int leaveSpan: 0
    property real edgeWidth: 0
    property color edgeColor: "transparent"
    property bool isLeaveSide: false
    property real position: 0
    readonly property real coverage: isLeaveSide ? 1 - position : position
    readonly property bool isCovered: isShown && coverage >= 1 && !sweep.running
    readonly property bool isCleared: !isShown && coverage <= 0 && !sweep.running
    readonly property bool coversLeft: isLeaveSide === isMirrored
    readonly property var line: Veil.cutOf(position, width, height, lean, isMirrored)
    readonly property var blade: Veil.bladeOf(line, width, height, coversLeft)
    readonly property string playing: sweep.running ? label + (isShown ? " in" : " away") : ""
    readonly property Item content: inner
    default property alias pieces: inner.data

    function sweepTo(target, span) {
        sweep.stop()
        sweep.to = target
        sweep.duration = isInstant ? 0 : Motion.pace(Math.max(0, Math.round(span)))
        sweep.start()
    }

    function show() {
        if (isLeaveSide && position >= 1) {
            isLeaveSide = false
            position = 0
        }
        if (isLeaveSide)
            sweepTo(0, enterSpan * position)
        else
            sweepTo(1, enterSpan * (1 - position))
    }

    function hide() {
        if (!isLeaveSide && position >= 1) {
            isLeaveSide = true
            position = 0
        }
        if (isLeaveSide)
            sweepTo(1, leaveSpan * (1 - position))
        else if (position > 0)
            sweepTo(0, leaveSpan * position)
        else
            sweep.stop()
    }

    onIsShownChanged: isShown ? show() : hide()
    Component.onCompleted: {
        Playing.enlist(cut)
        if (isShown)
            show()
    }
    Component.onDestruction: {
        sweep.stop()
        Playing.delist(cut)
    }

    NumberAnimation {
        id: sweep
        paused: Motion.isHeld && running
        target: cut
        property: "position"
        easing.type: Easing.InOutQuad
    }

    Item {
        id: bladeItem
        objectName: "blade"
        visible: cut.coverage > 0
        clip: cut.coverage < 1
        x: cut.blade.x
        y: cut.blade.y
        width: cut.blade.size
        height: cut.blade.size
        transform: Rotation {
            origin.x: cut.blade.originX
            origin.y: cut.blade.size / 2
            angle: cut.blade.angle
        }

        Item {
            id: inner
            x: -cut.blade.x
            y: -cut.blade.y
            width: cut.width
            height: cut.height
            transform: Rotation {
                origin.x: cut.blade.pivotX
                origin.y: cut.blade.pivotY
                angle: -cut.blade.angle
            }
        }

        Rectangle {
            visible: cut.edgeWidth > 0 && cut.coverage < 1
            x: cut.coversLeft ? parent.width - width : 0
            width: cut.edgeWidth
            height: parent.height
            color: cut.edgeColor
        }
    }
}
