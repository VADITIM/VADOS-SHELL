import QtQuick
import qs.config
import "../utils/Phases.js" as Phases
import "../utils/Playing.js" as Playing
import "../utils/Log.js" as Log

QtObject {
    id: lifecycle

    property string name: ""
    property bool canRecover: false
    property string phase: "idle"
    readonly property bool isPresent: Phases.isPresent(phase)
    readonly property bool isMoving: Phases.isMoving(phase)
    readonly property bool isLeaving: Phases.isLeaving(phase)
    readonly property bool isShowing: Phases.isShowing(phase)

    readonly property string playing: isMoving ? name + " " + phase : ""

    Component.onCompleted: Playing.enlist(lifecycle)
    Component.onDestruction: Playing.delist(lifecycle)

    property Timer watchdog: Timer {
        interval: Motion.lifecycle.stuck
        onTriggered: {
            Log.warn("lifecycle", lifecycle.name + " stuck in " + lifecycle.phase + ", settling")
            lifecycle.send("settle")
        }
    }

    property Connections holding: Connections {
        target: Motion

        function onIsHeldChanged() {
            lifecycle.watch()
        }
    }

    function watch() {
        if (isMoving && !Motion.isHeld)
            watchdog.restart()
        else
            watchdog.stop()
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
        watch()
        moved(from, to, event)
        if (Motion.isHeld)
            Qt.callLater(Motion.holdAgain)
    }
}
