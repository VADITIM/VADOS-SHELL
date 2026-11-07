import QtQuick
import qs.config
import "../utils/Phases.js" as Phases

QtObject {
    id: lifecycle

    property string name: ""
    property bool canRecover: false
    property string phase: "idle"
    readonly property bool isPresent: Phases.isPresent(phase)
    readonly property bool isMoving: Phases.isMoving(phase)
    readonly property bool isLeaving: Phases.isLeaving(phase)
    readonly property bool isShowing: Phases.isShowing(phase)

    property Timer watchdog: Timer {
        interval: Motion.lifecycle.stuck
        onTriggered: {
            console.warn("vados: " + lifecycle.name + " stuck in " + lifecycle.phase + ", settling")
            lifecycle.send("settle")
        }
    }

    signal moving(string from, string to, string event)
    signal moved(string from, string to, string event)
    signal interrupted(string from)

    function send(event) {
        const from = phase
        const to = Phases.next(from, event, canRecover)
        if (to === from)
            return
        if (Phases.isInterruption(from, event))
            interrupted(from)
        moving(from, to, event)
        phase = to
        if (Phases.isMoving(to))
            watchdog.restart()
        else
            watchdog.stop()
        moved(from, to, event)
    }
}
