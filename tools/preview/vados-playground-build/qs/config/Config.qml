pragma Singleton
import QtQuick
QtObject {
    property QtObject data: QtObject {
        property QtObject taskbar: QtObject {
            property bool enabled: true
            property string style: "floating"
            property string side: "left"
            property bool compact: false
            property string gather: "merge"
        }
        property QtObject appearance: QtObject {
            property string accent: "#ffffff"
            property string choice: "outline"
            property string choiceOutline: ""
            property string choicePill: ""
        }
        property QtObject desktop: QtObject { property string mode: "canvas" }
        property QtObject search: QtObject { property var favorites: ["firefox.desktop", "kitty.desktop"]; property var hidden: [] }
        property QtObject weather: QtObject { property string location: "" }
        property QtObject notifications: QtObject { property bool enabled: false; property int history: 200 }
        property QtObject send: QtObject { property string app: "blip"; property var devices: [] }
        property QtObject clipboard: QtObject { property bool enabled: true; property int size: 150; property bool images: true }
        property QtObject capture: QtObject { property string screenshots: ""; property string recordings: "" }
        property QtObject attention: QtObject { property bool doNotDisturb: false }
        property QtObject motion: QtObject { property bool reduced: false; property string burst: "static" }
        property QtObject rendering: QtObject { property string quality: "full" }
        property QtObject profile: QtObject {
            property string name: ""
            property string secondName: ""
            property string picture: ""
            property string github: ""
        }
        property QtObject pills: QtObject {
            property real opacity: 0.94
            property real blur: 1
            property string color: ""
        }
        property QtObject services: QtObject { property bool mediaPlayer: true }
        property QtObject lock: QtObject {
            property var layout: ["clock:5:1", "profile:6:4", "login:5:8"]
            property string wallpaper: ""
            property int blankAfter: 60
        }
        property QtObject wallpaper: QtObject { property string path: ""; property string folder: "" }
        property QtObject widgets: QtObject { property var layout: [] }
    }
    function setTaskbarStyle(style) { data.taskbar.style = style }
    function setTaskbarSide(side) { data.taskbar.side = side }
    function setTaskbarCompact(isCompact) { data.taskbar.compact = isCompact }
    function setTaskbarGather(gather) { data.taskbar.gather = gather }
    function setAccent(color) { data.appearance.accent = color }
    function setChoiceStyle(style) { data.appearance.choice = style }
    function setChoiceOutline(color) { data.appearance.choiceOutline = color }
    function setChoicePill(color) { data.appearance.choicePill = color }
    function setWallpaper(path) { data.wallpaper.path = path }
    function setWallpaperFolder(folder) { data.wallpaper.folder = folder }
    function setWidgetsLayout(entries) { data.widgets.layout = entries }
    function setWindowMode(mode) { data.desktop.mode = mode }
    function setWeatherLocation(location) { data.weather.location = location }
    function setScreenshotFolder(folder) { data.capture.screenshots = folder }
    function setRecordingFolder(folder) { data.capture.recordings = folder }
    function setNotificationsEnabled(isEnabled) { data.notifications.enabled = isEnabled }
    function setNotificationHistory(count) { data.notifications.history = count }
    function setSendApp(key) { data.send.app = key }
    function setSendDevices(entries) { data.send.devices = entries }
    function setDoNotDisturb(isQuiet) { data.attention.doNotDisturb = isQuiet }
    function setReducedMotion(isReduced) { data.motion.reduced = isReduced }
    function setBurstStyle(style) { data.motion.burst = style }
    function setRenderQuality(quality) { data.rendering.quality = quality }
    function setProfileName(value) { data.profile.name = value }
    function setProfileSecondName(value) { data.profile.secondName = value }
    function setProfilePicture(value) { data.profile.picture = value }
    function setProfileGithub(value) { data.profile.github = value }
    function setPillOpacity(value) { data.pills.opacity = value }
    function setPillBlur(value) { data.pills.blur = value }
    function setPillColor(value) { data.pills.color = value }
    function setMediaPlayer(isOn) { data.services.mediaPlayer = isOn }
    function setLockLayout(entries) { data.lock.layout = entries }
    function setLockWallpaper(value) { data.lock.wallpaper = value }
    function setLockBlankAfter(seconds) { data.lock.blankAfter = seconds }
    function toggleFavorite(appId) {
        const favorites = data.search.favorites.slice()
        const at = favorites.indexOf(appId)
        if (at >= 0)
            favorites.splice(at, 1)
        else
            favorites.push(appId)
        data.search.favorites = favorites
    }
    function toggleHidden(appId) {
        const hidden = data.search.hidden.slice()
        const at = hidden.indexOf(appId)
        if (at >= 0)
            hidden.splice(at, 1)
        else
            hidden.push(appId)
        data.search.hidden = hidden
    }
}
