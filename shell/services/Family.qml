pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Family.js" as Catalogue
import "../utils/Log.js" as Log

Singleton {
    id: family

    property bool isWatching: false
    property var defaults: ({})
    readonly property var entryIds: DesktopEntries.applications.values.map(entry => entry.id)
    readonly property var rows: Catalogue.resolve(entryIds, defaults).map(row => Object.assign(row, { icon: iconOf(row) }))

    function iconOf(row) {
        if (!row.isInstalled)
            return ""
        const app = Catalogue.byKey(row.key)
        const found = Apps.byId(app.entry) ?? Apps.byId(Catalogue.desktopFile(app))
        return found ? found.icon : ""
    }

    function refresh() {
        query.running = true
    }

    function makeDefault(key) {
        const app = Catalogue.byKey(key)
        const command = app ? Catalogue.defaultCommand(app) : []
        if (command.length === 0 || setter.running)
            return
        setter.appLabel = app.label
        setter.command = command
        setter.running = true
    }

    function openReleases(key) {
        const app = Catalogue.byKey(key)
        if (app)
            Quickshell.execDetached(["xdg-open", Catalogue.releasesLink(app)])
    }

    onIsWatchingChanged: {
        if (isWatching)
            refresh()
    }

    Process {
        id: query
        command: Catalogue.queryCommand()
        stdout: StdioCollector {
            onStreamFinished: family.defaults = Catalogue.parseDefaults(text)
        }
    }

    Process {
        id: setter

        property string appLabel: ""

        onExited: code => {
            if (code !== 0)
                Log.warn("family", `xdg-mime exited with code ${code} for ${appLabel}; its defaults are unchanged`)
            family.refresh()
        }
    }
}
