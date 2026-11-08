pragma Singleton
import QtQuick
import Quickshell
import qs.config
import qs.services

Singleton {
    id: attention

    readonly property bool isQuiet: Config.data.attention.doNotDisturb
    readonly property bool isFullscreen: Compositor.activeWindow?.isFullscreen ?? false
    property var peek: null
    property var held: []

    function mayPeek(notification) {
        if (Notifications.isCritical(notification))
            return true
        if (Notifications.isLow(notification))
            return false
        return !isQuiet && !isFullscreen
    }

    function admit(notification) {
        if (!mayPeek(notification))
            return
        held = held.concat([notification])
        if (!batch.running)
            batch.start()
    }

    function durationOf(notifications) {
        return notifications.reduce((longest, notification) => Math.max(longest, notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : Motion.attention.peek), 0)
    }

    function place(notifications, screenName) {
        if (notifications.length === 0) {
            dismissPeek()
            return
        }
        const isUrgent = notifications.some(notification => Notifications.isCritical(notification))
        peek = { notifications: notifications, isUrgent: isUrgent, screen: screenName }
        if (isUrgent) {
            expiry.stop()
            return
        }
        expiry.interval = durationOf(notifications)
        expiry.restart()
    }

    function showHeld() {
        const arrived = held.filter(notification => Notifications.isAlive(notification))
        held = []
        if (arrived.length === 0)
            return
        const shown = peek ? peek.notifications.concat(arrived) : arrived
        place(shown, peek ? peek.screen : Compositor.focusedScreen)
    }

    function dismissPeek() {
        expiry.stop()
        peek = null
    }

    function setQuiet(isOn) {
        Config.setDoNotDisturb(isOn)
    }

    Connections {
        target: Notifications

        function onReceived(notification) {
            attention.admit(notification)
        }

        function onListChanged() {
            if (!attention.peek)
                return
            const alive = attention.peek.notifications.filter(notification => Notifications.isAlive(notification))
            if (alive.length !== attention.peek.notifications.length)
                attention.place(alive, attention.peek.screen)
        }
    }

    Timer {
        id: batch
        interval: Motion.attention.batch
        onTriggered: attention.showHeld()
    }

    Timer {
        id: expiry
        onTriggered: attention.dismissPeek()
    }
}
