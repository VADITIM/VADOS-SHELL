import QtQuick
import QtQuick.Window
import qs.config
import qs.state
import qs.services
import qs.modules.taskbar
import qs.modules.alerts
import qs.modules.clipboard
import qs.modules.search
import qs.modules.settings
import qs.modules.dashboard
import qs.modules.notifications
import qs.modules.framedebug
import qs.windows
import QtCore as Core

Window {
    id: root

    readonly property string screenName: "play"
    readonly property bool isRight: Config.data.taskbar.side === "right"
    property Item focusBeforeFrames: null
    property int sampleIndex: 0
    readonly property var peek: Attention.peek && Attention.peek.screen === screenName && !Overlays.isTaskbarAway(screenName) ? Attention.peek : null
    readonly property var samples: [
        ["Vesktop", "dev.vencord.Vesktop", "#general", "mira: the new build is up, can someone check the burst on a right taskbar?"],
        ["Telegram Desktop", "org.telegram.desktop", "Jonas", "Dinner at eight? I booked the place by the river."],
        ["ZapZap", "com.rtosta.zapzap", "Family", "<b>Mum</b>: photos from the weekend &amp; the garden"],
        ["Thunderbird", "org.mozilla.thunderbird", "Invoice 2026-11", "Your invoice for November is ready to download."],
        ["NetworkManager", "", "Connected", "You are now connected to the Wi-Fi network \"home\"."]
    ]

    signal shotSaved(string path)

    function holdKeyboard() {
        if (!FrameDebug.isActive || frameHud.activeFocus)
            return
        focusBeforeFrames = activeFocusItem
        frameHud.forceActiveFocus()
    }

    function returnKeyboard() {
        if (focusBeforeFrames && focusBeforeFrames.visible)
            focusBeforeFrames.forceActiveFocus()
        else
            contentItem.forceActiveFocus()
        focusBeforeFrames = null
    }

    function isOverlayOpen(key: string): bool {
        return Overlays.isOpen(key, screenName) && !Overlays.isWaiting(key, screenName)
    }

    function landOverlay() {
        Overlays.settleSwap(screenName)
        Overlays.returnTaskbar(screenName)
    }

    function postSample(urgency) {
        const sample = samples[sampleIndex % samples.length]
        sampleIndex++
        return Notifications.post(sample[0], sample[1], sample[2], sample[3], urgency)
    }

    function pressShortcut(name: string) {
        if (name === "frames")
            FrameDebug.toggle(screenName)
        else if (name === "frameShot")
            FrameDebug.snap(screenName)
    }

    width: 1600
    height: 900
    visible: true
    title: "VAD/OS Shell playground"
    color: "#2b3542"


    Item {
        id: scene
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#3b4a5c" }
                GradientStop { position: 1; color: "#1d242e" }
            }
        }

        Repeater {
            model: [
                { x: 380, y: 110, width: 720, height: 440, color: "#e6e6e6" },
                { x: 820, y: 300, width: 520, height: 380, color: "#c9d3e0" },
                { x: 240, y: 520, width: 480, height: 300, color: "#3a3f48" }
            ]

            Rectangle {
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                radius: 10
                color: modelData.color
            }
        }

        Taskbar {
            id: taskbar
            x: root.isRight ? root.width - width : 0
            width: Appearance.taskbar.windowWidth
            height: scene.height
            isMirrored: root.isRight
            barStyle: Config.data.taskbar.style
            isCompact: Config.data.taskbar.compact
            onCompactRequested: isCompact => Config.setTaskbarCompact(isCompact)
            onSettingsRequested: Overlays.toggle("settings", root.screenName)
            onDashboardRequested: Overlays.toggle("dashboard", root.screenName)
            isAway: Overlays.isTaskbarAway(root.screenName)
            visitor: Overlays.visitorOn(root.screenName)
            activityMode: ActivityState.modeOn(root.screenName)
            activityLead: ActivityState.leadKey
            onActivityModeRequested: mode => ActivityState.set(root.screenName, mode)
            onActivityLeadRequested: direction => ActivityState.rotate(direction)
            isAlerting: root.peek !== null
            alertSize: alerts.bodySize
            isClipboardOpen: ActivityState.isClipboardOn(root.screenName)
            clipboardSize: clipboard.bodySize
            onClipboardCloseRequested: ActivityState.closeClipboard()
        }

        Alerts {
            id: alerts
            x: taskbar.x
            width: taskbar.width
            height: taskbar.height
            isMirrored: root.isRight
            peek: root.peek
            body: taskbar.alertRect
            isBodyShown: taskbar.isAlertShown
            onDismissRequested: Attention.dismissPeek()
            onOpenRequested: notification => {
                Notifications.open(notification)
                Attention.dismissPeek()
            }
        }

        ClipboardHistory {
            id: clipboard
            x: taskbar.x
            width: taskbar.width
            height: taskbar.height
            isMirrored: root.isRight
            entries: Clipboard.entries
            body: taskbar.clipboardRect
            isBodyShown: taskbar.isClipboardShown
            isBumpHovered: taskbar.isClipboardBumpHovered
            onPickRequested: entry => {
                Clipboard.pick(entry)
                ActivityState.closeClipboard()
            }
            onPinRequested: entry => Clipboard.togglePin(entry)
            onRemoveRequested: entry => Clipboard.remove(entry)
            onClearRequested: Clipboard.clear()
            onCloseRequested: ActivityState.closeClipboard()
        }

        Search {
            id: search
            anchors.fill: parent
            visible: isPresent
            isOpen: root.isOverlayOpen("search")
            favoriteIds: Config.data.search.favorites
            parts: Overlays.taskbarParts[root.screenName] ?? []
            isMirrored: root.isRight
            canHandOff: Config.data.taskbar.style !== "bare"
            isHandingOver: Overlays.isHandingOver("search", root.screenName)
            hasCircle: Overlays.hasCircle("search", root.screenName)
            onPhaseChanged: Overlays.reportPhase("search", root.screenName, phase)
            onVisitorChanged: Overlays.placeVisitor("search", root.screenName, visitor)
            onCloseRequested: Overlays.close("search")
            onLanded: root.landOverlay()
            onFavoriteToggled: appId => Config.toggleFavorite(appId)
        }

        Settings {
            id: settings
            anchors.fill: parent
            visible: isPresent
            isOpen: root.isOverlayOpen("settings")
            parts: Overlays.taskbarParts[root.screenName] ?? []
            isMirrored: root.isRight
            canHandOff: Config.data.taskbar.style !== "bare"
            isHandingOver: Overlays.isHandingOver("settings", root.screenName)
            hasCircle: Overlays.hasCircle("settings", root.screenName)
            onPhaseChanged: Overlays.reportPhase("settings", root.screenName, phase)
            onVisitorChanged: Overlays.placeVisitor("settings", root.screenName, visitor)
            accent: Appearance.color.accent
            taskbarSide: Config.data.taskbar.side
            barStyle: Config.data.taskbar.style
            windowMode: Config.data.desktop.mode
            canSwitchMode: true
            onCloseRequested: Overlays.close("settings")
            onLanded: root.landOverlay()
            onAccentRequested: value => Config.setAccent(value.toString())
            onSideRequested: side => Config.setTaskbarSide(side)
            onStyleRequested: style => Config.setTaskbarStyle(style)
            onModeRequested: mode => Config.setWindowMode(mode)
            isReducedMotion: Config.data.motion.reduced
            isQuiet: Config.data.attention.doNotDisturb
            onReducedMotionRequested: isReduced => Config.setReducedMotion(isReduced)
            onQuietRequested: isQuiet => Config.setDoNotDisturb(isQuiet)
            profileName: Config.data.profile.name
            profileSecondName: Config.data.profile.secondName
            profilePicture: Config.data.profile.picture
            profileGithub: Config.data.profile.github
            pillOpacity: Config.data.pills.opacity
            pillBlur: Config.data.pills.blur
            pillColor: Config.data.pills.color
            isMediaPlayerOn: Config.data.services.mediaPlayer
            isNotificationsOn: Config.data.notifications.enabled
            lockLayout: Config.data.lock.layout
            lockWallpaper: Config.data.lock.wallpaper
            onLockLayoutRequested: entries => Config.setLockLayout(entries)
            onLockWallpaperRequested: value => Config.setLockWallpaper(value)
            onProfileRequested: (field, value) => ({
                name: Config.setProfileName,
                secondName: Config.setProfileSecondName,
                picture: Config.setProfilePicture,
                github: Config.setProfileGithub
            })[field](value)
            onPillRequested: (field, value) => ({
                opacity: Config.setPillOpacity,
                blur: Config.setPillBlur,
                color: Config.setPillColor
            })[field](value)
            onMediaPlayerRequested: isOn => Config.setMediaPlayer(isOn)
            onNotificationsRequested: isOn => Config.setNotificationsEnabled(isOn)
        }

        Dashboard {
            id: dashboard
            anchors.fill: parent
            visible: isPresent
            isOpen: root.isOverlayOpen("dashboard")
            isMirrored: root.isRight
            parts: Overlays.taskbarParts[root.screenName] ?? []
            canHandOff: Config.data.taskbar.style !== "bare"
            isHandingOver: Overlays.isHandingOver("dashboard", root.screenName)
            hasCircle: Overlays.hasCircle("dashboard", root.screenName)
            onPhaseChanged: Overlays.reportPhase("dashboard", root.screenName, phase)
            onVisitorChanged: Overlays.placeVisitor("dashboard", root.screenName, visitor)
            onCloseRequested: Overlays.close("dashboard")
            onLanded: root.landOverlay()
        }

        NotificationMenu {
            id: notificationMenu
            anchors.fill: parent
            visible: isPresent
            isOpen: root.isOverlayOpen("notifications")
            parts: Overlays.taskbarParts[root.screenName] ?? []
            isMirrored: root.isRight
            canHandOff: Config.data.taskbar.style !== "bare"
            isHandingOver: Overlays.isHandingOver("notifications", root.screenName)
            hasCircle: Overlays.hasCircle("notifications", root.screenName)
            isQuiet: Attention.isQuiet
            onPhaseChanged: Overlays.reportPhase("notifications", root.screenName, phase)
            onVisitorChanged: Overlays.placeVisitor("notifications", root.screenName, visitor)
            onCloseRequested: Overlays.close("notifications")
            onLanded: root.landOverlay()
            onQuietRequested: isQuiet => Attention.setQuiet(isQuiet)
        }
    }

    Connections {
        target: Overlays

        function onTaskbarGathering(screenName) {
            if (screenName !== root.screenName)
                return
            Overlays.placeTaskbarParts(root.screenName, taskbar.liquidParts())
        }
    }

    FrameTap {
        target: scene
        screenName: root.screenName
        isLive: true
    }

    FrameHud {
        id: frameHud
        anchors.fill: parent
        isActive: FrameDebug.isActive
        isReplay: FrameDebug.isViewingPast
        replayShots: FrameDebug.shotsOn(root.screenName)
        counter: FrameDebug.counter
        label: FrameDebug.shownLabel
        onStepRequested: FrameDebug.step()
        onBackRequested: FrameDebug.back()
        onShotRequested: FrameDebug.snap(root.screenName)
        onCloseRequested: FrameDebug.close()
        onIsActiveChanged: {
            if (isActive)
                root.holdKeyboard()
            else
                root.returnKeyboard()
        }
    }

    onActiveFocusItemChanged: if (FrameDebug.isActive && !frameHud.activeFocus) Qt.callLater(holdKeyboard)

    Connections {
        target: FrameDebug

        function onSnapshotReady(shots) {
            frameHud.snapshotShots = shots
            const isStarted = frameHud.capture(result => {
                const path = Core.StandardPaths.writableLocation(Core.StandardPaths.TempLocation) + "/vados-frame.png"
                result.saveToFile(path)
                root.shotSaved(path)
                FrameDebug.finishSnap()
            })
            if (!isStarted)
                FrameDebug.finishSnap()
        }
    }

    Shortcut {
        sequence: "0"
        context: Qt.ApplicationShortcut
        onActivated: root.pressShortcut("frames")
    }

    Shortcut {
        sequence: "+"
        context: Qt.ApplicationShortcut
        onActivated: root.pressShortcut("frameShot")
    }

    Shortcut {
        sequence: "Ctrl+Right"
        context: Qt.ApplicationShortcut
        onActivated: ActivityState.step(root.screenName, 1)
    }

    Shortcut {
        sequence: "Ctrl+Left"
        context: Qt.ApplicationShortcut
        onActivated: ActivityState.step(root.screenName, -1)
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        onActivated: ActivityState.rotate(1)
    }

    Shortcut {
        sequence: "V"
        enabled: !Overlays.isOpen("search", root.screenName)
        context: Qt.ApplicationShortcut
        onActivated: ActivityState.toggleClipboard(root.screenName)
    }

    Shortcut {
        sequence: "C"
        enabled: !Overlays.isOpen("search", root.screenName)
        context: Qt.ApplicationShortcut
        onActivated: Activities.isCalling = !Activities.isCalling
    }

    Shortcut {
        sequence: "N"
        enabled: !Overlays.isOpen("search", root.screenName)
        context: Qt.ApplicationShortcut
        onActivated: root.postSample(1)
    }

    Shortcut {
        sequence: "Shift+N"
        enabled: !Overlays.isOpen("search", root.screenName)
        context: Qt.ApplicationShortcut
        onActivated: root.postSample(2)
    }

    Shortcut {
        sequence: "M"
        enabled: !Overlays.isOpen("search", root.screenName)
        context: Qt.ApplicationShortcut
        onActivated: Activities.hasMedia = !Activities.hasMedia
    }

    Shortcut {
        sequences: ["Ctrl+D"]
        context: Qt.ApplicationShortcut
        onActivated: Overlays.toggle("dashboard", root.screenName)
    }

    Shortcut {
        sequence: "D"
        enabled: !Overlays.isAnyOpen()
        context: Qt.ApplicationShortcut
        onActivated: Overlays.toggle("dashboard", root.screenName)
    }

    Shortcut {
        sequences: ["Ctrl+N", "Meta+N"]
        context: Qt.ApplicationShortcut
        onActivated: Overlays.toggle("notifications", root.screenName)
    }

    Shortcut {
        sequences: ["Ctrl+P"]
        context: Qt.ApplicationShortcut
        onActivated: Overlays.toggle("settings", root.screenName)
    }

    Shortcut {
        sequences: ["Ctrl+G", "Alt+G", "Ctrl+Space", "F1"]
        context: Qt.ApplicationShortcut
        onActivated: Overlays.toggle("search", root.screenName)
    }

    Shortcut {
        sequence: "G"
        enabled: Overlays.screenOf("search") === "" && Overlays.screenOf("settings") === ""
        context: Qt.ApplicationShortcut
        onActivated: Overlays.toggle("search", root.screenName)
    }
}
