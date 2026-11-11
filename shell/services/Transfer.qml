pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../utils/Senders.js" as Senders
import "../utils/Log.js" as Log

Singleton {
    id: transfer

    property var installed: []
    readonly property bool isPicking: FileChooser.isPicking
    property string pendingPeer: ""
    readonly property string appKey: Config.data.send.app
    readonly property var app: Senders.byKey(appKey)
    readonly property string appName: app ? app.name : ""
    readonly property bool isAvailable: app !== null && installed.indexOf(appKey) >= 0
    readonly property var devices: Senders.devicesOf(Config.data.send.devices)

    function nextApp() {
        return Senders.nextOf(installed, appKey)
    }

    function send(peer) {
        if (!isAvailable || isPicking)
            return
        pendingPeer = peer
        FileChooser.choose("Send with " + appName, "files", files => transfer.deliver(files))
    }

    function deliver(files) {
        for (const file of files)
            Quickshell.execDetached(Senders.sendCommand(app, pendingPeer, file))
        if (files.length > 0)
            Log.info("transfer", "sending " + files.length + " file" + (files.length === 1 ? "" : "s") + " with " + appKey + (pendingPeer.length > 0 ? " to " + pendingPeer : ""))
    }

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "for name in \"$@\"; do command -v \"$name\" >/dev/null 2>&1 && echo \"$name\"; done", "sh"].concat(Senders.senders.map(sender => sender.binary))
        stdout: StdioCollector {
            onStreamFinished: transfer.installed = Senders.senders.filter(sender => text.split("\n").indexOf(sender.binary) >= 0).map(sender => sender.key)
        }
    }
}
