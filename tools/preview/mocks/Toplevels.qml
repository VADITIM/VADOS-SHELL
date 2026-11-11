pragma Singleton
import QtQuick

QtObject {
    id: toplevels

    property var windows: []
    readonly property var groups: {
        const byApp = {}
        const order = []
        for (const window of windows) {
            if (!byApp[window.appId]) {
                byApp[window.appId] = { appId: window.appId, windows: [] }
                order.push(window.appId)
            }
            byApp[window.appId].windows.push(window)
        }
        return order.map(appId => byApp[appId])
    }
    property Component windowComponent: Component {
        QtObject {
            property string appId
            property string title
            property bool activated: false
            function activate() { toplevels.focus(this) }
            function close() { toplevels.remove(this) }
        }
    }

    function open(appId, title) {
        const window = windowComponent.createObject(toplevels, { appId: appId, title: title })
        windows = windows.concat([window])
        focus(window)
        return window
    }

    function focus(target) {
        for (const window of windows)
            window.activated = window === target
    }

    function remove(target) {
        windows = windows.filter(window => window !== target)
    }

    function iconFor(appId) { return "" }
    function findIcon(appId) { return "" }

    function activate(group) {
        const current = group.windows.findIndex(window => window.activated)
        group.windows[(current + 1) % group.windows.length].activate()
    }

    function close(group) {
        const target = group.windows.find(window => window.activated) ?? group.windows[group.windows.length - 1]
        target.close()
    }

    Component.onCompleted: {
        open("firefox", "VAD/OS — Mozilla Firefox")
        open("kitty", "~/source/vados-shell")
        open("code", "Taskbar.qml — Visual Studio Code")
        open("spotify", "Spotify Premium")
        open("obsidian", "VAD/OS vault")
        focus(windows[1])
    }
}
