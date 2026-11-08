import QtQuick
import qs.config
import qs.services
import qs.modules.dashboard

OverlayWindow {
    id: window

    overlayKey: "dashboard"
    isPresent: dashboard.isPresent
    phase: dashboard.phase

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
        parts: window.parts
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: window.placeVisitor(visitor)
        onCloseRequested: window.requestClose()
        onLanded: window.land()
    }
}
