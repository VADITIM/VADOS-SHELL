pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: activity

    property string openScreen: ""
    property string pinnedKind: ""

    readonly property var notificationEntry: Notifications.list.length > 0 ? ({
        kind: "notifications",
        count: Notifications.list.length,
        unread: Notifications.unreadCount,
        isUrgent: Notifications.isUrgent,
        latest: Notifications.latest
    }) : null
    readonly property var trayEntry: Tray.items.length > 0 ? ({
        kind: "tray",
        count: Tray.items.length,
        unread: 0,
        isUrgent: false,
        latest: null
    }) : null
    readonly property var entries: [notificationEntry, trayEntry].filter(entry => entry !== null)
    readonly property var current: entries.find(entry => entry.kind === pinnedKind)
        ?? entries.find(entry => entry.isUrgent)
        ?? entries.find(entry => entry.unread > 0)
        ?? entries[0]
        ?? null
    readonly property bool hasActivity: entries.length > 0

    function isOpenOn(screenName) {
        return openScreen === screenName
    }

    function open(screenName) {
        openScreen = screenName
        Notifications.markRead()
    }

    function close() {
        openScreen = ""
        pinnedKind = ""
    }

    function toggle(screenName) {
        if (openScreen.length > 0)
            close()
        else
            open(screenName)
    }

    function pin(kind) {
        pinnedKind = entries.some(entry => entry.kind === kind) ? kind : ""
    }
}
