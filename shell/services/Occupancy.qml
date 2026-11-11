pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    id: occupancy

    function isCovered(screenName, isHolding) {
        const window = Compositor.activeWindow ?? (isHolding ? Compositor.lastWindow : null)
        if (!window || window.screen !== screenName)
            return false
        if (window.isFullscreen)
            return true
        const screen = Quickshell.screens.find(candidate => candidate.name === screenName)
        const screenWidth = screen?.width ?? Number.MAX_VALUE
        const screenHeight = screen?.height ?? Number.MAX_VALUE
        const isNearEdge = Config.data.taskbar.side === "right"
            ? window.x + window.width > screenWidth - Appearance.taskbar.reach && window.x < screenWidth
            : window.x < Appearance.taskbar.reach && window.x + window.width > 0
        return isNearEdge && window.y < screenHeight && window.y + window.height > 0
    }
}
