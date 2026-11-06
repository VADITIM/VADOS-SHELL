pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property var data: adapter

    function setTaskbarStyle(style) {
        adapter.taskbar.style = style
        file.writeAdapter()
    }

    function setTaskbarSide(side) {
        adapter.taskbar.side = side
        file.writeAdapter()
    }

    function setTaskbarCompact(isCompact) {
        adapter.taskbar.compact = isCompact
        file.writeAdapter()
    }

    function setAccent(color) {
        adapter.appearance.accent = color
        pendingWrite.restart()
    }

    function setWindowMode(mode) {
        adapter.desktop.mode = mode
        file.writeAdapter()
    }

    function setWeatherLocation(location) {
        adapter.weather.location = location
        file.writeAdapter()
    }

    function setNotificationsEnabled(isEnabled) {
        adapter.notifications.enabled = isEnabled
        file.writeAdapter()
    }

    function setProfile(name, picture) {
        adapter.profile.name = name
        adapter.profile.picture = picture
        file.writeAdapter()
    }

    function toggleFavorite(appId) {
        const favorites = (adapter.search.favorites || []).slice()
        const at = favorites.indexOf(appId)
        if (at >= 0)
            favorites.splice(at, 1)
        else
            favorites.push(appId)
        adapter.search.favorites = favorites
        file.writeAdapter()
    }

    Timer {
        id: pendingWrite
        interval: Motion.settings.write
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/vados/shell.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property JsonObject taskbar: JsonObject {
                property bool enabled: true
                property string style: "floating"
                property string side: "left"
                property bool compact: false
            }
            property JsonObject appearance: JsonObject {
                property string accent: "#ffffff"
            }
            property JsonObject desktop: JsonObject {
                property string mode: "canvas"
            }
            property JsonObject search: JsonObject {
                property var favorites: []
            }
            property JsonObject profile: JsonObject {
                property string name: ""
                property string picture: ""
            }
            property JsonObject weather: JsonObject {
                property string location: ""
            }
            property JsonObject notifications: JsonObject {
                property bool enabled: false
            }
        }
    }
}
