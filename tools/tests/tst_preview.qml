import QtQuick
import QtTest
import qs.config
import qs.services
import qs.state

TestCase {
    name: "Preview"

    property var window: null

    function initTestCase() {
        failOnWarning(/.*/)
        const component = Qt.createComponent(Qt.resolvedUrl("../preview/play.qml"))
        compare(component.status, Component.Ready, component.errorString())
        window = component.createObject(null)
        verify(window !== null)
        wait(800)
    }

    function cleanupTestCase() {
        window.destroy()
    }

    function test_wholeShellLoadsWithoutWarnings() {
        verify(window !== null)
    }

    function overlayModule(propertyName) {
        const scene = window.contentItem.children[0]
        for (const child of scene.children) {
            if (child[propertyName] !== undefined && child.isOpen !== undefined)
                return child
        }
        return null
    }

    function test_switchingFromTheDashboardToSearchNeverShowsTheTaskbar() {
        failOnWarning(/.*/)
        const search = overlayModule("favoriteIds")
        verify(search !== null)
        Overlays.open("dashboard", window.screenName)
        tryCompare(Overlays, "top", "dashboard")
        tryVerify(() => Overlays.phaseOf("dashboard", window.screenName) === "active", 5000, "the preview reports overlay phases")
        Overlays.open("search", window.screenName)
        verify(!search.isOpen, "search waits for the dashboard's circle instead of gathering the taskbar parts again")
        tryVerify(() => {
            verify(Overlays.isTaskbarAway(window.screenName), "the taskbar showed during the swap")
            return Overlays.phaseOf("search", window.screenName) === "active"
        }, 10000)
        Overlays.close("search")
        tryVerify(() => !Overlays.isTaskbarAway(window.screenName), 10000)
    }

    function test_frameDebuggerOwnsTheKeyboardOverTheSearchField() {
        failOnWarning(/.*/)
        Overlays.toggle("search", window.screenName)
        tryVerify(() => window.activeFocusItem !== null && window.activeFocusItem.toString().startsWith("QQuickTextInput"), 2000)
        const field = window.activeFocusItem
        FrameDebug.toggle(window.screenName)
        tryVerify(() => window.activeFocusItem !== field, 1000)
        FrameDebug.close()
        tryCompare(window, "activeFocusItem", field)
        Overlays.close("search")
        tryVerify(() => !Overlays.isTaskbarAway(window.screenName), 10000)
    }

    function sceneChild(propertyName) {
        const scene = window.contentItem.children[0]
        for (const child of scene.children) {
            if (child[propertyName] !== undefined)
                return child
        }
        return null
    }

    function peekOnce() {
        const taskbar = sceneChild("alertRect")
        const alerts = sceneChild("bodySize")
        verify(taskbar !== null && alerts !== null)
        const notification = window.postSample(1)
        tryVerify(() => Attention.peek !== null, 3000, "the notification peeks")
        tryVerify(() => taskbar.isAlertShown, 3000, "the activity pill grows into the alert")
        tryVerify(() => Math.abs(taskbar.alertRect.width - alerts.bodySize.width) < 1 && Math.abs(taskbar.alertRect.height - alerts.bodySize.height) < 1, 3000, "the pill settles at the alert size")
        return { taskbar: taskbar, alerts: alerts, notification: notification }
    }

    function finishAlert(taskbar) {
        tryCompare(Attention, "peek", null, 3000)
        tryVerify(() => !taskbar.isAlertShown, 3000)
        tryVerify(() => taskbar.alertRect.width < Appearance.alerts.width / 2, 3000, "the alert folds back into the activity pill")
        Notifications.clear()
    }

    function test_alertPeeksAndATapOpensItsApp() {
        failOnWarning(/.*/)
        window.sampleIndex = 0
        const peeked = peekOnce()
        compare(peeked.alerts.source.key, "discord")
        const body = peeked.taskbar.alertRect
        mouseClick(peeked.alerts, body.x + body.width / 2, body.y + body.height / 2)
        compare(Notifications.opened[Notifications.opened.length - 1], peeked.notification, "a tap opens the notification's app")
        finishAlert(peeked.taskbar)
    }

    function test_swipingAnAlertAwayKeepsTheNotification() {
        failOnWarning(/.*/)
        const peeked = peekOnce()
        const body = peeked.taskbar.alertRect
        const opened = Notifications.opened.length
        mouseDrag(peeked.alerts, body.x + body.width / 2, body.y + body.height / 2, Motion.alerts.swipe * 2, 0)
        compare(Notifications.opened.length, opened, "a swipe is not a tap")
        verify(Notifications.isAlive(peeked.notification), "a swiped alert stays in the history")
        finishAlert(peeked.taskbar)
    }

    function test_alertsTogglingFasterThanTheirMotionEndAtRest() {
        failOnWarning(/.*/)
        const taskbar = sceneChild("alertRect")
        for (let round = 0; round < 6; round++) {
            window.postSample(round % 2 === 0 ? 1 : 2)
            wait(Motion.attention.batch + round * 40)
            Attention.dismissPeek()
            wait(round * 30)
        }
        finishAlert(taskbar)
        verify(!taskbar.isAlertShown)
    }

    function test_aShortDragSettlesBack() {
        failOnWarning(/.*/)
        const peeked = peekOnce()
        const body = peeked.taskbar.alertRect
        mouseDrag(peeked.alerts, body.x + body.width / 2, body.y + body.height / 2, Motion.alerts.swipe / 3, 0, Qt.LeftButton, Qt.NoModifier, 400)
        verify(Attention.peek !== null, "a short drag does not dismiss")
        tryCompare(peeked.alerts, "slide", 0, 2000)
        Attention.dismissPeek()
        finishAlert(peeked.taskbar)
    }
}
