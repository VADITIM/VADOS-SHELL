pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Fuzzy.js" as Fuzzy

Singleton {
    id: apps

    readonly property string cacheDirectory: Quickshell.env("HOME") + "/.cache/vados"
    readonly property var usage: adapter.usage || {}
    readonly property var all: {
        const list = []
        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay)
                continue
            list.push({
                id: entry.id,
                name: entry.name || entry.id,
                genericName: entry.genericName || "",
                comment: entry.comment || "",
                keywords: (entry.keywords || []).join(" "),
                icon: Quickshell.iconPath(entry.icon, "application-x-executable"),
                entry: entry
            })
        }
        list.sort((first, second) => first.name.localeCompare(second.name))
        return list
    }

    function search(query) {
        return Fuzzy.rank(all, query, usage, Date.now())
    }

    function recent() {
        return Fuzzy.recent(all, usage)
    }

    function byId(appId) {
        return all.find(app => app.id === appId) ?? null
    }

    function launch(appId) {
        const app = byId(appId)
        if (!app)
            return
        app.entry.execute()
        const next = Object.assign({}, usage)
        next[appId] = { count: (next[appId]?.count ?? 0) + 1, last: Date.now() }
        adapter.usage = next
        file.writeAdapter()
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", cacheDirectory])

    FileView {
        id: file
        path: apps.cacheDirectory + "/apps.json"
        printErrors: false

        JsonAdapter {
            id: adapter
            property var usage: ({})
        }
    }
}
