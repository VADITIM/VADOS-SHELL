import QtQuick
import QtQuick.Window
import qs.config
import qs.state
import qs.services
import qs.modules.taskbar
import qs.modules.search
import qs.modules.settings
import qs.modules.dashboard

Window {
    id: root

    readonly property string screenName: "play"
    readonly property bool isRight: Config.data.taskbar.side === "right"

    width: 1600
    height: 900
    visible: true
    title: "VAD/OS Shell playground"
    color: "#2b3542"

    Component.onCompleted: Visibilities.placeSettingsOrigin(screenName, taskbar.settingsOrigin)

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
        height: parent.height
        isMirrored: root.isRight
        barStyle: Config.data.taskbar.style
        isCompact: Config.data.taskbar.compact
        onCompactRequested: isCompact => Config.setTaskbarCompact(isCompact)
        isAway: Visibilities.taskbarAwayScreen === root.screenName
        visitor: Visibilities.visitors[root.screenName] ?? null
        onSettingsRequested: Visibilities.toggleSettings(root.screenName)
        onDashboardRequested: Visibilities.toggleDashboard(root.screenName)
        onSettingsOriginChanged: Visibilities.placeSettingsOrigin(root.screenName, settingsOrigin)
    }

    Connections {
        target: Visibilities

        function onTaskbarGathering(screenName) {
            if (screenName !== root.screenName)
                return
            Visibilities.placeSettingsOrigin(root.screenName, taskbar.settingsOrigin)
            Visibilities.placeTaskbarParts(root.screenName, taskbar.liquidParts())
        }
    }

    Search {
        id: search
        anchors.fill: parent
        visible: isPresent
        isOpen: Visibilities.searchScreen === root.screenName
        favoriteIds: Config.data.search.favorites
        parts: Visibilities.taskbarParts[root.screenName] ?? []
        isMirrored: root.isRight
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: Visibilities.placeVisitor(root.screenName, visitor)
        onCloseRequested: Visibilities.closeSearch()
        onLanded: Visibilities.returnTaskbar(root.screenName)
        onFavoriteToggled: appId => Config.toggleFavorite(appId)
    }

    Settings {
        id: settings
        anchors.fill: parent
        visible: isPresent
        isOpen: Visibilities.settingsScreen === root.screenName
        origin: Visibilities.settingsOrigins[root.screenName] ?? Qt.rect(0, 0, 0, 0)
        parts: Visibilities.taskbarParts[root.screenName] ?? []
        accent: Appearance.color.accent
        taskbarSide: Config.data.taskbar.side
        barStyle: Config.data.taskbar.style
        windowMode: Config.data.desktop.mode
        canSwitchMode: true
        onCloseRequested: Visibilities.closeSettings()
        onLanded: Visibilities.returnTaskbar(root.screenName)
        onAccentRequested: value => Config.setAccent(value.toString())
        onSideRequested: side => Config.setTaskbarSide(side)
        onStyleRequested: style => Config.setTaskbarStyle(style)
        onModeRequested: mode => Config.setWindowMode(mode)
    }

    Dashboard {
        id: dashboard
        anchors.fill: parent
        visible: isPresent
        isOpen: Visibilities.dashboardScreen === root.screenName
        isMirrored: root.isRight
        parts: Visibilities.taskbarParts[root.screenName] ?? []
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: Visibilities.placeVisitor(root.screenName, visitor)
        onCloseRequested: Visibilities.closeDashboard()
        onLanded: Visibilities.returnTaskbar(root.screenName)
    }

    Shortcut {
        sequences: ["Ctrl+D"]
        context: Qt.ApplicationShortcut
        onActivated: Visibilities.toggleDashboard(root.screenName)
    }

    Shortcut {
        sequence: "D"
        enabled: Visibilities.searchScreen === "" && Visibilities.settingsScreen === "" && Visibilities.dashboardScreen === ""
        context: Qt.ApplicationShortcut
        onActivated: Visibilities.toggleDashboard(root.screenName)
    }

    Shortcut {
        sequences: ["Ctrl+P"]
        context: Qt.ApplicationShortcut
        onActivated: Visibilities.toggleSettings(root.screenName)
    }

    Shortcut {
        sequences: ["Ctrl+G", "Alt+G", "Ctrl+Space", "F1"]
        context: Qt.ApplicationShortcut
        onActivated: Visibilities.toggleSearch(root.screenName)
    }

    Shortcut {
        sequence: "G"
        enabled: Visibilities.searchScreen === "" && Visibilities.settingsScreen === ""
        context: Qt.ApplicationShortcut
        onActivated: Visibilities.toggleSearch(root.screenName)
    }
}
