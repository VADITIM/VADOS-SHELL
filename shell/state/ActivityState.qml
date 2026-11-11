pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.services

Singleton {
    id: state

    readonly property var modes: ["hidden", "idle", "active", "expanded"]
    property string mode: "idle"
    property string screenName: ""
    property string lead: ""
    readonly property bool isAnyLive: Activities.isAnyLive
    readonly property string leadKey: Activities.order.includes(lead) ? lead : Activities.order[0] ?? "media"
    readonly property bool isReading: Overlays.stack.indexOf("notifications") >= 0
    property string clipboardScreen: ""
    readonly property bool canClipboard: Clipboard.isEnabled
    readonly property bool isRecording: Capture.isRecording
    property var places: ({})

    function place(name, where) {
        const next = Object.assign({}, places)
        next[name] = where
        places = next
    }

    function placeOn(name) {
        return places[name] ?? null
    }

    function copiedNotice(path) {
        return {
            id: "vados-screenshot",
            isNotice: true,
            appName: "Screenshot",
            desktopEntry: "vados-screenshot",
            summary: "COPIED",
            body: path,
            expireTimeout: Motion.capture.announce / 1000,
            urgency: 1,
            actions: []
        }
    }

    onIsRecordingChanged: {
        if (isRecording) {
            lead = "recording"
            if (mode === "hidden" || mode === "idle")
                mode = "active"
            Attention.announce(recordingNotice(), Capture.recordingScreen)
            return
        }
        if (mode === "expanded" && lead === "recording")
            fold()
        if (lead === "recording")
            lead = ""
    }

    function recordingNotice() {
        return {
            id: "vados-recorder",
            isNotice: true,
            appName: "Screen",
            desktopEntry: "vados-recorder",
            summary: "RECORDING NOW",
            body: Capture.recordingFolder,
            expireTimeout: Motion.capture.announce / 1000,
            urgency: 1,
            actions: []
        }
    }

    onIsAnyLiveChanged: {
        if (mode === "expanded")
            return
        lead = ""
        if (isAnyLive && mode === "idle")
            mode = "active"
        else if (!isAnyLive && mode === "active")
            mode = "idle"
    }

    onIsReadingChanged: {
        if (isReading)
            Notifications.markRead()
    }

    function modeOn(name) {
        return mode === "expanded" && screenName !== name ? "active" : mode
    }

    function isClipboardOn(name) {
        return canClipboard && name.length > 0 && clipboardScreen === name
    }

    function toggleClipboard(name) {
        if (isClipboardOn(name)) {
            closeClipboard()
            return
        }
        if (!canClipboard)
            return
        if (modeOn(name) === "expanded")
            fold()
        clipboardScreen = name
    }

    function closeClipboard() {
        clipboardScreen = ""
    }

    function set(name, wanted) {
        if (modes.indexOf(wanted) < 0)
            return
        if (wanted === "expanded")
            closeClipboard()
        if (wanted === "expanded" && leadKey === "notifications") {
            Overlays.open("notifications", name)
            return
        }
        if (wanted === "expanded") {
            screenName = name
            lead = leadKey
        }
        mode = wanted
    }

    function step(name, direction) {
        if (isClipboardOn(name)) {
            closeClipboard()
            return
        }
        const at = modes.indexOf(modeOn(name))
        set(name, modes[Math.max(0, Math.min(modes.length - 1, at + direction))])
    }

    function rotate(direction) {
        const order = mode === "expanded" ? Activities.order.filter(key => key !== "notifications") : Activities.order
        if (order.length < 2)
            return
        const at = Math.max(0, order.indexOf(leadKey))
        lead = order[(at + direction + order.length) % order.length]
    }

    function fold() {
        if (mode === "expanded")
            mode = isAnyLive ? "active" : "idle"
    }

    function toggle(name) {
        if (modeOn(name) === "expanded")
            fold()
        else
            set(name, "expanded")
    }

    function pin(key) {
        if (!Activities.keys.includes(key))
            return
        if (key === "notifications")
            fold()
        lead = key
    }

    Connections {
        target: Notifications

        function onUnreadCountChanged() {
            if (state.isReading && Notifications.unreadCount > 0)
                Qt.callLater(Notifications.markRead)
        }
    }
}
