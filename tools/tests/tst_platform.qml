import QtQuick
import QtTest
import qs.config
import qs.services
import "../../shell/utils/Platform.js" as Platform

TestCase {
    name: "Platform"

    readonly property var backendNames: ["driftwm", "hyprland", "generic"]

    function cleanup() {
        Config.setWindowMode("canvas")
        Compositor.isDriftwm = false
        Compositor.canvasState = null
        Compositor.sent = []
    }

    function test_levels() {
        compare(Platform.levelOf(Platform.capabilitiesOf("driftwm")), "native")
        compare(Platform.levelOf(Platform.capabilitiesOf("hyprland")), "extended")
        compare(Platform.levelOf(Platform.capabilitiesOf("generic")), "core")
    }

    function test_anUnknownBackendIsGeneric() {
        compare(Platform.capabilitiesOf("unknown"), Platform.capabilitiesOf("generic"))
        compare(Platform.levelOf(Platform.capabilitiesOf("unknown")), "core")
    }

    function test_everyBackendAnswersEveryCapability() {
        const names = Object.keys(Platform.capabilitiesOf("generic")).sort()
        for (const backend of backendNames) {
            const capabilities = Platform.capabilitiesOf(backend)
            compare(Object.keys(capabilities).sort(), names, backend)
            for (const name of names)
                compare(typeof capabilities[name], "boolean", backend + " " + name)
        }
    }

    function test_coreHoldsOnEveryBackend() {
        for (const backend of backendNames) {
            const capabilities = Platform.capabilitiesOf(backend)
            verify(capabilities.layerShell, backend)
            verify(capabilities.activeWindow, backend)
            verify(capabilities.fullscreenDetection, backend)
        }
    }

    function test_onlyDriftwmDrawsItsOwnBackground() {
        verify(Platform.capabilitiesOf("driftwm").ownBackground, "driftwm paints over the background layer, so widgets sit on the bottom layer")
        verify(!Platform.capabilitiesOf("hyprland").ownBackground)
        verify(!Platform.capabilitiesOf("generic").ownBackground)
    }

    function test_theLockNeedsTheSessionLockProtocol() {
        verify(Platform.capabilitiesOf("driftwm").sessionLock)
        verify(Platform.capabilitiesOf("hyprland").sessionLock)
        verify(!Platform.capabilitiesOf("generic").sessionLock, "an unknown compositor never gets a plain overlay as a lock")
        const before = Compositor.powered.length
        Compositor.powerDisplays(false)
        compare(Compositor.powered.length, before, "no display power command without the capability")
        Compositor.isDriftwm = true
        Compositor.powerDisplays(false)
        compare(Compositor.powered.length, before + 1)
    }

    function test_outputLayoutsNeedOutputConfiguration() {
        verify(Platform.capabilitiesOf("driftwm").outputConfiguration, "driftwm takes [[outputs]] from its config and reloads it live")
        verify(Platform.capabilitiesOf("hyprland").outputConfiguration)
        verify(!Platform.capabilitiesOf("generic").outputConfiguration, "an unknown compositor gets no Displays tab")
        const layout = Compositor.outputs
        const before = Compositor.appliedOutputs.length
        verify(!Compositor.applyOutputs(layout), "nothing is applied without the capability")
        compare(Compositor.appliedOutputs.length, before)
        Compositor.isDriftwm = true
        verify(Compositor.applyOutputs(layout))
        compare(Compositor.appliedOutputs.length, before + 1)
        compare(Compositor.outputTrial.phase, "trying", "an applied layout is on trial")
        Compositor.revertOutputs()
        compare(Compositor.outputTrial.phase, "idle")
        compare(Compositor.outputs, layout, "a revert puts the previous layout back")
    }

    function test_windowAbilitiesNeedWindowControl() {
        for (const backend of backendNames) {
            const capabilities = Platform.capabilitiesOf(backend)
            if (capabilities.windowMinimize || capabilities.windowSnap)
                verify(capabilities.windowControl, backend)
        }
    }

    function test_desktopModeDegradesWithoutANativeBackend() {
        Compositor.canvasState = { windows: [{ id: 3, is_focused: true, position: [0, 0], size: [100, 100] }], outputs: [] }
        Config.setWindowMode("desktop")
        verify(!Confinement.canConfine)
        verify(!Confinement.isConfined)
        verify(!Confinement.canMinimize)
        verify(!Confinement.canSnap)
        Confinement.minimize()
        Confinement.snap("left")
        compare(Compositor.sent.length, 0, "sends no window commands the backend cannot run")
    }

    function test_desktopModeMinimizesAndSnapsOnANativeBackend() {
        Compositor.isDriftwm = true
        Config.setWindowMode("desktop")
        verify(Confinement.canConfine)
        verify(Confinement.canMinimize)
        verify(Confinement.canSnap)
    }
}
