import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.services
import qs.modules.dashboard

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isOpen: Visibilities.dashboardScreen === screenName

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    visible: dashboard.isPresent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vados-dashboard"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    Binding {
        target: Hardware
        property: "isActive"
        value: true
        when: window.isOpen
        restoreMode: Binding.RestoreValue
    }

    Binding {
        target: Traffic
        property: "isActive"
        value: true
        when: window.isOpen
        restoreMode: Binding.RestoreValue
    }

    Binding {
        target: Weather
        property: "isActive"
        value: true
        when: window.isOpen
        restoreMode: Binding.RestoreValue
    }

    Dashboard {
        id: dashboard
        anchors.fill: parent
        isOpen: window.isOpen
        isMirrored: Config.data.taskbar.side === "right"
        parts: Visibilities.taskbarParts[window.screenName] ?? []
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: Visibilities.placeVisitor(window.screenName, visitor)
        onCloseRequested: Visibilities.closeDashboard()
        onLanded: Visibilities.returnTaskbar(window.screenName)
    }
}
