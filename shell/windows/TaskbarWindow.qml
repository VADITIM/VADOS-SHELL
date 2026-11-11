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
    property rect extensionOrigin: Qt.rect(0, 0, 0, 0)
    readonly property var peek: Attention.peek && Attention.peek.screen === screenName && !Overlays.isTaskbarAway(screenName) ? Attention.peek : null
    readonly property bool isFullscreenHere: Compositor.activeWindow?.isFullscreen === true && Compositor.activeWindow.screen === screenName
    readonly property bool isClipboardOpen: ActivityState.isClipboardOn(screenName)
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
    color: "transparent"
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
        width: extension.inputWidth
        height: window.height
    }

    Connections {
        target: Overlays

        function onTaskbarGathering(screenName) {
            if (screenName !== window.screenName)
                return
            Overlays.placeTaskbarParts(window.screenName, taskbar.liquidParts())
        }
    }

    Taskbar {
        id: taskbar
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
        isEaten: extension.isHolding
        onExtensionRequested: (key, origin) => {
            window.extensionOrigin = origin
            window.extensionKey = key
        }
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
        onOpenRequested: notification => {
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

    Extension {
        id: extension
        anchors.fill: parent
        isMirrored: window.isRight
        inset: taskbar.inset
        extensionKey: window.extensionKey
        origin: window.extensionOrigin
        onCloseRequested: window.extensionKey = ""
    }
}
