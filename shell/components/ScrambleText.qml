import QtQuick
import qs.config
import "../utils/Scramble.js" as Scramble
import "../utils/Playing.js" as Playing

Item {
    id: scramble

    property string target
    property bool isShown: false
    property string label: "scramble"
    property color color: Appearance.color.text
    property string family: Appearance.font.sans
    property int pixelSize: Appearance.font.label
    property bool isBold: true
    property real spacing: Appearance.font.labelSpacing
    property real elapsed: 0
    property real presence: 0
    property string previous
    property int from: 0
    property real runSpan: 0
    property var starts: []
    property int typeBudget: 0
    readonly property int count: Math.max(0, target.length - from)
    readonly property var timing: ({ stagger: typeBudget > 0 && count > 1 ? Math.min(Motion.type.scrambleStagger, Math.max(0, typeBudget - Motion.type.scrambleSpin) / (count - 1)) : Motion.type.scrambleStagger, spin: Motion.type.scrambleSpin, settle: Motion.type.scrambleSettle, turns: Motion.type.scrambleTurns, cycles: Motion.type.scrambleCycles })
    readonly property real span: runSpan
    readonly property bool isTyped: elapsed >= span
    readonly property string playing: typing.running || leaving.running ? label : ""

    implicitWidth: metrics.advanceWidth(target) + spacing * Math.max(0, target.length - 1)
    implicitHeight: metrics.height
    opacity: presence

    FontMetrics {
        id: metrics
        font.family: scramble.family
        font.pixelSize: scramble.pixelSize
        font.bold: scramble.isBold
    }

    Repeater {
        model: scramble.target.length

        Text {
            required property int index
            readonly property var phase: Scramble.phaseOf(scramble.starts[index] ?? 0, scramble.elapsed, scramble.timing)
            readonly property string actual: scramble.target.charAt(index)

            x: metrics.advanceWidth(scramble.target.slice(0, index)) + index * scramble.spacing
            width: metrics.advanceWidth(actual)
            height: scramble.implicitHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: Scramble.characterAt(scramble.target, Appearance.font.scrambleSymbols, index, phase)
            rotation: phase.rotation
            color: scramble.color
            font.family: scramble.family
            font.pixelSize: scramble.pixelSize
            font.bold: scramble.isBold
        }
    }

    NumberAnimation {
        id: typing
        paused: Motion.isHeld && running
        target: scramble
        property: "elapsed"
        to: scramble.runSpan
        duration: Motion.pace(Math.max(0, scramble.runSpan - scramble.elapsed))
    }

    NumberAnimation {
        id: leaving
        paused: Motion.isHeld && running
        target: scramble
        property: "presence"
        to: 0
        duration: Motion.pace(Motion.type.scrambleLeave)
        easing.type: Easing.InQuad
    }

    onTargetChanged: {
        const changed = Scramble.firstDifference(previous, target)
        previous = target
        if (!isShown)
            return
        retype(changed)
    }
    onIsShownChanged: {
        if (isShown) {
            leaving.stop()
            presence = 1
            retype(0)
            return
        }
        typing.stop()
        leaving.restart()
    }

    function retype(start) {
        const isRunning = typing.running
        typing.stop()
        const now = isRunning ? elapsed : 0
        from = start
        starts = Scramble.startsFor(isRunning ? starts : Scramble.settle(starts), target.length, start, now, timing.stagger)
        runSpan = Scramble.endOf(starts, timing.spin)
        elapsed = now
        typing.start()
    }

    Component.onCompleted: {
        previous = target
        Playing.enlist(scramble)
    }
    Component.onDestruction: {
        typing.stop()
        leaving.stop()
        Playing.delist(scramble)
    }
}
