.pragma library

const apps = [
    { key: "calculator", id: "vados-calculator", name: "Calculator", genericName: "VAD/OS calculator", comment: "Arithmetic in its own window", keywords: "math arithmetic sum rechner", icon: "calculator.svg" }
]

function byKey(key) {
    return apps.find(app => app.key === key) ?? null
}

function byId(appId) {
    return apps.find(app => app.id === appId) ?? null
}

function opened(list, key) {
    if (!byKey(key) || (list || []).indexOf(key) >= 0)
        return list || []
    return (list || []).concat([key])
}

function closed(list, key) {
    return (list || []).filter(open => open !== key)
}

function toggled(list, key) {
    return (list || []).indexOf(key) >= 0 ? closed(list, key) : opened(list, key)
}
