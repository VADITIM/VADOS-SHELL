//@ pragma UseQApplication
//@ pragma NativeTextRendering
import QtQuick
import Quickshell
import qs.config
import qs.state
import qs.services
import qs.windows
import qs.keybinds
import "utils/Widgets.js" as Widgets

ShellRoot {
    id: root

    readonly property var desktopSources: Widgets.sourcesShown(Config.data.widgets.layout, Array.from(Quickshell.screens, screen => ({
        name: screen.name,
        width: screen.width,
        height: screen.height,
        isCovered: Compositor.activeWindow?.isFullscreen === true && Compositor.activeWindow.screen === screen.name
    })), Appearance.widgets)

    Shortcuts {}

    Binding {
        target: Hardware
        property: "isOnDesktop"
        value: root.desktopSources.indexOf("hardware") >= 0
    }

    Binding {
        target: Weather
        property: "isOnDesktop"
        value: root.desktopSources.indexOf("weather") >= 0
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            Overlays.keepScreens(Array.from(Quickshell.screens, screen => screen.name))
        }
    }

    Variants {
        model: Config.data.taskbar.enabled ? Quickshell.screens : []

        ClipboardDismissWindow {
            required property ShellScreen modelData
            screen: modelData
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
        model: Array.from(Quickshell.screens).filter(screen => (Config.data.wallpaper.path.length > 0 && !Compositor.capabilities.ownBackground) || Widgets.hasLayout(Config.data.widgets.layout, screen.name))

        WidgetWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    LazyLoader {
        active: Builtins.opened.indexOf("calculator") >= 0

        CalculatorWindow {}
    }

    LockWindow {}

    Variants {
        model: Quickshell.screens

        CornerWindow {
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
