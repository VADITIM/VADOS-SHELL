import QtQuick
import qs.config
import qs.services
import qs.state
import qs.modules.notifications

OverlayWindow {
    id: window

    overlayKey: "notifications"
    isPresent: menu.isPresent
    phase: menu.phase

    NotificationMenu {
        id: menu
        anchors.fill: parent
        isOpen: window.isOpen
        parts: window.parts
        shouldStream: window.shouldStream
        isMirrored: Config.data.taskbar.side === "right"
        canHandOff: window.canHandOff
        isHandingOver: window.isHandingOver
        hasCircle: window.hasCircle
        isQuiet: Attention.isQuiet
        onVisitorChanged: window.placeVisitor(visitor)
        onIsCarryingChanged: window.carry(isCarrying)
        onCloseRequested: window.requestClose()
        onLanded: window.land()
        onQuietRequested: isQuiet => Attention.setQuiet(isQuiet)
        onAppRequested: Config.setSendApp(Transfer.nextApp())
    }
}
