import QtQuick
import qs.config
import "../utils/Backoff.js" as Backoff
import "../utils/Log.js" as Log

QtObject {
    id: supervisor

    property string name: ""
    property bool isActive: true
    property QtObject process: null
    property int failures: 0
    property int restarts: 0
    property string lastFailure: ""
    property int exitCode: 0
    property bool hasExited: false
    property bool isStopping: false
    readonly property bool isHolding: hold.running
    readonly property string status: !isActive ? "stopped" : isHolding ? "waiting" : failures > 0 ? "failing" : "healthy"

    signal restarted()

    property Timer hold: Timer {
        onTriggered: supervisor.restart()
    }

    property Timer health: Timer {
        interval: Motion.supervision.healthy
        onTriggered: supervisor.succeed()
    }

    property Timer exitCheck: Timer {
        interval: 0
        onTriggered: supervisor.noteStopped()
    }

    property Connections watcher: Connections {
        target: supervisor.process
        ignoreUnknownSignals: true

        function onRunningChanged() {
            if (supervisor.process.running) {
                supervisor.health.restart()
                return
            }
            supervisor.health.stop()
            supervisor.exitCheck.restart()
        }

        function onExited(exitCode, exitStatus) {
            supervisor.exitCode = exitCode
            supervisor.hasExited = true
        }
    }

    function start() {
        if (!process || !isActive || hold.running || process.running)
            return
        hasExited = false
        isStopping = false
        process.running = true
    }

    function stop() {
        hold.stop()
        health.stop()
        if (!process || !process.running)
            return
        isStopping = true
        process.running = false
    }

    function noteStopped() {
        if (process.running)
            return
        if (isStopping) {
            isStopping = false
            start()
            return
        }
        if (!isActive || hold.running)
            return
        fail(hasExited ? "exited with code " + exitCode : "failed to start")
    }

    function fail(reason) {
        if (!isActive)
            return
        health.stop()
        failures += 1
        lastFailure = reason
        const delay = Backoff.delayOf(failures, Motion.supervision)
        Log.warn(name, reason + ", restarting in " + Math.round(delay / 1000) + " s")
        hold.interval = delay
        hold.restart()
    }

    function succeed() {
        if (failures > 0)
            Log.info(name, "recovered after " + failures + (failures === 1 ? " failure" : " failures"))
        failures = 0
    }

    function restart() {
        if (!isActive)
            return
        restarts += 1
        start()
        restarted()
    }

    onIsActiveChanged: {
        if (isActive)
            start()
        else
            stop()
    }

    Component.onCompleted: {
        Supervision.enroll(supervisor)
        start()
    }

    Component.onDestruction: Supervision.release(supervisor)
}
