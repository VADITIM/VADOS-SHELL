import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.state

Scope {
    id: shortcuts

    GlobalShortcut {
        appid: "vados"
        name: "search"
        description: "Open or close the app search"
        onPressed: Visibilities.toggleSearch(Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "settings"
        description: "Open or close the settings"
        onPressed: Visibilities.toggleSettings(Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "dashboard"
        description: "Open or close the dashboard"
        onPressed: Visibilities.toggleDashboard(Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "activityNext"
        description: "Step the activity pill up: hidden, idle, active, expanded"
        onPressed: ActivityState.step(Compositor.focusedScreen, 1)
    }

    GlobalShortcut {
        appid: "vados"
        name: "activityPrevious"
        description: "Step the activity pill down: expanded, active, idle, hidden"
        onPressed: ActivityState.step(Compositor.focusedScreen, -1)
    }

    IpcHandler {
        target: "activity"

        function next(): void {
            ActivityState.step(Compositor.focusedScreen, 1)
        }

        function previous(): void {
            ActivityState.step(Compositor.focusedScreen, -1)
        }

        function mode(name: string): void {
            ActivityState.set(Compositor.focusedScreen, name)
        }

        function rotate(): void {
            ActivityState.rotate(1)
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            Visibilities.toggleDashboard(Compositor.focusedScreen)
        }

        function close(): void {
            Visibilities.closeDashboard()
        }

        function location(name: string): void {
            Config.setWeatherLocation(name)
        }
    }

    IpcHandler {
        target: "search"

        function toggle(): void {
            Visibilities.toggleSearch(Compositor.focusedScreen)
        }

        function close(): void {
            Visibilities.closeSearch()
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            Visibilities.toggleSettings(Compositor.focusedScreen)
        }

        function close(): void {
            Visibilities.closeSettings()
        }
    }

    IpcHandler {
        target: "desktop"

        function mode(name: string): void {
            if (name === "canvas" || name === "desktop")
                Config.setWindowMode(name)
        }

        function toggle(): void {
            Config.setWindowMode(Config.data.desktop.mode === "desktop" ? "canvas" : "desktop")
        }

        function minimize(): void {
            Confinement.minimize()
        }

        function maximize(): void {
            Confinement.maximize()
        }

        function fullscreen(): void {
            Confinement.fullscreen()
        }

        function snap(direction: string): void {
            Confinement.snap(direction)
        }
    }
}
