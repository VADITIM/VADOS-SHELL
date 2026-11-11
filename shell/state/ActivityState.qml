pragma Singleton
import QtQuick
import Quickshell
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
