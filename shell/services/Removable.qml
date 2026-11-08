pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: removable

    property var devices: []

    function read(text) {
        let tree
        try {
            tree = JSON.parse(text)
        } catch (error) {
            return
        }
        const found = []
        for (const disk of tree.blockdevices ?? []) {
            const isHotplug = disk.hotplug === true || disk.hotplug === "1"
            if (!isHotplug || disk.tran !== "usb" || disk.type !== "disk")
                continue
            const parts = disk.children?.length ? disk.children : [disk]
            found.push({
                path: disk.path,
                label: (parts.find(part => part.label)?.label ?? disk.name).toUpperCase(),
                size: disk.size,
                partitions: parts.map(part => part.path)
            })
        }
        devices = found
    }

    function eject(device) {
        const unmounts = device.partitions.map(path => "udisksctl unmount --no-user-interaction -b " + path + " ;")
        Quickshell.execDetached(["sh", "-c", unmounts.join(" ") + " udisksctl power-off --no-user-interaction -b " + device.path])
    }

    Component.onCompleted: query.running = true

    Process {
        id: monitor
        command: ["udevadm", "monitor", "--udev", "--subsystem-match=block"]
        stdout: SplitParser {
            onRead: settle.restart()
        }
    }

    Supervisor {
        name: "removable"
        process: monitor
    }

    Timer {
        id: settle
        interval: 400
        onTriggered: query.running = true
    }

    Process {
        id: query
        command: ["lsblk", "-J", "-o", "NAME,PATH,LABEL,SIZE,HOTPLUG,TRAN,TYPE"]
        stdout: StdioCollector {
            onStreamFinished: removable.read(text)
        }
    }
}
