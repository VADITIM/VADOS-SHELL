pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"])
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    function restart() {
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"])
    }
}
