import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.services

TestCase {
    name: "Confinement"

    readonly property string path: Quickshell.env("HOME") + "/.cache/vados/desktop.json"

    function test_desktopModeAdoptsParkedWindowsAfterARestart() {
        Quickshell.writeFile(path, JSON.stringify({ version: 1, data: { parked: { "5": [10, 20], "9": [1, 1] } } }))
        Config.setWindowMode("desktop")
        Compositor.isDriftwm = true
        Compositor.canvasState = { windows: [{ id: 5, position: [9000, 0], size: [100, 100] }, { id: 6, position: [0, 0], size: [100, 100] }] }
        tryCompare(Confinement, "hasRecovered", true, 1000)
        compare(Confinement.parked["5"][0], 10, "keeps the position from before the restart, not the parking spot")
        verify(Confinement.parked["9"] === undefined, "drops windows that no longer exist")
        compare(Compositor.sent.filter(command => command.indexOf("--id 5") >= 0).length, 0, "does not park it a second time")
    }
}
