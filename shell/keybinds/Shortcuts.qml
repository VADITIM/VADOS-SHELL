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

    readonly property string notificationStatus: Notifications.status
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
        description: "Expand or fold the activity pill"
        onPressed: ActivityState.toggle(Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "notifications"
        description: "Open or close the notifications menu"
        onPressed: Overlays.toggle("notifications", Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "clipboard"
        description: "Open or close the clipboard history"
        onPressed: ActivityState.toggleClipboard(Compositor.focusedScreen)
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

    GlobalShortcut {
        appid: "vados"
        name: "frames"
        description: "Hold every animation and step it one frame at a time"
        onPressed: FrameDebug.toggle(Compositor.focusedScreen)
    }

    GlobalShortcut {
        appid: "vados"
        name: "frameShot"
        description: "Copy a screenshot of the shell to the clipboard"
        onPressed: FrameDebug.snap(Compositor.focusedScreen)
    }

    IpcHandler {
        target: "frames"

        function back(): void {
            FrameDebug.back()
        }

        function shot(): void {
            FrameDebug.snap(Compositor.focusedScreen)
        }

        function toggle(): void {
            FrameDebug.toggle(Compositor.focusedScreen)
        }

        function step(): void {
            FrameDebug.step()
        }

        function close(): void {
            FrameDebug.close()
        }

        function status(): string {
            return FrameDebug.counter + " " + FrameDebug.shownLabel
        }
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

        function toggle(): void {
            ActivityState.toggle(Compositor.focusedScreen)
        }

        function close(): void {
            ActivityState.fold()
        }

        function pin(key: string): void {
            ActivityState.pin(key)
        }

        function current(): string {
            return ActivityState.leadKey
        }
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
        target: "clipboard"

        function toggle(): void {
            ActivityState.toggleClipboard(Compositor.focusedScreen)
        }

        function close(): void {
            ActivityState.closeClipboard()
        }

        function clear(): void {
            Clipboard.clear()
        }

        function count(): int {
            return Clipboard.entries.length
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
            return shortcuts.notificationStatus
        }

        function toggle(): void {
            Overlays.toggle("notifications", Compositor.focusedScreen)
        }

        function close(): void {
            Overlays.close("notifications")
        }

        function count(): int {
            return Notifications.list.length
        }

        function clear(): void {
            Notifications.clear()
        }
    }
}
