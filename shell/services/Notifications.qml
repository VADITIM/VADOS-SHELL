pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: notifications

    readonly property bool isServing: Config.data.notifications.enabled && server.item !== null
    readonly property var list: server.item ? Array.from(server.item.trackedNotifications.values).reverse() : []
    readonly property var latest: list.length > 0 ? list[0] : null
    property var unreadIds: []
    readonly property int unreadCount: list.filter(notification => unreadIds.indexOf(notification.id) >= 0).length
    readonly property bool hasUnread: unreadCount > 0
    readonly property bool isUrgent: list.some(notification => isCritical(notification) && unreadIds.indexOf(notification.id) >= 0)

    signal received(var notification)

    function accept(notification) {
        notification.tracked = true
        unreadIds = unreadIds.concat([notification.id])
        received(notification)
    }

    function isCritical(notification) {
        return notification.urgency === NotificationUrgency.Critical
    }

    function isLow(notification) {
        return notification.urgency === NotificationUrgency.Low
    }

    function isAlive(notification) {
        return list.indexOf(notification) >= 0
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
        markRead()
    }

    function invoke(notification, identifier) {
        const action = notification.actions.find(candidate => candidate.identifier === identifier)
        if (action)
            action.invoke()
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
}
