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

    function cleanup() {
        const taskbar = sceneChild("alertRect")
        if (taskbar)
            taskbar.isCovered = false
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

    function findItem(root, isWanted) {
        if (isWanted(root))
            return root
        for (const child of root.children) {
            const found = findItem(child, isWanted)
            if (found)
                return found
        }
        return null
    }

    function expandActivity(key, isWanted) {
        ActivityState.pin(key)
        ActivityState.set(window.screenName, "expanded")
        const view = findItem(window.contentItem, isWanted)
        verify(view !== null)
        tryVerify(() => view.isShown, 3000, "the " + key + " view opens out of the activity pill")
        return view
    }

    function foldActivity(view) {
        ActivityState.fold()
        ActivityState.lead = ""
        tryVerify(() => !view.isShown, 3000)
    }

    function openMenu() {
        const menu = overlayModule("deviceIndex")
        verify(menu !== null)
        tryVerify(() => Overlays.phaseOf("notifications", window.screenName) === "active", 5000, "the notifications menu opens")
        tryVerify(() => menu.isSendShown, 3000, "the send body splits off")
        return menu
    }

    function waitForTaskbar() {
        tryVerify(() => !Overlays.isTaskbarAway(window.screenName), 10000, "the taskbar comes back")
    }

    function closeMenu() {
        Overlays.close("notifications")
        waitForTaskbar()
    }

    function test_theBellOpensTheNotificationMenu() {
        failOnWarning(/.*/)
        Notifications.clear()
        Config.setDoNotDisturb(true)
        window.sampleIndex = 0
        const first = window.postSample(1)
        const second = window.postSample(1)
        Config.setDoNotDisturb(false)
        verify(Notifications.unreadCount >= 2, "held notifications wait as unread")
        ActivityState.pin("notifications")
        ActivityState.set(window.screenName, "expanded")
        compare(Overlays.top, "notifications", "expanding the bell opens the menu")
        verify(ActivityState.mode !== "expanded", "the pill itself does not expand")
        ActivityState.lead = ""
        const menu = openMenu()
        compare(Notifications.unreadCount, 0, "opening the menu reads everything")
        compare(menu.entries[0].id, second.id, "the newest is on top")
        const row = findItem(menu, item => item.entry !== undefined && item.forgotten !== undefined && item.entry.key === menu.entries[0].key)
        verify(row !== null)
        tryVerify(() => row.presence > 0.99, 2000)
        mouseDrag(row, row.width / 2, row.height / 2, Motion.alerts.swipe * 2, 0)
        tryVerify(() => !Notifications.history.some(entry => entry.id === second.id), 1000, "a swiped row leaves the history")
        const other = findItem(menu, item => item.entry !== undefined && item.forgotten !== undefined && item.entry.key === menu.entries[0].key)
        verify(other !== null)
        verify(other.presence > 0.99, "the rows left stay where they are instead of entering again")
        mouseClick(other, other.width / 2, other.height / 2)
        compare(Notifications.openedEntries[Notifications.openedEntries.length - 1].id, first.id, "a tap opens its app")
        verify(!Overlays.isOpen("notifications", window.screenName), "and closes the menu")
        waitForTaskbar()
        Notifications.clear()
    }

    function test_theMenuWorksFromTheKeyboard() {
        failOnWarning(/.*/)
        Notifications.clear()
        window.postSample(1)
        Overlays.open("notifications", window.screenName)
        const menu = openMenu()
        compare(menu.zone, "list")
        keyClick(Qt.Key_Tab)
        compare(menu.zone, "actions")
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Return)
        tryVerify(() => Attention.isQuiet, 1000, "the mute bubble turns do-not-disturb on")
        keyClick(Qt.Key_Return)
        tryVerify(() => !Attention.isQuiet, 1000, "and off again")
        keyClick(Qt.Key_Tab)
        compare(menu.zone, "send")
        keyClick(Qt.Key_Return)
        compare(menu.deviceIndex, 0, "Enter picks a device")
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Right)
        keyClick(Qt.Key_Right)
        compare(menu.cursor, Transfer.devices.length, "the cursor reaches SEND")
        keyClick(Qt.Key_Return)
        compare(Transfer.sent[Transfer.sent.length - 1], Transfer.devices[0].peer, "SEND sends to the chosen device")
        verify(!Overlays.isOpen("notifications", window.screenName), "sending closes the menu for the file chooser")
        waitForTaskbar()
        Overlays.open("notifications", window.screenName)
        openMenu()
        keyClick(Qt.Key_Escape)
        verify(!Overlays.isOpen("notifications", window.screenName), "Escape closes it")
        waitForTaskbar()
        Notifications.clear()
    }

    function test_coveredTaskbarStaysHiddenThroughAnOverlay() {
        failOnWarning(/.*/)
        const taskbar = sceneChild("alertRect")
        verify(taskbar !== null)
        const clock = taskbar.children.find(child => child.toString().startsWith("Clock"))
        verify(clock !== undefined)
        taskbar.isCovered = true
        taskbar.isSummoned = false
        tryVerify(() => !clock.isShown, 2000)
        Overlays.open("dashboard", window.screenName)
        tryVerify(() => {
            verify(!clock.isShown, "the clock of a covered taskbar never shows while the dashboard opens")
            return Overlays.phaseOf("dashboard", window.screenName) === "active"
        }, 5000)
        Overlays.close("dashboard")
        tryVerify(() => {
            verify(!clock.isShown && !taskbar.isRevealed, "a covered taskbar does not come back when the dashboard leaves")
            return Overlays.phaseOf("dashboard", window.screenName) === "idle"
        }, 5000)
        taskbar.isCovered = false
        tryVerify(() => clock.isShown, 2000, "the taskbar comes back once nothing covers it")
    }

    function test_clearingEmptiesTheHistory() {
        failOnWarning(/.*/)
        window.postSample(1)
        window.postSample(1)
        Overlays.open("notifications", window.screenName)
        const menu = openMenu()
        const bubble = findItem(menu, item => item.modelData !== undefined && item.modelData !== null && item.modelData.key === "clear")
        verify(bubble !== null)
        tryVerify(() => bubble.presence > 0.99, 2000, "the trash bubble buds out of the wall")
        mouseClick(bubble, bubble.width / 2, bubble.height / 2)
        compare(Notifications.history.length, 0)
        compare(menu.zone, "actions", "the cursor leaves the empty list")
        closeMenu()
    }

    function test_trayOpensOutOfThePill() {
        failOnWarning(/.*/)
        const view = expandActivity("tray", item => item.openItem !== undefined)
        compare(view.items.length, Tray.items.length)
        const cell = findItem(view, item => item.hasIcon !== undefined && item.index === 0)
        verify(cell !== null)
        tryVerify(() => cell.presence > 0.99, 2000)
        mouseClick(cell, cell.width / 2, cell.height / 2)
        compare(Tray.opened[Tray.opened.length - 1], Tray.items[0].id, "a click activates the tray item")
        mouseClick(cell, cell.width / 2, cell.height / 2, Qt.RightButton)
        compare(Tray.opened[Tray.opened.length - 1], Tray.items[0].id + " menu", "a right click opens its menu")
        foldActivity(view)
    }
}
