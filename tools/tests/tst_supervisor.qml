import QtQuick
import QtTest
import Quickshell.Io
import qs.config
import qs.services
import "../../shell/utils/Backoff.js" as Backoff

TestCase {
    name: "Supervisor"

    Component {
        id: processComponent

        Process {}
    }

    Component {
        id: supervisorComponent

        Supervisor {}
    }

    SignalSpy {
        id: restarts
        signalName: "restarted"
    }

    function supervise(name, properties) {
        const process = createTemporaryObject(processComponent, this)
        const supervisor = createTemporaryObject(supervisorComponent, this, Object.assign({ name: name, process: process }, properties ?? {}))
        return supervisor
    }

    function crash(supervisor, exitCode) {
        supervisor.process.exited(exitCode, 0)
        supervisor.process.running = false
    }

    function hurry(supervisor) {
        supervisor.hold.interval = 10
        supervisor.hold.restart()
    }

    function test_backoffGrowsToItsCap() {
        const policy = Motion.supervision
        compare(Backoff.delayOf(0, policy), policy.base)
        compare(Backoff.delayOf(1, policy), policy.base)
        compare(Backoff.delayOf(2, policy), policy.base * policy.factor)
        compare(Backoff.delayOf(3, policy), policy.base * policy.factor * policy.factor)
        compare(Backoff.delayOf(100, policy), policy.cap)
    }

    function test_startsTheProcessWhileActive() {
        const supervisor = supervise("start")
        verify(supervisor.process.running)
        compare(supervisor.status, "healthy")
    }

    function test_crashRestartsWithBackoff() {
        const supervisor = supervise("crash")
        ignoreWarning("vados: crash: exited with code 3, restarting in 1 s")
        crash(supervisor, 3)
        tryCompare(supervisor, "status", "waiting", 500)
        compare(supervisor.failures, 1)
        compare(supervisor.lastFailure, "exited with code 3")
        verify(!supervisor.process.running)
        hurry(supervisor)
        tryCompare(supervisor.process, "running", true, 500)
        compare(supervisor.restarts, 1)
        compare(supervisor.status, "failing")
        ignoreWarning("vados: crash: exited with code 4, restarting in 2 s")
        crash(supervisor, 4)
        tryCompare(supervisor, "failures", 2, 500)
        compare(supervisor.hold.interval, Motion.supervision.base * Motion.supervision.factor)
    }

    function test_healthyRunResetsTheBackoff() {
        const supervisor = supervise("healthy")
        ignoreWarning("vados: healthy: exited with code 1, restarting in 1 s")
        crash(supervisor, 1)
        tryCompare(supervisor, "status", "waiting", 500)
        supervisor.health.interval = 20
        hurry(supervisor)
        tryCompare(supervisor, "failures", 0, 1000)
        compare(supervisor.status, "healthy")
        compare(supervisor.restarts, 1)
    }

    function test_failedStartCountsAsFailure() {
        const supervisor = supervise("missing")
        ignoreWarning("vados: missing: failed to start, restarting in 1 s")
        supervisor.process.running = false
        tryCompare(supervisor, "failures", 1, 500)
        compare(supervisor.lastFailure, "failed to start")
    }

    function test_inactiveStopsAndNeverRestarts() {
        const supervisor = supervise("hidden")
        supervisor.isActive = false
        verify(!supervisor.process.running)
        wait(50)
        compare(supervisor.failures, 0, "a stop asked for is not a failure")
        compare(supervisor.status, "stopped")
        supervisor.isActive = true
        verify(supervisor.process.running, "showing again starts at once")
    }

    function test_showingAgainWhileStoppingIsNoFailure() {
        const supervisor = supervise("reopen")
        supervisor.isActive = false
        supervisor.process.running = true
        supervisor.isActive = true
        supervisor.process.exited(15, 1)
        supervisor.process.running = false
        tryCompare(supervisor.process, "running", true, 500)
        compare(supervisor.failures, 0, "the stop it asked for finished late")
        compare(supervisor.isStopping, false)
        compare(supervisor.status, "healthy")
    }

    function test_hidingDuringTheWaitCancelsTheRestart() {
        const supervisor = supervise("cancel")
        ignoreWarning("vados: cancel: exited with code 2, restarting in 1 s")
        crash(supervisor, 2)
        tryCompare(supervisor, "status", "waiting", 500)
        supervisor.isActive = false
        verify(!supervisor.hold.running)
        wait(50)
        compare(supervisor.restarts, 0)
        verify(!supervisor.process.running)
    }

    function test_workWithoutProcess() {
        const supervisor = createTemporaryObject(supervisorComponent, this, { name: "task" })
        restarts.clear()
        restarts.target = supervisor
        ignoreWarning("vados: task: offline, restarting in 1 s")
        supervisor.fail("offline")
        compare(supervisor.status, "waiting")
        hurry(supervisor)
        tryCompare(restarts, "count", 1, 500)
        supervisor.succeed()
        compare(supervisor.failures, 0)
        compare(supervisor.status, "healthy")
    }

    function test_enrollsForDiagnostics() {
        const supervisor = supervise("listed")
        verify(Supervision.supervisors.indexOf(supervisor) >= 0)
    }
}
