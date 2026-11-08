import QtQuick
import QtTest
import "../../shell/utils/Diagnostics.js" as Diagnostics

TestCase {
    name: "Diagnostics"

    readonly property var compositor: ({ name: "driftwm", level: "native", capabilities: { freeCanvas: true, windowControl: true, workspaceManagement: false } })
    readonly property var overlays: ({ stack: ["dashboard", "search"], screens: { dashboard: "DP-1", search: "DP-2" }, phases: { "DP-2": { search: "entering" }, "DP-1": { dashboard: "active" } } })
    readonly property var supervisors: [
        { name: "compositor", status: "healthy", restarts: 0, failures: 0, lastFailure: "" },
        { name: "traffic", status: "waiting", restarts: 3, failures: 2, lastFailure: "exited with code 2" }
    ]
    readonly property var entries: [
        { time: 0, last: 0, level: "warn", subsystem: "weather", message: "offline", repeats: 4 }
    ]

    function lines() {
        return Diagnostics.report(compositor, overlays, supervisors, entries).split("\n")
    }

    function test_compositorAndCapabilities() {
        const report = lines()
        compare(report[0], "vados diagnostics")
        compare(report[1], "compositor: driftwm, level native")
        compare(report[2], "  capabilities: freeCanvas, windowControl")
        compare(report[3], "  missing: workspaceManagement")
    }

    function test_overlayStackAndPhases() {
        const report = lines()
        compare(report[4], "overlays: dashboard on DP-1 < search on DP-2")
        compare(report[5], "  DP-1 dashboard: active")
        compare(report[6], "  DP-2 search: entering")
    }

    function test_supervisorsAndLog() {
        const report = lines()
        compare(report[7], "supervised:")
        compare(report[8], "  compositor: healthy, 0 restarts")
        compare(report[9], "  traffic: waiting, 3 restarts, 2 failing in a row, last failure: exited with code 2")
        compare(report[10], "log: 1 recent")
        verify(report[11].endsWith(" warn weather: offline (5 times, last " + report[11].slice(2, 10) + ")"), report[11])
    }

    function test_emptyShell() {
        const report = Diagnostics.report({ name: "generic", level: "core", capabilities: {} }, { stack: [], screens: {}, phases: {} }, [], [])
        compare(report, "vados diagnostics\ncompositor: generic, level core\n  capabilities: none\n  missing: none\noverlays: none open\nsupervised: none\nlog: empty")
    }
}
