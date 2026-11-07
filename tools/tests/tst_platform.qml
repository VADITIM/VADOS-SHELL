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
