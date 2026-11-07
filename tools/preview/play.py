import os
import shutil
import subprocess
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
        }
        property QtObject appearance: QtObject { property string accent: "#ffffff" }
        property QtObject desktop: QtObject { property string mode: "canvas" }
        property QtObject search: QtObject { property var favorites: ["firefox.desktop", "kitty.desktop"] }
        property QtObject weather: QtObject { property string location: "" }
        property QtObject notifications: QtObject { property bool enabled: false }
        property QtObject attention: QtObject { property bool doNotDisturb: false }
        property QtObject motion: QtObject { property bool reduced: false }
        property QtObject rendering: QtObject { property string quality: "full" }
    }
    function setTaskbarStyle(style) { data.taskbar.style = style }
    function setTaskbarSide(side) { data.taskbar.side = side }
    function setTaskbarCompact(isCompact) { data.taskbar.compact = isCompact }
    function setAccent(color) { data.appearance.accent = color }
    function setWindowMode(mode) { data.desktop.mode = mode }
    function setWeatherLocation(location) { data.weather.location = location }
    function setNotificationsEnabled(isEnabled) { data.notifications.enabled = isEnabled }
    function setDoNotDisturb(isQuiet) { data.attention.doNotDisturb = isQuiet }
    function setReducedMotion(isReduced) { data.motion.reduced = isReduced }
    function setRenderQuality(quality) { data.rendering.quality = quality }
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
    tokens = [(os.path.join(SHELL, "config", name), None) for name in ("Appearance.qml", "Motion.qml", "Rendering.qml")]
    write_module("qs.config", tokens + [("Config.qml", CONFIG_MOCK)])
    write_module("qs.components", qml_files(os.path.join(SHELL, "components")))
    write_module("qs.state", qml_files(os.path.join(SHELL, "state")))
    for module in ("taskbar", "search", "settings", "dashboard"):
        write_module("qs.modules." + module, qml_files(os.path.join(SHELL, "modules", module)))
    write_module("qs.services", mock_services())
    utilities = os.path.join(BUILD, "qs", "utils")
    os.makedirs(utilities, exist_ok=True)
    for name in os.listdir(os.path.join(SHELL, "utils")):
        if name.endswith(".js"):
            shutil.copy(os.path.join(SHELL, "utils", name), os.path.join(utilities, name))


def main():
    build()
    environment = dict(os.environ)
    environment["QML_IMPORT_PATH"] = BUILD
    environment["QSG_RENDER_LOOP"] = "basic"
    environment["PYTHONPATH"] = PYSIDE
    print("Running. Ctrl+P settings, G or Ctrl+G search, D or Ctrl+D dashboard, Esc closes. Close the window to quit.")
    command = [sys.executable, "-m", "PySide6.scripts.qml", os.path.join(PREVIEW, "play.qml")] + sys.argv[1:]
    return subprocess.call(command, env=environment)


if __name__ == "__main__":
    sys.exit(main())
