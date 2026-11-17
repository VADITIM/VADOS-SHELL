import QtQuick
import qs.services

QtObject {
    id: arrangement

    readonly property var groups: Toplevels.groups
    property string carriedAppId: ""
    property int pillCounter: 0
    property var detachedTasks: ({})
    property ListModel mainTasks: ListModel {}
    property ListModel detachedPills: ListModel {}
    readonly property Component taskListComponent: Component {
        ListModel {}
    }

    onGroupsChanged: synchronise()
    Component.onCompleted: synchronise()

    function modelFor(pillKey) {
        return pillKey === "main" ? mainTasks : detachedTasks[pillKey] ?? null
    }

    function pillKeys() {
        const keys = ["main"]
        for (let position = 0; position < detachedPills.count; position++)
            keys.push(detachedPills.get(position).pillKey)
        return keys
    }

    function groupFor(appId) {
        return groups.find(group => group.appId === appId) ?? null
    }

    function places(appId) {
        const found = []
        for (const pillKey of pillKeys()) {
            const model = modelFor(pillKey)
            for (let position = 0; position < model.count; position++) {
                const entry = model.get(position)
                if (entry.appId === appId)
                    found.push({ pillKey: pillKey, index: position, isLeaving: entry.isLeaving, isGhost: entry.isGhost })
            }
        }
        return found
    }

    function livingPlace(appId) {
        return places(appId).find(place => !place.isLeaving) ?? null
    }

    function synchronise() {
        const present = new Set(groups.map(group => group.appId))
        for (const pillKey of pillKeys()) {
            const model = modelFor(pillKey)
            for (let position = 0; position < model.count; position++) {
                const entry = model.get(position)
                if (!present.has(entry.appId) && !entry.isLeaving)
                    model.setProperty(position, "isLeaving", true)
            }
        }
        for (const group of groups) {
            if (group.appId === carriedAppId || livingPlace(group.appId))
                continue
            mainTasks.append({ appId: group.appId, isLeaving: false, isGhost: false })
        }
    }

    function discard(pillKey, appId) {
        const model = modelFor(pillKey)
        if (!model)
            return
        for (let position = 0; position < model.count; position++) {
            const entry = model.get(position)
            if (entry.appId === appId && entry.isLeaving) {
                model.remove(position)
                return
            }
        }
    }

    function markGhost(appId) {
        const place = livingPlace(appId)
        if (place)
            modelFor(place.pillKey).setProperty(place.index, "isGhost", true)
        return place
    }

    function placeGhost(appId, pillKey, index) {
        const target = modelFor(pillKey)
        if (!target)
            return
        let isPlaced = false
        for (const place of places(appId)) {
            const model = modelFor(place.pillKey)
            if (place.pillKey === pillKey && !isPlaced) {
                isPlaced = true
                if (place.isLeaving)
                    model.setProperty(place.index, "isLeaving", false)
                const wanted = Math.max(0, Math.min(index, model.count - 1))
                if (wanted !== place.index)
                    model.move(place.index, wanted, 1)
            } else if (!place.isLeaving) {
                model.setProperty(place.index, "isLeaving", true)
            }
        }
        if (!isPlaced)
            target.insert(Math.max(0, Math.min(index, target.count)), { appId: appId, isLeaving: false, isGhost: true })
    }

    function vacate(appId) {
        for (const place of places(appId)) {
            if (!place.isLeaving)
                modelFor(place.pillKey).setProperty(place.index, "isLeaving", true)
        }
    }

    function settleGhost(appId) {
        const place = livingPlace(appId)
        if (place)
            modelFor(place.pillKey).setProperty(place.index, "isGhost", false)
    }

    function createPill(index) {
        pillCounter += 1
        const pillKey = "pill-" + pillCounter
        const tasks = detachedTasks
        tasks[pillKey] = taskListComponent.createObject(arrangement)
        detachedTasks = tasks
        detachedPills.insert(Math.max(0, Math.min(index, detachedPills.count)), { pillKey: pillKey })
        return pillKey
    }

    function removePill(pillKey) {
        const model = modelFor(pillKey)
        if (!model || pillKey === "main")
            return
        for (let position = 0; position < model.count; position++) {
            if (!model.get(position).isLeaving)
                return
        }
        for (let position = 0; position < detachedPills.count; position++) {
            if (detachedPills.get(position).pillKey === pillKey) {
                detachedPills.remove(position)
                break
            }
        }
        const tasks = detachedTasks
        delete tasks[pillKey]
        detachedTasks = tasks
        model.destroy()
    }
}
