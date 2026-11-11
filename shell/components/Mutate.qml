import QtQuick
import qs.config
import "../utils/Liquid.js" as Liquid
import "../utils/Playing.js" as Playing

QtObject {
    id: mutate

    property string label: "mutate"
    property bool isShown: false
    property bool isArriving: false
    property bool hasArrived: true
    property bool hasSpread: true
    property bool hasArrivalPop: false
    property int enterDelay: 0
    property bool isHolding: false
    property bool isRetired: false
    property int leaveDelay: Motion.pill.leaveWindow + Motion.pill.leaveElement / 4
    property int leaveSpreadDuration: Motion.pill.leaveSpread
    property int popDuration: Motion.pill.pop
    property var character: Motion.liquid.pill
    property real popTime: 0
    property real popFrom: 0
    property real popRemaining: 1
    property bool isPopLeaving: false
    readonly property real pop: isPopLeaving ? popFrom * popRemaining
        : popTime >= popDuration ? 1
        : popFrom + (1 - popFrom) * Liquid.rise(character, popTime / 1000)
    readonly property string playing: spreadEnter.running || popEnter.running || innerEnter.running ? label + " enter"
        : leave.running || popLeave.running ? label + " leave"
        : ""
    property real spread: 0
    property bool isInnerShown: false
    readonly property int innerLead: Motion.pill.spread / 2
    readonly property int spreadAfterInner: Motion.pill.spread - innerLead

    signal departed()

    readonly property SequentialAnimation spreadEnter: SequentialAnimation {
        paused: Motion.isHeld && running
        PauseAnimation { duration: Motion.pace(mutate.enterDelay) }
        ParallelAnimation {
            NumberAnimation {
                target: mutate
                property: "popTime"
                to: mutate.popDuration
                duration: Motion.pace(mutate.popDuration)
            }
            SequentialAnimation {
                PauseAnimation { duration: Motion.pace(Motion.pill.spreadDelay) }
                ParallelAnimation {
                    NumberAnimation {
                        target: mutate
                        property: "spread"
                        to: 1
                        duration: Motion.pace(Motion.pill.spread)
                        easing.type: Easing.InOutCubic
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: Motion.pace(mutate.innerLead) }
                        ScriptAction { script: mutate.isInnerShown = true }
                    }
                }
            }
        }
    }

    readonly property SequentialAnimation popEnter: SequentialAnimation {
        paused: Motion.isHeld && running
        PauseAnimation { duration: Motion.pace(mutate.enterDelay) }
        ScriptAction { script: mutate.isInnerShown = true }
        NumberAnimation {
            target: mutate
            property: "popTime"
            to: mutate.popDuration
            duration: Motion.pace(mutate.popDuration)
        }
    }

    readonly property SequentialAnimation innerEnter: SequentialAnimation {
        paused: Motion.isHeld && running
        PauseAnimation { duration: Motion.pace(mutate.enterDelay) }
        ScriptAction { script: mutate.isInnerShown = true }
    }

    readonly property SequentialAnimation leave: SequentialAnimation {
        paused: Motion.isHeld && running
        ScriptAction { script: mutate.isInnerShown = false }
        PauseAnimation { id: leavePause }
        NumberAnimation {
            target: mutate
            property: "spread"
            to: 0
            duration: Motion.pace(mutate.hasSpread ? mutate.leaveSpreadDuration : 0)
            easing.type: Easing.InOutCubic
        }
        ScriptAction { script: mutate.retire() }
    }

    readonly property SequentialAnimation popLeave: SequentialAnimation {
        paused: Motion.isHeld && running
        ScriptAction { script: mutate.holdPop(true) }
        NumberAnimation {
            target: mutate
            property: "popRemaining"
            to: 0
            duration: Motion.pace(Motion.pill.leavePop)
            easing.type: Easing.InBack
        }
        ScriptAction { script: mutate.departed() }
    }

    function holdPop(isLeaving) {
        const current = pop
        popFrom = current
        popTime = 0
        popRemaining = 1
        isPopLeaving = isLeaving
    }

    function retire() {
        isRetired = true
        if (!isHolding)
            popLeave.restart()
    }

    function stopAll() {
        spreadEnter.stop()
        popEnter.stop()
        innerEnter.stop()
        leave.stop()
        popLeave.stop()
        isRetired = false
    }

    function arrive() {
        stopAll()
        popFrom = 1
        popTime = popDuration
        popRemaining = 1
        isPopLeaving = false
        if (hasSpread) {
            spread = 0
            isInnerShown = false
            spreadEnter.restart()
            return
        }
        spread = 1
        isInnerShown = !hasArrivalPop
        if (hasArrivalPop)
            innerEnter.restart()
    }

    function wait() {
        stopAll()
        popFrom = 0
        popTime = 0
        popRemaining = 1
        isPopLeaving = false
        spread = 0
        isInnerShown = false
    }

    function play() {
        if (isShown && isArriving) {
            if (hasArrived)
                arrive()
            else
                wait()
            return
        }
        innerEnter.stop()
        if (isShown) {
            leave.stop()
            popLeave.stop()
            isRetired = false
            holdPop(false)
            if (hasSpread)
                spreadEnter.restart()
            else
                popEnter.restart()
            return
        }
        spreadEnter.stop()
        popEnter.stop()
        popLeave.stop()
        isRetired = false
        leavePause.duration = Motion.pace(leaveDelay)
        leave.restart()
    }

    onIsShownChanged: play()
    onIsHoldingChanged: if (!isHolding && isRetired && !isShown) popLeave.restart()
    onIsArrivingChanged: if (isArriving && isShown) play()
    onHasArrivedChanged: if (isArriving && isShown && hasArrived) play()
    Component.onCompleted: {
        Playing.enlist(mutate)
        if (isShown)
            play()
    }
    Component.onDestruction: {
        stopAll()
        Playing.delist(mutate)
    }
}
