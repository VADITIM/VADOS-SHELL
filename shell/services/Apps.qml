pragma Singleton
import QtQuick
import Quickshell
import qs.config
import "../utils/Fuzzy.js" as Fuzzy

Singleton {
    id: apps

    readonly property var usage: store.values.usage || {}
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
                entry: entry,
                builtin: ""
            })
        }
        for (const app of Builtins.apps) {
            list.push({
                id: app.id,
                name: app.name,
                genericName: app.genericName,
                comment: app.comment,
                keywords: app.keywords,
                icon: Qt.resolvedUrl("../assets/" + app.icon),
                entry: null,
                builtin: app.key
            })
        }
        list.sort((first, second) => first.name.localeCompare(second.name))
        return list
    }

    readonly property var seen: store.values.seen
    readonly property var fresh: store.isLoaded ? Fuzzy.fresh(all, seen, usage, apps.now, Appearance.search.newWindow) : []
    property real now: Date.now()

    function noteSeen() {
        if (!store.isLoaded || all.length === 0)
            return
        const next = Fuzzy.noteSeen(all, seen, Date.now())
        if (next !== seen)
            store.update(Object.assign({}, store.values, { seen: next }))
    }

    onAllChanged: noteSeen()

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
        if (app.builtin.length > 0)
            Builtins.open(app.builtin)
        else
            app.entry.execute()
        const next = Object.assign({}, usage)
        next[appId] = { count: (next[appId]?.count ?? 0) + 1, last: Date.now() }
        store.update(Object.assign({}, store.values, { usage: next }))
    }

    StateFile {
        id: store
        name: "apps"
        defaults: ({ usage: {} })
        onIsLoadedChanged: apps.noteSeen()
    }
}
