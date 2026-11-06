//@ pragma UseQApplication
import Quickshell
import qs.config
import qs.windows
import qs.keybinds

ShellRoot {
    Shortcuts {}

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
}
