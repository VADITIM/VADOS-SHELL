import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.services
import qs.modules.taskbar
import qs.modules.extension
import qs.modules.alerts
import qs.modules.clipboard

PanelWindow {
    id: window

    readonly property bool isRight: Config.data.taskbar.side === "right"
    readonly property string screenName: screen?.name ?? ""
    property string extensionKey: ""
    readonly property var peek: Attention.peek && Attention.peek.screen === screenName && !Overlays.isTaskbarAway(screenName) ? Attention.peek : null
    readonly property bool isFullscreenHere: Compositor.activeWindow?.isFullscreen === true && Compositor.activeWindow.screen === screenName
    readonly property bool isClipboardOpen: ActivityState.isClipboardOn(screenName)
    readonly property rect clipboardZone: {
        const body = taskbar.clipboardRect
        const left = window.isRight ? (screen?.width ?? window.width) - body.x - body.width : body.x
        return Qt.rect(left, body.y, body.width, body.height)
    }
    readonly property bool isRaisedOverFullscreen: isFullscreenHere && (peek !== null || taskbar.isAlertShown || isClipboardOpen)

    anchors {
        left: !window.isRight
        right: window.isRight
        top: true
        bottom: true
    }
    implicitWidth: Appearance.taskbar.windowWidth
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: window.isRaisedOverFullscreen ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "vados-taskbar"
    WlrLayershell.keyboardFocus: extension.isTyping ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onClipboardZoneChanged: ActivityState.placeClipboard(window.screenName, clipboardZone)
    mask: Region {
        item: inputZone

        Region {
            item: extensionZone
        }
    }

    FrameTap {
        target: window.contentItem
        screenName: window.screenName
        isLive: window.visible
        side: window.isRight ? "right" : "left"
    }

    Item {
        id: inputZone
        x: window.isRight ? window.width - width : 0
        width: taskbar.inputWidth
        height: window.height
    }

    Item {
        id: extensionZone
        x: window.isRight ? window.width - width : 0
        y: extension.inputTop
        width: extension.inputWidth
        height: extension.inputHeight
    }

    Connections {
        target: Overlays

        function onTaskbarGathering(screenName) {
            if (screenName !== window.screenName)
                return
            Overlays.placeTaskbarParts(window.screenName, taskbar.liquidParts())
            Overlays.placeTaskbarOrigins(window.screenName, taskbar.originPoints())
        }
    }

    Taskbar {
        id: taskbar
        onActivityPlaceChanged: ActivityState.place(window.screenName, activityPlace)
        Component.onCompleted: ActivityState.place(window.screenName, activityPlace)
        anchors.fill: parent
        hostWindow: window
        isMirrored: window.isRight
        barStyle: Config.data.taskbar.style
        isCompact: Config.data.taskbar.compact
        onCompactRequested: isCompact => Config.setTaskbarCompact(isCompact)
        onSettingsRequested: Overlays.toggle("settings", window.screenName)
        onDashboardRequested: Overlays.toggle("dashboard", window.screenName)
        isAway: Overlays.isTaskbarAway(window.screenName)
        isGathering: Overlays.isGathering(window.screenName)
        isMerging: Config.data.taskbar.gather === "merge"
        visitor: Overlays.visitorOn(window.screenName)
        activityMode: ActivityState.modeOn(window.screenName)
        activityLead: ActivityState.leadKey
        onActivityModeRequested: mode => ActivityState.set(window.screenName, mode)
        onActivityLeadRequested: direction => ActivityState.rotate(direction)
        isAlerting: window.peek !== null
        alertSize: alerts.bodySize
        isClipboardOpen: window.isClipboardOpen
        clipboardSize: clipboard.bodySize
        onClipboardCloseRequested: ActivityState.closeClipboard()
        isCovered: Occupancy.isCovered(window.screenName, Overlays.isHolding(window.screenName))
        isEngaged: extension.isOpen || extension.isHeld || window.isClipboardOpen || alerts.isExpanded
        extensionKey: window.extensionKey
        onExtensionRequested: key => window.extensionKey = key
        onIsAwayChanged: {
            if (isAway)
                window.extensionKey = ""
        }
    }

    Alerts {
        id: alerts
        anchors.fill: parent
        isMirrored: window.isRight
        peek: window.peek
        body: taskbar.alertRect
        isBodyShown: taskbar.isAlertShown
        onDismissRequested: Attention.dismissPeek()
        onHoldRequested: isOn => Attention.holdPeek(isOn)
        onOpenRequested: notification => {
            if (notification.isNotice !== true)
                Notifications.open(notification)
            Attention.dismissPeek()
        }
    }

    ClipboardHistory {
        id: clipboard
        anchors.fill: parent
        isMirrored: window.isRight
        entries: Clipboard.entries
        body: taskbar.clipboardRect
        isBodyShown: taskbar.isClipboardShown
        onPickRequested: entry => {
            Clipboard.pick(entry)
            ActivityState.closeClipboard()
        }
        onPinRequested: entry => Clipboard.togglePin(entry)
        onRemoveRequested: entry => Clipboard.remove(entry)
        onClearRequested: Clipboard.clear()
        onCloseRequested: ActivityState.closeClipboard()
    }

    Extension {
        id: extension
        anchors.fill: parent
        isMirrored: window.isRight
        extensionKey: window.extensionKey
        body: taskbar.extensionRect
        lift: taskbar.extensionLift
        isBatteryProtected: Config.data.battery.limit
        onCloseRequested: window.extensionKey = ""
        onBatteryProtectRequested: isProtected => Config.setBatteryLimit(isProtected)
    }
}
