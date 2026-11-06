pragma Singleton
import QtQuick
import "../utils/Fuzzy.js" as Fuzzy

QtObject {
    id: apps
    property var usage: ({
        "firefox.desktop": { count: 40, last: Date.now() - 600000 },
        "kitty.desktop": { count: 90, last: Date.now() - 60000 },
        "code.desktop": { count: 25, last: Date.now() - 3600000 },
        "spotify.desktop": { count: 6, last: Date.now() - 86400000 },
        "discord.desktop": { count: 12, last: Date.now() - 7200000 }
    })
    property string lastLaunched: ""
    readonly property var all: {
        const names = [["Firefox","Web Browser"],["Kitty","Terminal"],["Visual Studio Code","Code Editor"],["Spotify","Music Player"],["Discord","Chat"],["Files","File Manager"],["Blender","3D Creation"],["GIMP","Image Editor"],["Inkscape","Vector Graphics"],["Krita","Painting"],["Obsidian","Notes"],["Steam","Games"],["Thunderbird","Mail Client"],["VLC","Media Player"],["OBS Studio","Streaming"],["LibreOffice Writer","Word Processor"],["LibreOffice Calc","Spreadsheet"],["Signal","Messenger"],["Fire Dragon","Web Browser"],["Firewall Config","Network"],["Pavucontrol","Volume Control"],["Btop","System Monitor"],["Calculator","Utility"],["Godot","Game Engine"],["Zed","Code Editor"],["Neovim","Text Editor"]]
        const list = names.map(pair => ({ id: pair[0].toLowerCase().split(" ")[0] + (pair[0] === "Visual Studio Code" ? "" : "") + ".desktop", name: pair[0], genericName: pair[1], comment: "", keywords: "", icon: "" }))
        list[2].id = "code.desktop"
        list.sort((a, b) => a.name.localeCompare(b.name))
        return list
    }
    function search(query) { return Fuzzy.rank(all, query, usage, Date.now()) }
    function recent() { return Fuzzy.recent(all, usage) }
    function byId(appId) { return all.find(app => app.id === appId) ?? null }
    function launch(appId) {
        lastLaunched = appId
        const next = Object.assign({}, usage)
        next[appId] = { count: (next[appId]?.count ?? 0) + 1, last: Date.now() }
        usage = next
        console.log("launch", appId)
    }
}
