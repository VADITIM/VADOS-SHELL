.pragma library

const apps = [
    { key: "files", label: "FILES", role: "FILE MANAGER", entry: "vados-files", repository: "VADITIM/VADOS-Files", mimes: ["inode/directory"] },
    { key: "gallery", label: "GALLERY", role: "IMAGES AND VIDEO", entry: "vados-gallery", repository: "VADITIM/VADOS-GALLERY", mimes: ["image/jpeg", "image/png", "image/webp", "image/gif", "image/bmp", "image/tiff", "image/avif", "video/mp4", "video/x-matroska", "video/webm"] },
    { key: "notes", label: "NOTES", role: "NOTES AND TEXT", entry: "vados-notes", repository: "VADITIM/VADOS-NOTES", mimes: ["text/markdown", "text/plain"] },
    { key: "terminal", label: "TERMINAL", role: "TERMINAL", entry: "vados-terminal", repository: "VADITIM/VADOS-TERMINAL", mimes: [] }
]

const queryScript = 'for mime in "$@"; do printf "%s=%s\\n" "$mime" "$(xdg-mime query default "$mime")"; done'

function byKey(key) {
    return apps.find(app => app.key === key) ?? null
}

function desktopFile(app) {
    return app.entry + ".desktop"
}

function releasesLink(app) {
    return "https://github.com/" + app.repository + "/releases"
}

function defaultCommand(app) {
    return app.mimes.length > 0 ? ["xdg-mime", "default", desktopFile(app)].concat(app.mimes) : []
}

function queryCommand() {
    const leads = apps.filter(app => app.mimes.length > 0).map(app => app.mimes[0])
    return ["sh", "-c", queryScript, "sh"].concat(leads)
}

function parseDefaults(text) {
    const defaults = {}
    for (const line of text.split("\n")) {
        const cut = line.indexOf("=")
        if (cut > 0)
            defaults[line.slice(0, cut)] = line.slice(cut + 1).trim()
    }
    return defaults
}

function isInstalled(app, entryIds) {
    return entryIds.indexOf(app.entry) >= 0 || entryIds.indexOf(desktopFile(app)) >= 0
}

function resolve(entryIds, defaults) {
    return apps.map(app => {
        const isHere = isInstalled(app, entryIds)
        const canBeDefault = isHere && app.mimes.length > 0
        return {
            key: app.key,
            label: app.label,
            role: app.role,
            isInstalled: isHere,
            canBeDefault: canBeDefault,
            isDefault: canBeDefault && defaults[app.mimes[0]] === desktopFile(app)
        }
    })
}

function statusOf(row) {
    return !row.isInstalled ? "NOT INSTALLED" : row.isDefault ? "DEFAULT APP" : "INSTALLED"
}
