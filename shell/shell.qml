//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.config
import qs.state
import qs.windows
import qs.keybinds

ShellRoot {
    Shortcuts {}

    Connections {
        target: Quickshell

        function onScreensChanged() {
            Overlays.keepScreens(Array.from(Quickshell.screens, screen => screen.name))
        }
    }

    Variants {
        model: Config.data.taskbar.enabled ? Quickshell.screens : []

        TaskbarWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        SearchWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        SettingsWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        DashboardWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        FrameWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }
}
