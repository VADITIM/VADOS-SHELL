//@ pragma UseQApplication
// VAD/OS Shell entry point. Run with: qs -p ~/.config/vados/shell
import Quickshell
import qs.windows

ShellRoot {
    Variants {
        model: Quickshell.screens

        BarWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }
}
