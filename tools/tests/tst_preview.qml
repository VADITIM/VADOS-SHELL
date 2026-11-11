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

    function test_hoveringAnAlertOpensItAndHoldsIt() {
        failOnWarning(/.*/)
        window.sampleIndex = 0
        const peeked = peekOnce()
        const rest = Qt.size(peeked.taskbar.alertRect.width, peeked.taskbar.alertRect.height)
        const body = peeked.taskbar.alertRect
        mouseMove(peeked.alerts, body.x + body.width / 2, body.y + body.height / 2)
        tryVerify(() => peeked.alerts.isExpanded, 2000, "hovering opens the alert")
        verify(Attention.isHeld, "and holds its peek")
        tryVerify(() => peeked.taskbar.alertRect.height > rest.height && Math.abs(peeked.taskbar.alertRect.height - peeked.alerts.bodySize.height) < 1, 3000, "the body grows to fit the whole message")
        verify(peeked.taskbar.isAlertShown, "the face stays while the body grows")
        wait(Motion.attention.peek + 300)
        verify(Attention.peek !== null, "a hovered alert never goes")
        mouseMove(peeked.alerts, body.x + body.width / 2, body.y - Appearance.alerts.expandedWidth)
        tryVerify(() => !peeked.alerts.isExpanded, 2000, "leaving the alert retracts it")
        verify(!Attention.isHeld)
        tryVerify(() => Math.abs(peeked.taskbar.alertRect.height - rest.height) < 1, 3000, "back to its normal size")
        verify(Attention.peek !== null, "it lingers after the hover")
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

    function openClipboard() {
        const taskbar = sceneChild("clipboardRect")
        const history = sceneChild("ordered")
        verify(taskbar !== null && history !== null)
        ActivityState.toggleClipboard(window.screenName)
        tryVerify(() => taskbar.isClipboardShown, 3000, "the clipboard grows out of the activity pill")
        tryVerify(() => taskbar.clipboardRect.width >= Appearance.clipboard.width - 1, 3000)
        wait(Motion.clipboard.faceEnter + Motion.clipboard.stagger * 3)
        return { taskbar: taskbar, history: history }
    }

    function closeClipboard(taskbar) {
        ActivityState.closeClipboard()
        tryVerify(() => !taskbar.isClipboardShown, 3000)
        tryVerify(() => taskbar.clipboardRect.width < Appearance.clipboard.width / 2, 3000, "the clipboard folds back into the activity pill")
    }

    function rowPoint(opened, slot) {
        const body = opened.taskbar.clipboardRect
        const look = Appearance.clipboard
        const top = body.y + look.padding + look.header + look.headerGap
        return Qt.point(body.x + body.width / 2, top + slot * (look.row + look.rowGap) + look.row / 2)
    }

    function test_aClickOnAClipboardRowCopiesItAndFolds() {
        failOnWarning(/.*/)
        const opened = openClipboard()
        const wanted = opened.history.ordered[1]
        const count = Clipboard.entries.length
        const point = rowPoint(opened, 1)
        mouseClick(opened.history, point.x, point.y)
        compare(Clipboard.picked[Clipboard.picked.length - 1], wanted.key, "a click copies that entry")
        compare(Clipboard.entries.length, count, "copying again adds no entry")
        compare(Clipboard.entries[0].key, wanted.key, "it moves to the top")
        tryVerify(() => !ActivityState.isClipboardOn(window.screenName), 1000, "picking folds the clipboard")
        closeClipboard(opened.taskbar)
    }

    function test_swipingAClipboardRowRemovesIt() {
        failOnWarning(/.*/)
        const opened = openClipboard()
        const wanted = opened.history.ordered[0]
        const picked = Clipboard.picked.length
        const point = rowPoint(opened, 0)
        mouseDrag(opened.history, point.x, point.y, Motion.clipboard.swipe * 2, 0)
        compare(Clipboard.picked.length, picked, "a swipe is not a click")
        verify(!Clipboard.entries.some(entry => entry.key === wanted.key), "the swiped entry is gone")
        closeClipboard(opened.taskbar)
    }

    function test_clipboardTogglingFasterThanItsMotionEndsAtRest() {
        failOnWarning(/.*/)
        const taskbar = sceneChild("clipboardRect")
        for (let round = 0; round < 6; round++) {
            ActivityState.toggleClipboard(window.screenName)
            wait(round * 35)
        }
        ActivityState.closeClipboard()
        tryVerify(() => !taskbar.isClipboardShown, 3000)
        tryVerify(() => taskbar.clipboardRect.width < Appearance.clipboard.width / 2, 3000)
    }
    function openScreenshot() {
        const shot = overlayModule("strokes")
        verify(shot !== null)
        Capture.shoot(window.screenName)
        tryVerify(() => Overlays.phaseOf("screenshot", window.screenName) === "active", 2000, "the screen darkens at once")
        verify(!Overlays.isTaskbarAway(window.screenName), "the screenshot keeps the taskbar where it is")
        tryVerify(() => shot.activeFocus, 1000, "the screenshot owns the keyboard")
        return shot
    }

    function test_screenshotSelectsDrawsAndCopies() {
        failOnWarning(/.*/)
        const shot = openScreenshot()
        const toolbar = findItem(shot, item => item.wheelShare !== undefined)
        verify(toolbar !== null)
        verify(toolbar.isShown, "the toolbar is there at once, before an area is chosen")
        const pill = ActivityState.placeOn(window.screenName)
        fuzzyCompare(toolbar.startSize.height, pill.height, 0.5, "it starts as the activity pill")
        fuzzyCompare(shot.pillCenterY, pill.centerY, 0.5, "right on top of it")
        tryVerify(() => toolbar.growth > 0.99, 1000, "and grows along the taskbar")
        mouseDrag(shot, 400, 200, 500, 300)
        verify(shot.hasSelection)
        fuzzyCompare(shot.selection.width, 500, 2)
        fuzzyCompare(shot.selection.height, 300, 2)
        shot.pick("paint")
        mouseDrag(shot, 1000, 600, 80, 40)
        compare(shot.strokes.length, 1, "paint draws outside the area too")
        shot.pick("shape")
        mouseDrag(shot, 600, 260, 60, 60)
        mouseDrag(shot, 700, 300, 40, 40)
        compare(shot.strokes.length, 3, "several shapes stay")
        mouseDrag(shot, 660, 320, 40, 20)
        compare(shot.strokes.length, 3, "a corner drag reshapes, it draws nothing new")
        fuzzyCompare(shot.strokes[1].points[1].x, 700, 2)
        fuzzyCompare(shot.strokes[1].points[1].y, 340, 2)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(shot.strokes.length, 2, "Ctrl+Z takes the last stroke back")
        shot.pick("select")
        mouseDrag(shot, 450, 250, 100, 0)
        fuzzyCompare(shot.selection.x, 500, 2)
        const tapX = 300
        const tapY = shot.height - 100
        mouseClick(shot, tapX, tapY)
        compare(Overlays.phaseOf("screenshot", window.screenName), "active", "a tap outside never closes")
        fuzzyCompare(shot.selection.x, Math.max(0, Math.min(shot.width - 500, tapX - 250)), 2, "it moves the area there")
        fuzzyCompare(shot.selection.y, Math.max(0, Math.min(shot.height - 300, tapY - 150)), 2)
        shot.toggleMenu("color")
        tryVerify(() => toolbar.wheelShare > 0.99, 1000, "the colour wheel pops out of the pill")
        shot.toggleMenu("color")
        tryVerify(() => toolbar.wheelShare < 0.01, 1000)
        const delivered = Capture.delivered.length
        keyClick(Qt.Key_C, Qt.ControlModifier)
        tryVerify(() => Capture.delivered.length === delivered + 1, 2000, "Ctrl+C copies the area")
        tryVerify(() => Attention.peek !== null && Attention.peek.notifications[0].summary === "COPIED", 2000, "and says so")
        tryVerify(() => Overlays.phaseOf("screenshot", window.screenName) === "idle", 2000, "and the screen comes back")
        Attention.dismissPeek()
    }

    function test_escapeRestoresTheScreenFast() {
        failOnWarning(/.*/)
        const shot = openScreenshot()
        mouseDrag(shot, 300, 200, 200, 150)
        const delivered = Capture.delivered.length
        keyClick(Qt.Key_Escape)
        tryVerify(() => Overlays.phaseOf("screenshot", window.screenName) === "idle", Motion.capture.leave + 600)
        compare(Capture.delivered.length, delivered, "Escape copies nothing")
    }

    function test_recordingPillPausesOnClickAndOpensOnHover() {
        failOnWarning(/.*/)
        Activities.isCalling = false
        Activities.hasMedia = false
        Capture.record(window.screenName)
        const pill = findItem(window.contentItem, item => item.isRecordingLead !== undefined)
        verify(pill !== null)
        tryCompare(Attention, "peek", null, 3000, "RECORDING NOW gives way after its moment")
        tryVerify(() => pill.face === "active" && pill.isFaceShown, 3000, "the pill turns into the recording pill")
        const center = pill.mapToItem(window.contentItem, pill.spineX, 0)
        mouseClick(window.contentItem, center.x, center.y)
        verify(Capture.isPaused, "a click pauses")
        mouseClick(window.contentItem, center.x, center.y)
        verify(!Capture.isPaused, "and a second click resumes")
        mouseMove(window.contentItem, center.x, center.y)
        tryCompare(ActivityState, "mode", "expanded", 2000, "hovering opens the recording controls")
        const view = findItem(window.contentItem, item => item.controls !== undefined)
        tryVerify(() => view.isShown, 3000)
        mouseMove(window.contentItem, window.width / 2, 40)
        tryCompare(ActivityState, "mode", "active", 2000, "leaving folds it back")
        Capture.stop()
        tryVerify(() => ActivityState.leadKey !== "recording", 1000)
        Activities.isCalling = true
        Activities.hasMedia = true
        ActivityState.lead = ""
    }
}
