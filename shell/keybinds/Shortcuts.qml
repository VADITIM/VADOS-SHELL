import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.state
import "../utils/Diagnostics.js" as Diagnostics
import "../utils/Log.js" as Log

Scope {
    id: shortcuts

    readonly property bool isServingNotifications: Notifications.isServing
    readonly property bool isQuiet: Attention.isQuiet

    GlobalShortcut {
        appid: "vados"
        name: "search"
        description: "Open or close the app search"
        onPressed: Overlays.toggle("search", Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "settings"
        description: "Open or close the settings"
        onPressed: Overlays.toggle("settings", Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "dashboard"
        description: "Open or close the dashboard"
        onPressed: Overlays.toggle("dashboard", Compositor.focusedScreen)
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
            Overlays.toggle("dashboard", Compositor.focusedScreen)
        }

        function close(): void {
            Overlays.close("dashboard")
        }

        function location(name: string): void {
            Config.setWeatherLocation(name)
        }
    }

    IpcHandler {
        target: "search"

        function toggle(): void {
            Overlays.toggle("search", Compositor.focusedScreen)
        }

        function close(): void {
            Overlays.close("search")
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            Overlays.toggle("settings", Compositor.focusedScreen)
        }

        function close(): void {
            Overlays.close("settings")
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
        target: "overlay"

        function toggle(key: string): void {
            Overlays.toggle(key, Compositor.focusedScreen)
        }

        function close(): void {
            Overlays.closeTop()
        }

        function top(): string {
            return Overlays.top
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
        target: "attention"

        function quiet(isOn: bool): void {
            Attention.setQuiet(isOn)
        }

        function toggle(): void {
            Attention.setQuiet(!shortcuts.isQuiet)
        }

        function status(): string {
            return shortcuts.isQuiet ? "quiet" : "open"
        }

        function dismiss(): void {
            Attention.dismissPeek()
        }
    }

    IpcHandler {
        target: "diagnostics"

        function report(): string {
            return Diagnostics.report(Compositor, Overlays, Supervision.supervisors, Log.recent())
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
