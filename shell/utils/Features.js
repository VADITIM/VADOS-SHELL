.pragma library

const surfaces = ["bar", "mutation", "overlay", "lock", "desktop", "window", "debug"]
const origins = ["edge", "column", "activity", "idle", "power", "none"]
const impacts = ["ambient", "glance", "focus", "takeover"]

const features = [
    { key: "taskbar", folder: "taskbar", root: "Taskbar", surface: "bar", origin: "edge", impact: "ambient", needs: [], isBuilt: true },
    { key: "activity", folder: "taskbar", root: "ActivityPill", surface: "mutation", origin: "activity", impact: "glance", needs: [], isBuilt: true },
    { key: "extension", folder: "extension", root: "Extension", surface: "mutation", origin: "idle", impact: "focus", needs: [], isBuilt: true },
    { key: "search", folder: "search", root: "Search", surface: "overlay", origin: "column", impact: "focus", needs: [], isBuilt: true, layer: 1, keepsTaskbar: false },
    { key: "dashboard", folder: "dashboard", root: "Dashboard", surface: "overlay", origin: "column", impact: "focus", needs: [], isBuilt: true, layer: 1, keepsTaskbar: false },
    { key: "settings", folder: "settings", root: "Settings", surface: "overlay", origin: "column", impact: "takeover", needs: [], isBuilt: true, layer: 1, keepsTaskbar: false },
    { key: "framedebug", folder: "framedebug", root: "FrameHud", surface: "debug", origin: "none", impact: "ambient", needs: [], isBuilt: true },
    { key: "alerts", folder: "alerts", root: "Alerts", surface: "mutation", origin: "activity", impact: "glance", needs: [], isBuilt: true },
    { key: "prompt", folder: "prompt", root: "Prompt", surface: "mutation", origin: "activity", impact: "focus", needs: [], isBuilt: true },
    { key: "clipboard", folder: "clipboard", root: "ClipboardHistory", surface: "mutation", origin: "activity", impact: "focus", needs: [], isBuilt: true },
    { key: "notifications", folder: "notifications", root: "NotificationMenu", surface: "overlay", origin: "column", impact: "focus", needs: [], isBuilt: true, layer: 1, keepsTaskbar: false },
    { key: "screenshot", folder: "screenshot", root: "Screenshot", surface: "overlay", origin: "activity", impact: "focus", needs: [], isBuilt: true, layer: 2, keepsTaskbar: true },
    { key: "lock", folder: "lock", root: "LockScreen", surface: "lock", origin: "power", impact: "takeover", needs: ["sessionLock"], isBuilt: true },
    { key: "wallpaper", folder: "wallpaper", root: "Wallpaper", surface: "desktop", origin: "none", impact: "ambient", needs: [], isBuilt: true },
    { key: "widgets", folder: "widgets", root: "WidgetLayer", surface: "desktop", origin: "none", impact: "ambient", needs: [], isBuilt: true },
    { key: "calculator", folder: "calculator", root: "Calculator", surface: "window", origin: "none", impact: "focus", needs: [], isBuilt: true },
    { key: "canvas", folder: "canvas", root: "Minimap", surface: "bar", origin: "edge", impact: "ambient", needs: ["freeCanvas"], isBuilt: false }
]

function overlayKinds() {
    const kinds = {}
    for (const feature of features) {
        if (feature.isBuilt && feature.surface === "overlay")
            kinds[feature.key] = { layer: feature.layer, keepsTaskbar: feature.keepsTaskbar }
    }
    return kinds
}
