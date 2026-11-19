pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/About.js" as About

Singleton {
    id: machine

    property string os: ""
    property string kernel: ""
    property string host: ""
    property real bootTime: 0

    FileView {
        path: "/etc/os-release"
        onLoaded: machine.os = About.osNameOf(text())
    }

    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: machine.kernel = text().trim()
    }

    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: machine.host = text().trim()
    }

    FileView {
        path: "/proc/uptime"
        onLoaded: machine.bootTime = Date.now() - parseFloat(text()) * 1000
    }
}
