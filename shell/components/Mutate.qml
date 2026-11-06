import QtQuick
import qs.config

QtObject {
    id: mutate

    property bool isShown: false
    property bool hasSpread: true
    property int enterDelay: 0
    property int leaveDelay: Motion.pill.leaveWindow + Motion.pill.leaveElement / 4
    property int popDuration: Motion.pill.pop
    property real pop: 0
    property real spread: 0
    property bool isInnerShown: false
    readonly property int innerLead: Motion.pill.spread / 2
    readonly property int spreadAfterInner: Motion.pill.spread - innerLead

    signal departed()

    readonly property SequentialAnimation spreadEnter: SequentialAnimation {
        PauseAnimation { duration: mutate.enterDelay }
        ParallelAnimation {
            NumberAnimation {
                target: mutate
                property: "pop"
                to: 1
                duration: mutate.popDuration
                easing.type: Easing.OutBack
            }
            SequentialAnimation {
                PauseAnimation { duration: Motion.pill.spreadDelay }
                ParallelAnimation {
                    NumberAnimation {
                        target: mutate
                        property: "spread"
                        to: 1
                        duration: Motion.pill.spread
                        easing.type: Easing.InOutCubic
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: mutate.innerLead }
                        ScriptAction { script: mutate.isInnerShown = true }
                    }
                }
            }
        }
    }

    readonly property SequentialAnimation popEnter: SequentialAnimation {
        PauseAnimation { duration: mutate.enterDelay }
        ScriptAction { script: mutate.isInnerShown = true }
        NumberAnimation {
            target: mutate
            property: "pop"
            to: 1
            duration: mutate.popDuration
            easing.type: Easing.OutBack
        }
    }

    readonly property SequentialAnimation leave: SequentialAnimation {
        ScriptAction { script: mutate.isInnerShown = false }
        PauseAnimation { id: leavePause }
        NumberAnimation {
            target: mutate
            property: "spread"
            to: 0
            duration: mutate.hasSpread ? Motion.pill.leaveSpread : 0
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: mutate
            property: "pop"
            to: 0
            duration: Motion.pill.leavePop
            easing.type: Easing.InBack
        }
        ScriptAction { script: mutate.departed() }
    }

    function play() {
        if (isShown) {
            leave.stop()
            if (hasSpread)
                spreadEnter.restart()
            else
                popEnter.restart()
            return
        }
        spreadEnter.stop()
        popEnter.stop()
        leavePause.duration = leaveDelay
        leave.restart()
    }

    onIsShownChanged: play()
    Component.onCompleted: if (isShown) play()
}
