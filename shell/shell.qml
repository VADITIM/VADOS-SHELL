//@ pragma UseQApplication
//@ pragma NativeTextRendering
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

        OverlaySlot {
            id: searchSlot
            overlayKey: "search"

            SearchWindow {
                screen: searchSlot.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        OverlaySlot {
            id: settingsSlot
            overlayKey: "settings"

            SettingsWindow {
                screen: settingsSlot.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        OverlaySlot {
            id: dashboardSlot
            overlayKey: "dashboard"

            DashboardWindow {
                screen: dashboardSlot.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        OverlaySlot {
            id: notificationsSlot
            overlayKey: "notifications"

            NotificationMenuWindow {
                screen: notificationsSlot.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        OverlaySlot {
            id: screenshotSlot
            overlayKey: "screenshot"

            ScreenshotWindow {
                screen: screenshotSlot.modelData
            }
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
