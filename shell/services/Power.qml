pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function lock() {
        if (!Lock.request())
            Quickshell.execDetached(["loginctl", "lock-session"])
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    function hibernate() {
        Quickshell.execDetached(["sh", "-c", "systemctl hibernate || systemctl suspend"])
    }

    function restart() {
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function logOut() {
        Quickshell.execDetached(["sh", "-c", "loginctl terminate-session \"${XDG_SESSION_ID:-$(loginctl show-user \"$USER\" -p Display --value)}\""])
    }

    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"])
    }
}
