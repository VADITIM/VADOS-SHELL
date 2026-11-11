pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config
import "../utils/Log.js" as Log
import "../utils/History.js" as History

Singleton {
    id: notifications

    readonly property string serverName: "quickshell"
    readonly property bool isEnabled: Config.data.notifications.enabled
    property string owner: ""
    readonly property bool isServing: isEnabled && server.item !== null && owner === serverName
    readonly property bool isUnowned: isEnabled && owner === "none"
    readonly property bool isBlocked: isEnabled && owner !== "" && owner !== "none" && owner !== serverName
    readonly property string status: !isEnabled ? "off" : isServing ? "serving" : isBlocked ? "blocked by " + owner : isUnowned ? "unregistered" : "starting"
    readonly property var list: server.item ? Array.from(server.item.trackedNotifications.values).reverse() : []
    readonly property var latest: list.length > 0 ? list[0] : null
    property var unreadIds: []
    readonly property int unreadCount: list.filter(notification => unreadIds.indexOf(notification.id) >= 0).length
    readonly property bool hasUnread: unreadCount > 0
    readonly property bool isUrgent: list.some(notification => isCritical(notification) && unreadIds.indexOf(notification.id) >= 0)
    readonly property int historyLimit: Config.data.notifications.history
    readonly property var history: store.values.entries || []

    signal received(var notification)

    function accept(notification) {
        notification.tracked = true
        unreadIds = unreadIds.concat([notification.id])
        keep(notification)
        received(notification)
    }

    function iconOf(notification) {
        if (History.isStorableIcon(notification.image))
            return notification.image
        const name = notification.appIcon || DesktopEntries.byId(notification.desktopEntry)?.icon || ""
        if (History.isStorableIcon(name))
            return name
        return name.length > 0 ? Quickshell.iconPath(name, true) : ""
    }

    function keep(notification) {
        if (!History.isKept(notification))
            return
        store.update({ entries: History.record(history, History.entryOf(notification, Date.now(), iconOf(notification)), historyLimit) })
    }

    function liveOf(entry) {
        return list.find(candidate => candidate.id === entry.id) ?? null
    }

    function forget(entry) {
        liveOf(entry)?.dismiss()
        store.update({ entries: History.forget(history, entry.key) })
    }

    function openEntry(entry) {
        const live = liveOf(entry)
        if (live)
            open(live)
        else
            DesktopEntries.byId(entry.desktopEntry)?.execute()
    }

    function isCritical(notification) {
        return notification.urgency === NotificationUrgency.Critical
    }

    function isLow(notification) {
        return notification.urgency === NotificationUrgency.Low
    }

    function isAlive(notification) {
        return list.some(candidate => candidate.id === notification.id)
    }

    function markRead() {
        unreadIds = []
    }

    function dismiss(notification) {
        notification.dismiss()
    }

    function clear() {
        for (const notification of list.slice())
            notification.dismiss()
        store.update({ entries: [] })
        markRead()
    }

    function open(notification) {
        if (!notification)
            return
        const action = notification.actions.find(candidate => candidate.identifier === "default")
        if (action)
            action.invoke()
        else
            DesktopEntries.byId(notification.desktopEntry)?.execute()
        unreadIds = unreadIds.filter(identifier => identifier !== notification.id)
    }

    function readOwner(text) {
        const found = text.match(/"([^"]*)"/)
        owner = found ? found[1] : "none"
        if (isUnowned)
            Log.warn("notifications", "nobody holds org.freedesktop.Notifications although the server is on; run ipc call notifications disable, then enable")
        if (isBlocked)
            Log.warn("notifications", owner + " holds org.freedesktop.Notifications, so the shell gets no notifications; stop and mask that daemon, then run ipc call notifications enable")
    }

    function probeOwner() {
        owner = ""
        if (isEnabled)
            ownerDelay.restart()
    }

    onIsEnabledChanged: probeOwner()
    onHistoryLimitChanged: {
        if (store.isLoaded && history.length > historyLimit)
            store.update({ entries: History.trim(history, historyLimit) })
    }
    Component.onCompleted: probeOwner()

    function invoke(notification, identifier) {
        const action = notification.actions.find(candidate => candidate.identifier === identifier)
        if (action)
            action.invoke()
    }

    StateFile {
        id: store
        name: "notifications"
        defaults: ({ entries: [] })
    }

    LazyLoader {
        id: server
        active: Config.data.notifications.enabled

        NotificationServer {
            actionsSupported: true
            bodySupported: true
            bodyMarkupSupported: true
            imageSupported: true
            persistenceSupported: true
            onNotification: notification => notifications.accept(notification)
        }
    }

    Timer {
        id: ownerDelay
        interval: Motion.attention.ownerProbe
        onTriggered: ownerQuery.running = true
    }

    Process {
        id: ownerQuery
        command: ["busctl", "--user", "--auto-start=no", "call", "org.freedesktop.Notifications", "/org/freedesktop/Notifications", "org.freedesktop.Notifications", "GetServerInformation"]
        stdout: StdioCollector {
            onStreamFinished: notifications.readOwner(text)
        }
    }
}
