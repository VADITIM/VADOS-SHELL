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

    Component.onCompleted: Overlays.placeSettingsOrigin(screenName, taskbar.settingsOrigin)

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
        onSettingsRequested: Overlays.toggle("settings", root.screenName)
        onDashboardRequested: Overlays.toggle("dashboard", root.screenName)
        isAway: Overlays.isTaskbarAway(root.screenName)
        visitor: Overlays.visitorOn(root.screenName)
        activityMode: ActivityState.modeOn(root.screenName)
        activityLead: ActivityState.leadKey
        onActivityModeRequested: mode => ActivityState.set(root.screenName, mode)
        onActivityLeadRequested: direction => ActivityState.rotate(direction)
        onSettingsOriginChanged: Overlays.placeSettingsOrigin(root.screenName, settingsOrigin)
    }

    Connections {
        target: Overlays

        function onTaskbarGathering(screenName) {
            if (screenName !== root.screenName)
                return
            Overlays.placeSettingsOrigin(root.screenName, taskbar.settingsOrigin)
            Overlays.placeTaskbarParts(root.screenName, taskbar.liquidParts())
        }
    }

    Search {
        id: search
        anchors.fill: parent
        visible: isPresent
        isOpen: Overlays.isOpen("search", root.screenName)
        favoriteIds: Config.data.search.favorites
        parts: Overlays.taskbarParts[root.screenName] ?? []
        isMirrored: root.isRight
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: Overlays.placeVisitor("search", root.screenName, visitor)
        onCloseRequested: Overlays.close("search")
        onLanded: Overlays.returnTaskbar(root.screenName)
        onFavoriteToggled: appId => Config.toggleFavorite(appId)
    }

    Settings {
        id: settings
        anchors.fill: parent
        visible: isPresent
        isOpen: Overlays.isOpen("settings", root.screenName)
        origin: Overlays.settingsOrigins[root.screenName] ?? Qt.rect(0, 0, 0, 0)
        parts: Overlays.taskbarParts[root.screenName] ?? []
        accent: Appearance.color.accent
        taskbarSide: Config.data.taskbar.side
        barStyle: Config.data.taskbar.style
        windowMode: Config.data.desktop.mode
        canSwitchMode: true
        onCloseRequested: Overlays.close("settings")
        onLanded: Overlays.returnTaskbar(root.screenName)
        onAccentRequested: value => Config.setAccent(value.toString())
        onSideRequested: side => Config.setTaskbarSide(side)
        onStyleRequested: style => Config.setTaskbarStyle(style)
        onModeRequested: mode => Config.setWindowMode(mode)
        isReducedMotion: Config.data.motion.reduced
        isQuiet: Config.data.attention.doNotDisturb
        onReducedMotionRequested: isReduced => Config.setReducedMotion(isReduced)
        onQuietRequested: isQuiet => Config.setDoNotDisturb(isQuiet)
    }

    Dashboard {
        id: dashboard
        anchors.fill: parent
        visible: isPresent
        isOpen: Overlays.isOpen("dashboard", root.screenName)
        isMirrored: root.isRight
        parts: Overlays.taskbarParts[root.screenName] ?? []
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: Overlays.placeVisitor("dashboard", root.screenName, visitor)
        onCloseRequested: Overlays.close("dashboard")
        onLanded: Overlays.returnTaskbar(root.screenName)
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
        sequence: "C"
        enabled: !Overlays.isOpen("search", root.screenName)
        context: Qt.ApplicationShortcut
        onActivated: Activities.isCalling = !Activities.isCalling
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
