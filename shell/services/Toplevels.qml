pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: toplevels

    readonly property var groups: {
        const byApp = {}
        const order = []
        for (const toplevel of ToplevelManager.toplevels.values) {
            const appId = toplevel.appId || toplevel.title || "unknown"
            if (!byApp[appId]) {
                byApp[appId] = { appId: appId, windows: [] }
                order.push(appId)
            }
            byApp[appId].windows.push(toplevel)
        }
        return order.map(appId => byApp[appId])
    }

    function entryFor(appId) {
        return typeof DesktopEntries.heuristicLookup === "function"
            ? DesktopEntries.heuristicLookup(appId)
            : DesktopEntries.byId(appId)
    }

    function iconFor(appId) {
        return Quickshell.iconPath(entryFor(appId)?.icon || appId.toLowerCase(), "application-x-executable")
    }

    function findIcon(appId) {
        return Quickshell.iconPath(entryFor(appId)?.icon || appId.toLowerCase(), true)
    }

    function activate(group) {
        const windows = group.windows
        const current = windows.findIndex(window => window.activated)
        const target = Confinement.isConfined && current >= 0 ? windows[current] : windows[(current + 1) % windows.length]
        if (Confinement.isConfined)
            Confinement.activate(target)
        else
            target.activate()
    }

    function close(group) {
        const windows = group.windows
        const target = windows.find(window => window.activated) ?? windows[windows.length - 1]
        target.close()
    }
}
