import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.services
import qs.modules.settings

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isOpen: Visibilities.settingsScreen === screenName

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    visible: settings.isPresent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vados-settings"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    Settings {
        id: settings
        anchors.fill: parent
        isOpen: window.isOpen
        origin: Visibilities.settingsOrigins[window.screenName] ?? Qt.rect(0, 0, 0, 0)
        parts: Visibilities.taskbarParts[window.screenName] ?? []
        accent: Appearance.color.accent
        taskbarSide: Config.data.taskbar.side
        barStyle: Config.data.taskbar.style
        windowMode: Config.data.desktop.mode
        canSwitchMode: Confinement.canConfine
        onCloseRequested: Visibilities.closeSettings()
        onLanded: Visibilities.returnTaskbar(window.screenName)
        onAccentRequested: value => Config.setAccent(value.toString())
        onSideRequested: side => Config.setTaskbarSide(side)
        onStyleRequested: style => Config.setTaskbarStyle(style)
        onModeRequested: mode => Config.setWindowMode(mode)
    }
}
