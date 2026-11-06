import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.state

Scope {
    id: shortcuts

    readonly property bool isServingNotifications: Notifications.isServing

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
        name: "activity"
        description: "Open or close the activity bar"
        onPressed: Activity.toggle(Compositor.focusedScreen)
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

    IpcHandler {
        target: "activity"

        function toggle(): void {
            Activity.toggle(Compositor.focusedScreen)
        }

        function close(): void {
            Activity.close()
        }

        function pin(kind: string): void {
            Activity.pin(kind)
        }

        function current(): string {
            return Activity.current ? Activity.current.kind : ""
        }
    }

    IpcHandler {
        target: "notifications"

        function enable(): void {
            Config.setNotificationsEnabled(true)
        }

        function disable(): void {
            Config.setNotificationsEnabled(false)
        }

        function status(): string {
            return shortcuts.isServingNotifications ? "serving" : "off"
        }

        function count(): int {
            return Notifications.list.length
        }

        function clear(): void {
            Notifications.clear()
        }
    }
}
