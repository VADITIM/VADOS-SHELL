import QtQuick
import qs.config

TypedText {
    id: roll

    property bool isSettled: false
    property string previous: ""

    text: isSettled ? "" : shown
    width: holdsWidth || isSettled ? fullWidth : implicitWidth

    function cellAt(index) {
        return cells.itemAt(index)
    }

    function turnOver(from, to) {
        if (from.length !== to.length)
            return
        let rank = 0
        for (let index = to.length - 1; index >= 0; index--) {
            if (from.charAt(index) === to.charAt(index))
                continue
            const cell = cells.itemAt(index)
            if (cell)
                cell.change(to.charAt(index), rank * Motion.roll.carry)
            rank++
        }
    }

    onTargetChanged: {
        if (isSettled) {
            shown = target
            turnOver(previous, target)
        }
        previous = target
    }
    function align() {
        for (let index = 0; index < cells.count; index++)
            cells.itemAt(index).rest(target.charAt(index))
    }

    onShownChanged: {
        if (isSettled || !isShown || target.length === 0 || shown !== target)
            return
        align()
        isSettled = true
    }
    onIsShownChanged: {
        if (!isShown)
            isSettled = false
    }

    Row {
        visible: roll.isSettled

        Repeater {
            id: cells
            model: roll.target.length

            Item {
                id: cell

                required property int index
                property string present: roll.target.charAt(index)
                property string past: ""
                property real progress: 1
                property int delay: 0
                readonly property real travel: height * Motion.roll.rise

                width: now.implicitWidth
                height: now.implicitHeight

                function rest(character) {
                    turn.stop()
                    past = ""
                    present = character
                    progress = 1
                }

                function change(character, wait) {
                    turn.stop()
                    past = present
                    present = character
                    delay = wait
                    progress = 0
                    turn.start()
                }

                Text {
                    id: now
                    text: cell.present
                    textFormat: Text.PlainText
                    y: cell.travel * (1 - cell.progress)
                    opacity: cell.progress
                    color: roll.color
                    font: roll.font
                }

                Text {
                    text: cell.past
                    textFormat: Text.PlainText
                    visible: cell.progress < 1
                    y: -cell.travel * cell.progress
                    opacity: 1 - Math.min(1, cell.progress / Motion.roll.leaveShare)
                    color: roll.color
                    font: roll.font
                }

                SequentialAnimation {
                    id: turn
                    paused: Motion.isHeld && running

                    PauseAnimation {
                        duration: Motion.pace(cell.delay)
                    }

                    NumberAnimation {
                        target: cell
                        property: "progress"
                        from: 0
                        to: 1
                        duration: Motion.pace(Motion.roll.duration)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
