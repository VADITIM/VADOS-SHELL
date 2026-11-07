import QtQuick
import QtTest
import qs.components
import "../../shell/utils/Phases.js" as Phases

Item {
    Lifecycle {
        id: lifecycle
        name: "test"
        property var trail: []
        onMoved: (from, to, event) => trail = trail.concat([to])
    }

    TestCase {
        name: "Lifecycle"

        function init() {
            lifecycle.phase = "idle"
            lifecycle.canRecover = false
            lifecycle.trail = []
            lifecycle.watchdog.stop()
            lifecycle.watchdog.interval = 3000
        }

        function test_fullCycle() {
            for (const event of ["show", "prepared", "entered", "hide", "exited"])
                lifecycle.send(event)
            compare(lifecycle.trail, ["preparing", "entering", "active", "exiting", "idle"])
        }

        function test_eventsOutOfOrderAreIgnored() {
            for (const event of ["entered", "hide", "exited", "recovered", "prepared"])
                compare(Phases.next("idle", event, true), "idle")
            compare(Phases.next("active", "show", true), "active")
            compare(Phases.next("exiting", "entered", true), "exiting")
        }

        function test_showWhileLeavingRecoversOrRestarts() {
            compare(Phases.next("exiting", "show", true), "recovering")
            compare(Phases.next("exiting", "show", false), "preparing")
            verify(Phases.isInterruption("exiting", "show"))
            compare(Phases.next("recovering", "recovered", true), "entering")
        }

        function test_everyPhaseAcceptsHideOrSettlesHome() {
            for (const phase of ["preparing", "entering", "active", "recovering"])
                compare(Phases.next(phase, "hide", true), "exiting")
            for (const phase of ["preparing", "entering", "recovering"])
                compare(Phases.next(phase, "settle", true), "active")
            compare(Phases.next("exiting", "settle", true), "idle")
        }

        function test_rapidInputAlwaysEndsValid() {
            const valid = ["idle", "preparing", "entering", "active", "exiting", "recovering"]
            const events = ["show", "hide", "prepared", "entered", "exited", "recovered", "settle"]
            let phase = "idle"
            let seed = 7
            for (let step = 0; step < 2000; step++) {
                seed = (seed * 48271) % 2147483647
                phase = Phases.next(phase, events[seed % events.length], seed % 2 === 0)
                verify(valid.indexOf(phase) >= 0, phase)
            }
        }

        function test_stuckTransitionSettles() {
            lifecycle.watchdog.interval = 50
            lifecycle.send("show")
            verify(lifecycle.watchdog.running)
            ignoreWarning("vados: test stuck in preparing, settling")
            tryCompare(lifecycle, "phase", "active", 500)
            verify(!lifecycle.watchdog.running, "nothing ticks once settled")
        }
    }
}
