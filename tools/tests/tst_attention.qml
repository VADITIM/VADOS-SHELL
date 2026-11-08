import QtQuick
import QtTest
import qs.config
import qs.services
import qs.state

TestCase {
    name: "Attention"

    readonly property bool isQuiet: Attention.isQuiet

    function make(identifier, urgency, timeout) {
        return { id: identifier, urgency: urgency, expireTimeout: timeout }
    }

    function arrive(notification) {
        Notifications.list = [notification].concat(Notifications.list)
        Notifications.received(notification)
    }

    function settleBatch() {
        wait(Motion.attention.batch + 100)
    }

    function cleanup() {
        Attention.dismissPeek()
        Notifications.list = []
        Config.setDoNotDisturb(false)
        Compositor.activeWindow = null
    }

    function test_batchesNormalNotifications() {
        arrive(make(1, 1, 0))
        arrive(make(2, 1, 0))
        settleBatch()
        verify(Attention.peek !== null)
        compare(Attention.peek.notifications.length, 2)
        verify(!Attention.peek.isUrgent)
    }

    function test_quietLetsOnlyCriticalThrough() {
        Config.setDoNotDisturb(true)
        arrive(make(3, 1, 0))
        arrive(make(4, 2, 0))
        settleBatch()
        compare(Attention.peek.notifications.length, 1)
        compare(Attention.peek.notifications[0].id, 4)
        verify(Attention.peek.isUrgent)
        Notifications.list = Notifications.list.filter(notification => notification.id !== 4)
        compare(Attention.peek, null, "a dismissed notification leaves its peek")
    }

    function test_fullscreenAndLowStayQuiet() {
        Compositor.activeWindow = { isFullscreen: true }
        arrive(make(5, 1, 0))
        arrive(make(6, 0, 0))
        settleBatch()
        compare(Attention.peek, null)
    }

    function test_peekExpiresWithItsTimeout() {
        arrive(make(7, 1, 1))
        settleBatch()
        verify(Attention.peek !== null)
        tryCompare(Attention, "peek", null, 2000)
    }
}
