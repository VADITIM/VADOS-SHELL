import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.services
import qs.modules.taskbar
import qs.modules.extension

PanelWindow {
    id: window

    readonly property bool isRight: Config.data.taskbar.side === "right"
    readonly property string screenName: screen?.name ?? ""
    property string extensionKey: ""
    property rect extensionOrigin: Qt.rect(0, 0, 0, 0)

    anchors {
        left: !window.isRight
        right: window.isRight
        top: true
        bottom: true
    }
    implicitWidth: Appearance.taskbar.windowWidth
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "vados-taskbar"
    color: "transparent"
    Component.onCompleted: Visibilities.placeSettingsOrigin(screenName, taskbar.settingsOrigin)
    mask: Region {
        item: inputZone

        Region {
            item: extensionZone
        }
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
        target: Visibilities

        function onTaskbarGathering(screenName) {
            if (screenName !== window.screenName)
                return
            Visibilities.placeSettingsOrigin(window.screenName, taskbar.settingsOrigin)
            Visibilities.placeTaskbarParts(window.screenName, taskbar.liquidParts())
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
        onSettingsRequested: Visibilities.toggleSettings(window.screenName)
        onDashboardRequested: Visibilities.toggleDashboard(window.screenName)
        isAway: Visibilities.taskbarAwayScreen === window.screenName
        visitor: Visibilities.visitors[window.screenName] ?? null
        activityMode: ActivityState.modeOn(window.screenName)
        activityLead: ActivityState.leadKey
        onActivityModeRequested: mode => ActivityState.set(window.screenName, mode)
        onActivityLeadRequested: direction => ActivityState.rotate(direction)
        onSettingsOriginChanged: Visibilities.placeSettingsOrigin(window.screenName, settingsOrigin)
        isCovered: Occupancy.isCovered(window.screen?.name ?? "")
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
