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
        canHandOff: window.canHandOff
        isHandingOver: window.isHandingOver
        hasCircle: window.hasCircle
        onVisitorChanged: window.placeVisitor(visitor)
        onIsCarryingChanged: window.carry(isCarrying)
        onCloseRequested: window.requestClose()
        onLanded: window.land()
    }
}
