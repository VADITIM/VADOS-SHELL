pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Schema.js" as Schema
import "../utils/Log.js" as Log

Singleton {
    id: root

    readonly property var data: adapter
    readonly property var reportedProblems: ({})

    function report(message) {
        if (reportedProblems[message])
            return
        reportedProblems[message] = true
        Log.warn("config", message + " (" + file.path + ")")
    }

    function readSetting(key) {
        const parts = Schema.splitKey(key)
        return adapter[parts.group][parts.name]
    }

    function accept(key, value) {
        const problem = Schema.findProblem(key, value)
        if (problem)
            report(`refused ${key}: it ${problem}; keeping ${JSON.stringify(readSetting(key))}`)
        return !problem
    }

    function applySettings(settings) {
        for (const key in Schema.settings) {
            const parts = Schema.splitKey(key)
            const value = settings[parts.group][parts.name]
            if (JSON.stringify(readSetting(key)) !== JSON.stringify(value))
                adapter[parts.group][parts.name] = value
        }
    }

    function repairLoaded() {
        let raw
        try {
            raw = JSON.parse(file.text())
        } catch (error) {
            report(`the file is not valid JSON (${error.message}); fix it, the shell keeps its current settings until then`)
            return
        }
        const repaired = Schema.repair(raw)
        repaired.problems.forEach(problem => report(problem))
        applySettings(repaired.settings)
        if (!repaired.shouldWrite)
            return
        adapter.version = Schema.version
        file.writeAdapter()
    }

    function setTaskbarStyle(style) {
        if (!accept("taskbar.style", style))
            return
        adapter.taskbar.style = style
        file.writeAdapter()
    }

    function setTaskbarSide(side) {
        if (!accept("taskbar.side", side))
            return
        adapter.taskbar.side = side
        file.writeAdapter()
    }

    function setTaskbarCompact(isCompact) {
        if (!accept("taskbar.compact", isCompact))
            return
        adapter.taskbar.compact = isCompact
        file.writeAdapter()
    }

    function setAccent(color) {
        if (!accept("appearance.accent", color))
            return
        adapter.appearance.accent = color
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setWindowMode(mode) {
        if (!accept("desktop.mode", mode))
            return
        adapter.desktop.mode = mode
        file.writeAdapter()
    }

    function setWeatherLocation(location) {
        if (!accept("weather.location", location))
            return
        adapter.weather.location = location
        file.writeAdapter()
    }

    function setReducedMotion(isReduced) {
        if (!accept("motion.reduced", isReduced))
            return
        adapter.motion.reduced = isReduced
        file.writeAdapter()
    }

    function setRenderQuality(quality) {
        if (!accept("rendering.quality", quality))
            return
        adapter.rendering.quality = quality
        file.writeAdapter()
    }

    function setDoNotDisturb(isQuiet) {
        if (!accept("attention.doNotDisturb", isQuiet))
            return
        adapter.attention.doNotDisturb = isQuiet
        file.writeAdapter()
    }

    function setNotificationsEnabled(isEnabled) {
        if (!accept("notifications.enabled", isEnabled))
            return
        adapter.notifications.enabled = isEnabled
        file.writeAdapter()
    }

    function setProfileName(value) {
        if (!accept("profile.name", value))
            return
        adapter.profile.name = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setProfileSecondName(value) {
        if (!accept("profile.secondName", value))
            return
        adapter.profile.secondName = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setProfilePicture(value) {
        if (!accept("profile.picture", value))
            return
        adapter.profile.picture = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setProfileGithub(value) {
        if (!accept("profile.github", value))
            return
        adapter.profile.github = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setPillOpacity(value) {
        if (!accept("pills.opacity", value))
            return
        adapter.pills.opacity = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setPillBlur(value) {
        if (!accept("pills.blur", value))
            return
        adapter.pills.blur = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setPillColor(value) {
        if (!accept("pills.color", value))
            return
        adapter.pills.color = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function setMediaPlayer(value) {
        if (!accept("services.mediaPlayer", value))
            return
        adapter.services.mediaPlayer = value
        file.writeAdapter()
    }

    function setLockLayout(entries) {
        if (!accept("lock.layout", entries))
            return
        adapter.lock.layout = entries
        file.writeAdapter()
    }

    function setLockWallpaper(value) {
        if (!accept("lock.wallpaper", value))
            return
        adapter.lock.wallpaper = value
        pendingWrite.interval = Motion.settings.write
        pendingWrite.restart()
    }

    function toggleFavorite(appId) {
        const favorites = (adapter.search.favorites || []).slice()
        const at = favorites.indexOf(appId)
        if (at >= 0)
            favorites.splice(at, 1)
        else
            favorites.push(appId)
        if (!accept("search.favorites", favorites))
            return
        adapter.search.favorites = favorites
        file.writeAdapter()
    }

    Timer {
        id: pendingWrite
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/vados/shell.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: Qt.callLater(root.repairLoaded)

        JsonAdapter {
            id: adapter
            property int version: Schema.version
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
                property string secondName: ""
                property string github: ""
            }
            property JsonObject pills: JsonObject {
                property real opacity: 0.94
                property real blur: 1
                property string color: ""
            }
            property JsonObject services: JsonObject {
                property bool mediaPlayer: true
            }
            property JsonObject lock: JsonObject {
                property var layout: ["clock:5:1", "profile:6:4", "login:5:8"]
                property string wallpaper: ""
            }
            property JsonObject weather: JsonObject {
                property string location: ""
            }
            property JsonObject notifications: JsonObject {
                property bool enabled: false
            }
            property JsonObject motion: JsonObject {
                property bool reduced: false
            }
            property JsonObject attention: JsonObject {
                property bool doNotDisturb: false
            }
            property JsonObject rendering: JsonObject {
                property string quality: "full"
            }
        }
    }
}
