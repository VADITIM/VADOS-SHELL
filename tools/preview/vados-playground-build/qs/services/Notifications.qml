pragma Singleton
import QtQuick
QtObject {
    property bool isServing: false
    property bool isBlocked: false
    property string owner: ""
    property string status: "off"
    property var list: []
    property var latest: null
    property var unreadIds: []
    readonly property int unreadCount: list.filter(notification => unreadIds.indexOf(notification.id) >= 0).length
    readonly property bool hasUnread: unreadCount > 0
    readonly property bool isUrgent: list.some(notification => isCritical(notification) && unreadIds.indexOf(notification.id) >= 0)
    signal received(var notification)
    function isCritical(notification) { return notification.urgency === 2 }
    function isLow(notification) { return notification.urgency === 0 }
    function isAlive(notification) { return list.some(candidate => candidate.id === notification.id) }
    function markRead() { unreadIds = [] }
    property int posted: 0
    property var opened: []
    function dismiss(notification) { list = list.filter(candidate => candidate.id !== notification.id) }
    function clear() { list = []; unreadIds = []; history = [] }
    function open(notification) { opened = opened.concat([notification]); unreadIds = unreadIds.filter(identifier => identifier !== notification.id) }
    function invoke(notification, identifier) {}
    property var history: []
    property var openedEntries: []
    function liveOf(entry) { return list.find(candidate => candidate.id === entry.id) ?? null }
    function forget(entry) { dismiss(entry); history = history.filter(candidate => candidate.key !== entry.key) }
    function openEntry(entry) { openedEntries = openedEntries.concat([entry]); const live = liveOf(entry); if (live) open(live) }
    function post(appName, desktopEntry, summary, body, urgency) {
        posted++
        const notification = { id: posted, appName: appName, desktopEntry: desktopEntry, summary: summary, body: body, urgency: urgency, expireTimeout: 0, actions: [] }
        list = [notification].concat(list)
        latest = notification
        unreadIds = unreadIds.concat([notification.id])
        history = [{ key: posted + ":" + posted, id: posted, appName: appName, desktopEntry: desktopEntry, summary: summary, body: body, urgency: urgency, icon: "", time: Date.now() }].concat(history)
        received(notification)
        return notification
    }
}
