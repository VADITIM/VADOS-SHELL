import os
import shutil
import sys

PYSIDE = r"C:\Users\vn\dependencies\pyside6"
PREVIEW = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(PREVIEW))
SHELL = os.path.join(PROJECT, "shell")
BUILD = os.path.join(os.environ.get("TEMP", PREVIEW), "vados-playground-build")

CONFIG_MOCK = """pragma Singleton
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
        property QtObject appearance: QtObject { property string accent: "#ffffff" }
        property QtObject desktop: QtObject { property string mode: "canvas" }
        property QtObject search: QtObject { property var favorites: ["firefox.desktop", "kitty.desktop"] }
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
        }
    }
    function setTaskbarStyle(style) { data.taskbar.style = style }
    function setTaskbarSide(side) { data.taskbar.side = side }
    function setTaskbarCompact(isCompact) { data.taskbar.compact = isCompact }
    function setTaskbarGather(gather) { data.taskbar.gather = gather }
    function setAccent(color) { data.appearance.accent = color }
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
    function toggleFavorite(appId) {
        const favorites = data.search.favorites.slice()
        const at = favorites.indexOf(appId)
        if (at >= 0)
            favorites.splice(at, 1)
        else
            favorites.push(appId)
        data.search.favorites = favorites
    }
}
"""


def write_module(name, files):
    target = os.path.join(BUILD, *name.split("."))
    os.makedirs(target, exist_ok=True)
    lines = ["module " + name]
    for path, text in files:
        base = os.path.basename(path)
        if text is None:
            with open(path, encoding="utf-8") as handle:
                text = handle.read()
        with open(os.path.join(target, base), "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
        prefix = "singleton " if "pragma Singleton" in text else ""
        lines.append(f"{prefix}{base[:-4]} 1.0 {base}")
    with open(os.path.join(target, "qmldir"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


def qml_files(folder):
    return [(os.path.join(folder, name), None) for name in sorted(os.listdir(folder)) if name.endswith(".qml")]


def mock_services():
    entries = []
    with open(os.path.join(PREVIEW, "mocks", "Services.txt"), encoding="utf-8") as handle:
        name, body = None, []
        for line in handle.read().splitlines():
            head, separator, rest = line.partition("|")
            if separator and head.isidentifier() and not line.startswith(" "):
                if name:
                    entries.append((name + ".qml", "\n".join(body) + "\n"))
                name, body = head, [rest]
            else:
                body.append(line)
        entries.append((name + ".qml", "\n".join(body) + "\n"))
    for name in ("Apps.qml", "Toplevels.qml"):
        with open(os.path.join(PREVIEW, "mocks", name), encoding="utf-8") as handle:
            entries.append((name, handle.read()))
    return entries


def build():
    shutil.rmtree(BUILD, ignore_errors=True)
    write_module("Quickshell", [("Singleton.qml", "import QtQml\nQtObject {\n    default property list<QtObject> data\n}\n")])
    tokens = [(os.path.join(SHELL, "config", name), None) for name in ("Appearance.qml", "Motion.qml", "Rendering.qml", "Release.qml")]
    write_module("qs.config", tokens + [("Config.qml", CONFIG_MOCK)])
    write_module("qs.components", qml_files(os.path.join(SHELL, "components")))
    write_module("qs.state", qml_files(os.path.join(SHELL, "state")))
    for module in ("taskbar", "alerts", "clipboard", "search", "settings", "dashboard", "notifications", "framedebug", "screenshot"):
        write_module("qs.modules." + module, qml_files(os.path.join(SHELL, "modules", module)))
    write_module("qs.services", mock_services())
    write_module("qs.windows", [(os.path.join(SHELL, "windows", "FrameTap.qml"), None)])
    utilities = os.path.join(BUILD, "qs", "utils")
    os.makedirs(utilities, exist_ok=True)
    for name in os.listdir(os.path.join(SHELL, "utils")):
        if name.endswith(".js"):
            shutil.copy(os.path.join(SHELL, "utils", name), os.path.join(utilities, name))


GLOBAL_KEYS = {"Key_0": "frames", "Key_Plus": "frameShot"}


def open_window(application):
    from PySide6.QtCore import QEvent, QMetaObject, QObject, Qt, QUrl, Q_ARG
    from PySide6.QtGui import QImage
    from PySide6.QtQml import QQmlApplicationEngine

    keys = {getattr(Qt.Key, name): shortcut for name, shortcut in GLOBAL_KEYS.items()}

    class GlobalShortcuts(QObject):
        def __init__(self, window):
            super().__init__(window)
            self.window = window

        def eventFilter(self, watched, event):
            if event.type() not in (QEvent.Type.KeyPress, QEvent.Type.ShortcutOverride):
                return False
            if not event.modifiers() & Qt.KeyboardModifier.KeypadModifier or event.key() not in keys:
                return False
            if event.type() == QEvent.Type.KeyPress and not event.isAutoRepeat():
                QMetaObject.invokeMethod(self.window, "pressShortcut", Q_ARG(str, keys[event.key()]))
            return True

    engine = QQmlApplicationEngine()
    engine.addImportPath(BUILD)
    engine.load(QUrl.fromLocalFile(os.path.join(PREVIEW, "play.qml")))
    if not engine.rootObjects():
        return engine, None
    window = engine.rootObjects()[0]
    window.installEventFilter(GlobalShortcuts(window))

    def copy(address):
        path = QUrl(address).toLocalFile() or address
        image = QImage(path)
        if image.isNull():
            print("vados: frames: the screenshot could not be read from " + path)
            return
        application.clipboard().setImage(image)
        print("vados: frames: screenshot copied to the clipboard, also saved to " + path)

    window.shotSaved.connect(copy)
    return engine, window


def run_window():
    sys.path.insert(0, PYSIDE)
    from PySide6.QtGui import QGuiApplication

    application = QGuiApplication(sys.argv)
    engine, window = open_window(application)
    if window is None:
        return 1
    return application.exec()


def main():
    build()
    os.environ["QML_IMPORT_PATH"] = BUILD
    os.environ["QSG_RENDER_LOOP"] = "basic"
    print("Running. Ctrl+P settings, G or Ctrl+G search, D or Ctrl+D dashboard, Ctrl+Left/Right activity pill state, Ctrl+Up activity lead, C call, M media, P or Print screenshot, R or Shift+Print recording, Esc closes, 0 or Num 0 holds every animation (Num 0 works everywhere, also in the search field), Up/Right steps a frame, Down/Left goes back, + or Num + copies a screenshot to the clipboard. Close the window to quit.")
    return run_window()


if __name__ == "__main__":
    sys.exit(main())
