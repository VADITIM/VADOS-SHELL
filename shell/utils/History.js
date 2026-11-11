.pragma library

function entryOf(notification, time, icon) {
    return {
        key: notification.id + ":" + time,
        id: notification.id,
        appName: notification.appName ?? "",
        desktopEntry: notification.desktopEntry ?? "",
        summary: notification.summary ?? "",
        body: notification.body ?? "",
        urgency: notification.urgency ?? 1,
        icon: icon ?? "",
        time: time
    }
}

function isKept(notification) {
    return !(notification.transient ?? false)
}

function record(entries, entry, limit) {
    const others = (entries || []).filter(candidate => candidate.key !== entry.key)
    return limit > 0 ? [entry].concat(others).slice(0, limit) : []
}

function trim(entries, limit) {
    return limit > 0 ? (entries || []).slice(0, limit) : []
}

function forget(entries, key) {
    return (entries || []).filter(candidate => candidate.key !== key)
}

function isStorableIcon(icon) {
    return typeof icon === "string" && (icon.startsWith("/") || icon.startsWith("file://"))
}
