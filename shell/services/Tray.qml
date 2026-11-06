pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    readonly property var items: SystemTray.items.values

    function open(item, window, x, y) {
        if (item.onlyMenu && item.hasMenu)
            item.display(window, x, y)
        else
            item.activate()
    }

    function openMenu(item, window, x, y) {
        if (item.hasMenu)
            item.display(window, x, y)
        else
            item.secondaryActivate()
    }
}
