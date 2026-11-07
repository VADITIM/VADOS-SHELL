import QtQuick
import qs.config
import qs.state
import qs.services
import qs.modules.settings

OverlayWindow {
    id: window

    overlayKey: "settings"
    isPresent: settings.isPresent

    Settings {
        id: settings
        anchors.fill: parent
        isOpen: window.isOpen
        origin: Overlays.settingsOrigins[window.screenName] ?? Qt.rect(0, 0, 0, 0)
        parts: window.parts
        accent: Appearance.color.accent
        taskbarSide: Config.data.taskbar.side
        barStyle: Config.data.taskbar.style
        windowMode: Config.data.desktop.mode
        canSwitchMode: Confinement.canConfine
        isReducedMotion: Config.data.motion.reduced
        isQuiet: Config.data.attention.doNotDisturb
        onCloseRequested: window.requestClose()
        onLanded: window.land()
        onAccentRequested: value => Config.setAccent(value.toString())
        onSideRequested: side => Config.setTaskbarSide(side)
        onStyleRequested: style => Config.setTaskbarStyle(style)
        onModeRequested: mode => Config.setWindowMode(mode)
        onReducedMotionRequested: isReduced => Config.setReducedMotion(isReduced)
        onQuietRequested: isQuiet => Config.setDoNotDisturb(isQuiet)
    }
}
