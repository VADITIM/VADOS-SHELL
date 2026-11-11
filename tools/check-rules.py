import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import animations
SHELL = os.path.join(ROOT, "shell")

ENGINE_TESTS = {
    "shell/utils/Liquid.js": "tst_liquid.qml",
    "shell/state/Overlays.qml": "tst_overlays.qml",
    "shell/state/Attention.qml": "tst_attention.qml",
    "shell/state/ActivityState.qml": "tst_activity.qml",
    "shell/components/Gesture.qml": "tst_gesture.qml",
    "shell/components/Burst.qml": "tst_burst.qml",
    "shell/services/StateFile.qml": "tst_statefile.qml",
    "shell/services/Confinement.qml": "tst_confinement.qml",
    "shell/utils/Phases.js": "tst_lifecycle.qml",
    "shell/components/Lifecycle.qml": "tst_lifecycle.qml",
    "shell/utils/Geometry.js": "tst_geometry.qml",
    "shell/utils/Platform.js": "tst_platform.qml",
    "shell/utils/Schema.js": "tst_schema.qml",
    "shell/components/LiquidLayer.qml": "tst_rendering.qml",
    "shell/components/Masked.qml": "tst_rendering.qml",
    "shell/config/Rendering.qml": "tst_rendering.qml",
    "shell/utils/Log.js": "tst_log.qml",
    "shell/utils/Backoff.js": "tst_supervisor.qml",
    "shell/services/Supervisor.qml": "tst_supervisor.qml",
    "shell/utils/Diagnostics.js": "tst_diagnostics.qml",
    "shell/utils/Playing.js": "tst_frames.qml",
    "shell/state/FrameDebug.qml": "tst_frames.qml",
    "shell/utils/Features.js": "tst_features.qml",
    "shell/utils/Alerts.js": "tst_alerts.qml",
    "shell/utils/Icons.js": "tst_icons.qml",
    "shell/utils/Tint.js": "tst_tint.qml",
    "shell/utils/Processes.js": "tst_processes.qml",
    "shell/utils/Clipboard.js": "tst_clipboard.qml",
    "shell/components/Gulp.qml": "tst_gulp.qml",
}

FEATURE_REGISTRY = "shell/utils/Features.js"

FEATURE_WINDOWS = {"lock": "LockWindow", "desktop": "WidgetWindow"}

RENDERING_COMPONENTS = {"shell/components/LiquidLayer.qml", "shell/components/Masked.qml"}

TIMERS_NOT_MOTION = {"Motion.reveal.dwell", "edgePull.pace.dwell"}

LAYER_IMPORTS = {
    "config": {"state", "services", "components", "modules", "windows", "keybinds"},
    "state": {"components", "modules", "windows", "keybinds"},
    "services": {"state", "components", "modules", "windows", "keybinds"},
    "components": {"state", "services", "modules", "windows", "keybinds"},
    "modules": {"windows", "keybinds"},
    "windows": {"keybinds"},
    "keybinds": {"components", "modules", "windows"},
}

VISUAL_TYPES = r"Item|Rectangle|Text|TextInput|TextEdit|Image|IconImage|Shape|ShapePath|Canvas|MouseArea|HoverHandler|TapHandler|DragHandler|Column|Row|Grid|Flow|Flickable|ListView|GridView|PathView|Repeater|Loader|ShaderEffect|MultiEffect|\w*Window"

COMPONENT_TOKENS = {
    "Appearance": {"unit", "radius", "color", "font", "liquid", "rising", "burst"},
    "Motion": {"isReduced", "pace", "isHeld", "holdAgain", "stateDuration", "hoverIn", "hoverOut", "press", "pill", "type", "sweep", "gesture", "lifecycle", "burst", "rising", "liquid"},
}

COMPOSITOR_SUPPORT_BACKENDS = ["driftwm", "hyprland", "generic"]


def relative(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def shell_files(extensions=(".qml", ".js")):
    for folder, _, names in os.walk(SHELL):
        for name in sorted(names):
            if name.endswith(extensions):
                path = os.path.join(folder, name)
                with open(path, encoding="utf-8", newline="") as handle:
                    yield relative(path), handle.read()


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def blocks(text, opener):
    for match in re.finditer(r"^\s*" + re.escape(opener) + r"\s*\{", text, re.M):
        depth = 0
        for index in range(match.end() - 1, len(text)):
            if text[index] == "{":
                depth += 1
            elif text[index] == "}":
                depth -= 1
                if depth == 0:
                    yield match.start(), text[match.start():index + 1]
                    break


def readme_section(title):
    with open(os.path.join(ROOT, "README.md"), encoding="utf-8") as handle:
        text = handle.read()
    match = re.search(r"^## " + re.escape(title) + r"\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return match.group(1) if match else ""


def feature_rows(text):
    rows = []
    for key, body in re.findall(r"^\s*\{ key: \"(\w+)\", (.*) \},?$", text, re.M):
        fields = dict(re.findall(r"(\w+): (\"\w+\"|\[[^\]]*\]|\w+)", body))
        rows.append({"key": key, **{name: value.strip('"') for name, value in fields.items()}})
    return rows


def module_folders():
    modules = os.path.join(SHELL, "modules")
    return sorted(name for name in os.listdir(modules) if os.path.isdir(os.path.join(modules, name)))


def check(files):
    found = []

    def flag(rule, path, line, message):
        found.append(f"{path}:{line}: [{rule}] {message}")

    def only_in(rule, pattern, allowed, message, scope=None):
        for path, text in files:
            if path in allowed or (scope and not path.startswith(scope)):
                continue
            for match in re.finditer(pattern, text, re.M):
                flag(rule, path, line_of(text, match.start()), message)

    only_in("compositor", r"^import Quickshell\.Hyprland|hyprctl|\"driftwm\"",
            {"shell/services/Compositor.qml", "shell/keybinds/Shortcuts.qml"},
            "window-manager access goes through services/Compositor.qml (rules/compositor.md)")
    only_in("compositor", r"Compositor\.(isDriftwm|isHyprland|name)\b", {"shell/services/Compositor.qml"},
            "features ask Compositor.capabilities, never which compositor runs (rules/compositor.md)")
    only_in("geometry", r"function (clampUnit|smooth|mix|splineAt|traceSpline)\(|(\w+) \* \2 \* \(3 - 2 \* \2\)|Math\.max\(0, Math\.min\(1,",
            {"shell/utils/Geometry.js"},
            "shared geometry lives in utils/Geometry.js (rules/animations.md)", scope="shell/components/")
    only_in("modules", r"^import Quickshell|\bConfig\.|^import qs\.modules", set(),
            "modules take settings as properties and never import Quickshell, Config or another module (rules/architecture.md)",
            scope="shell/modules/")
    only_in("liquid", r"Math\.exp\(", {"shell/utils/Liquid.js"},
            "liquid physics lives in utils/Liquid.js as a Motion.liquid character (rules/animations.md)")
    only_in("tokens", r"\"#[0-9a-fA-F]{3,8}\"", set(),
            "colours come from Appearance.color (rules/frontend.md)", scope="shell/modules/")
    only_in("tokens", r"\"#[0-9a-fA-F]{3,8}\"", set(),
            "colours come from Appearance.color (rules/frontend.md)", scope="shell/components/")
    only_in("overlays", r"WlrLayershell\.keyboardFocus", {"shell/windows/OverlayWindow.qml", "shell/windows/FrameWindow.qml"},
            "overlays are OverlayWindows registered in state/Overlays.qml (rules/interaction.md)")
    only_in("overlays", r"WlrLayer\.Overlay", {"shell/windows/OverlayWindow.qml", "shell/windows/FrameWindow.qml", "shell/windows/TaskbarWindow.qml"},
            "overlays are OverlayWindows registered in state/Overlays.qml; the taskbar rises only for an alert over a fullscreen window (rules/interaction.md)")
    only_in("lock", r"WlSessionLock", {"shell/windows/LockWindow.qml"},
            "the session lock lives only in windows/LockWindow.qml (rules/security.md)")
    only_in("lock", r"PamContext", {"shell/services/Lock.qml"},
            "authentication lives only in services/Lock.qml (rules/security.md)")
    only_in("state", r"\.cache/|\.setText\(", {"shell/services/StateFile.qml"},
            "runtime state is written through services/StateFile.qml (rules/state.md)")
    only_in("state", r"writeAdapter\(", {"shell/config/Config.qml"},
            "user settings are written only by config/Config.qml (rules/architecture.md)")
    only_in("attention", r"function onReceived\(", {"shell/state/Attention.qml"},
            "only state/Attention.qml decides whether a notification may interrupt (rules/interaction.md)")
    only_in("reliability", r"\bconsole\.\w+\(", {"shell/utils/Log.js"},
            "log through utils/Log.js (Log.info, Log.warn, Log.error), one format with repeats held back (rules/reliability.md)")
    only_in("rendering", r"\bMultiEffect\b|\bShaderEffect(Source)?\b|\blayer\.(enabled|effect)\b|^import QtQuick\.Effects|GraphicalEffects|\b(OpacityMask|GaussianBlur|FastBlur)\b",
            RENDERING_COMPONENTS,
            "effects, layers and masks live in the rendering components (LiquidLayer, Masked); compose them (rules/performance.md)")
    for path in sorted(RENDERING_COMPONENTS):
        text = dict(files).get(path, "")
        for match in re.finditer(r"^\s*(layer\.enabled|live):\s*true\s*$", text, re.M):
            flag("rendering", path, line_of(text, match.start()), "a layer or texture runs only while its surface renders, never always (rules/performance.md)")
    for path, text in files:
        for start, block in blocks(text, "LiquidLayer"):
            depth, top = 0, []
            for character in block:
                depth += character == "{"
                depth -= character == "}"
                if depth == 1 or character in "{}":
                    top.append(character)
            surface = "".join(top)
            if not re.search(r"^\s*isShown:", surface, re.M) or re.search(r"^\s*visible:", surface, re.M):
                flag("rendering", path, line_of(text, start), "a LiquidLayer says when it is shown with isShown, never visible, so it stops rendering when idle (rules/performance.md)")

    for path, text in files:
        if path.startswith(("shell/components/", "shell/modules/")):
            for declaration in animations.declarations(text.split(chr(10))):
                if not declaration["is_held"]:
                    flag("motion", path, declaration["line"] + 1, "an animation takes paused: Motion.isHeld so the frame debugger can hold it (rules/animations.md)")

    for path, text in files:
        if path.startswith("shell/components/") and re.search(r"^\s*id: leave$", text, re.M) and "Lifecycle {" not in text:
            flag("lifecycle", path, 1, "a surface with an enter and a leave runs its phases through a Lifecycle (rules/interaction.md)")

    gesture_types = {"Gesture"} | {
        os.path.basename(path)[:-4] for path, text in files
        if path.endswith(".qml") and re.search(r"^Gesture \{", text, re.M)
    }
    for path, text in files:
        if "\r" in text:
            flag("files", path, 1, "LF line endings only (rules/code-quality.md)")
        if not path.startswith(("shell/components/", "shell/modules/")):
            continue
        if not path.endswith(("TypedText.qml", "Gesture.qml")):
            for match in re.finditer(r"duration:\s*([^\n};]+)", text):
                expression = match.group(1).strip()
                if not expression.startswith("Motion.pace(") and expression not in TIMERS_NOT_MOTION:
                    flag("motion", path, line_of(text, match.start()), "durations go through Motion.pace so reduced motion reaches them (rules/animations.md)")
        if not path.endswith("Gesture.qml"):
            for match in re.finditer(r"onPositionChanged[^\n]*\n((?:[^\n]*\n){0,8})", text):
                if re.search(r"\bpressed\b|mouse\.buttons", match.group(1)):
                    flag("gestures", path, line_of(text, match.start()), "drags go through components/Gesture.qml (rules/interaction.md)")
        for kind in sorted(gesture_types):
            for start, block in blocks(text, kind):
                if re.search(r"^\s*onClicked\s*:", block, re.M):
                    flag("gestures", path, line_of(text, start), f"a {kind} answers taps with onTapped; onClicked also fires after a drag (rules/interaction.md)")

    for path, text in files:
        layer = path.split("/")[1] if path.count("/") > 1 else ""
        for match in re.finditer(r"^import\s+(?:qs\.(\w+)|\"(?:\.\./)+(\w+))", text, re.M):
            target = match.group(1) or match.group(2)
            if target in LAYER_IMPORTS.get(layer, set()):
                flag("layers", path, line_of(text, match.start()), f"{layer} does not import {target}; data flows down, events up, and state is the only sideways channel (rules/architecture.md)")
        if layer == "services":
            for match in re.finditer(r"(?:^\s*|:\s*)(" + VISUAL_TYPES + r")\s*\{|^import (QtQuick\.(?:Shapes|Controls|Layouts|Effects)|Quickshell\.Widgets)\b", text, re.M):
                flag("layers", path, line_of(text, match.start()), f"services own no UI; {match.group(1) or match.group(2)} belongs in a component or module (rules/architecture.md)")
        if layer == "components":
            for match in re.finditer(r"\b(Appearance|Motion)\.(\w+)", text):
                if match.group(2) not in COMPONENT_TOKENS[match.group(1)]:
                    flag("layers", path, line_of(text, match.start()), f"components stay feature-agnostic: {match.group(0)} is a feature group, take it as a property from the module (rules/architecture.md)")

    platform = dict(files).get("shell/utils/Platform.js", "")
    backends = {
        name: dict(re.findall(r"(\w+): (true|false)", body))
        for name, body in re.findall(r"^\s*(\w+): \{(.*?)\},?$", platform, re.M)
    }
    if sorted(backends) != sorted(COMPOSITOR_SUPPORT_BACKENDS):
        flag("compositor", "shell/utils/Platform.js", 1, f"backends {sorted(backends)} differ from the README Compositor support columns {COMPOSITOR_SUPPORT_BACKENDS} (rules/compositor.md)")
    support = {
        name: [cell.strip() for cell in cells.split("|")[:len(COMPOSITOR_SUPPORT_BACKENDS)]]
        for name, cells in re.findall(r"^\| `(\w+)` \|(.*)\|$", readme_section("Compositor support"), re.M)
    }
    for backend in sorted(set(backends) & set(COMPOSITOR_SUPPORT_BACKENDS)):
        column = COMPOSITOR_SUPPORT_BACKENDS.index(backend)
        for capability in sorted(set(backends[backend]) | set(support)):
            claimed = backends[backend].get(capability)
            documented = support[capability][column] if capability in support and column < len(support[capability]) else None
            expected = {"true": "yes", "false": "no"}.get(claimed)
            if expected != documented:
                flag("compositor", "shell/utils/Platform.js", 1, f"`{capability}` on {backend} is {claimed} in utils/Platform.js but {documented} in the README Compositor support table; they say the same (rules/compositor.md)")

    network = readme_section("Network")
    for path, text in files:
        match = re.search(r"XMLHttpRequest|\bcurl\b|\bwget\b|\"ping\"|https?://", text)
        if match and path.replace("shell/", "") not in network and path not in network:
            flag("privacy", path, line_of(text, match.start()), "a file that reaches the network is listed in the README Network section (rules/security.md)")

    mocks_text = open(os.path.join(ROOT, "tools", "preview", "mocks", "Services.txt"), encoding="utf-8").read()
    mocked = set(re.findall(r"^([A-Za-z]+)\|", mocks_text, re.M))
    mocked |= {name[:-4] for name in os.listdir(os.path.join(ROOT, "tools", "preview", "mocks")) if name.endswith(".qml")}
    for path, text in files:
        if path.startswith("shell/services/") and "pragma Singleton" in text:
            name = os.path.basename(path)[:-4]
            if name not in mocked:
                flag("testing", path, 1, f"service {name} has no preview mock in tools/preview/mocks (rules/testing.md)")

    for engine, test in ENGINE_TESTS.items():
        if not os.path.exists(os.path.join(ROOT, engine)):
            flag("testing", engine, 1, "engine listed in tools/check-rules.py no longer exists")
        elif not os.path.exists(os.path.join(ROOT, "tools", "tests", test)):
            flag("testing", engine, 1, f"engine has no test tools/tests/{test} (rules/testing.md)")

    sources = dict(files)
    rows = feature_rows(sources.get(FEATURE_REGISTRY, ""))
    folders = module_folders()
    if not rows:
        flag("features", FEATURE_REGISTRY, 1, "the feature registry has no rows the checker can read; keep one row per line (rules/features.md)")
    for folder in folders:
        owners = [row for row in rows if row.get("folder") == folder]
        if not owners:
            flag("features", f"shell/modules/{folder}", 1, "a module folder belongs to a row in utils/Features.js (rules/features.md)")
        elif any(path.startswith(f"shell/modules/{folder}/") for path in sources) and not any(row.get("isBuilt") == "true" for row in owners):
            flag("features", FEATURE_REGISTRY, 1, f"shell/modules/{folder} holds code but every feature in it is planned; set isBuilt once its surface is wired (rules/features.md)")
    for row in rows:
        key, folder, root, surface = row["key"], row.get("folder"), row.get("root"), row.get("surface")
        if folder not in folders:
            flag("features", FEATURE_REGISTRY, 1, f"`{key}` names shell/modules/{folder}, which does not exist (rules/features.md)")
            continue
        if row.get("isBuilt") != "true":
            continue
        if f"shell/modules/{folder}/{root}.qml" not in sources:
            flag("features", FEATURE_REGISTRY, 1, f"`{key}` is built but its root shell/modules/{folder}/{root}.qml does not exist (rules/features.md)")
        window = f"{root}Window" if surface == "overlay" else FEATURE_WINDOWS.get(surface)
        if window and f"shell/windows/{window}.qml" not in sources:
            flag("features", FEATURE_REGISTRY, 1, f"`{key}` is built as {surface} but shell/windows/{window}.qml does not exist (rules/features.md)")
        if surface == "overlay":
            if f'overlayKey: "{key}"' not in sources.get(f"shell/windows/{window}.qml", ""):
                flag("features", f"shell/windows/{window}.qml", 1, f"the window of `{key}` is an OverlayWindow with overlayKey \"{key}\" (rules/features.md)")
            if not re.search(r"OverlaySlot \{[^{}]*overlayKey: \"" + re.escape(key) + r"\"[^{}]*\b" + re.escape(window) + r" \{", sources.get("shell/shell.qml", "")):
                flag("features", "shell/shell.qml", 1, f"`{key}` is built but shell.qml has no OverlaySlot with overlayKey \"{key}\" holding its {window} per screen; an overlay window exists only while wanted (rules/features.md)")
            if f'target: "{key}"' not in sources.get("shell/keybinds/Shortcuts.qml", ""):
                flag("features", "shell/keybinds/Shortcuts.qml", 1, f"`{key}` is built but has no IPC target \"{key}\" (rules/features.md)")
        if surface == "lock" and "shell/services/Lock.qml" not in sources:
            flag("features", FEATURE_REGISTRY, 1, f"`{key}` is built but shell/services/Lock.qml (authentication) does not exist (rules/security.md)")
    if "Features.overlayKinds()" not in sources.get("shell/state/Overlays.qml", ""):
        flag("features", "shell/state/Overlays.qml", 1, "overlay kinds come from the built overlay rows of utils/Features.js, never a second list (rules/features.md)")

    config = dict(files).get("shell/config/Config.qml", "")
    settings = readme_section("Settings (`shell.json`)")
    for group, body in re.findall(r"property JsonObject (\w+): JsonObject \{(.*?)\n            \}", config, re.S):
        for key in re.findall(r"property \w+ (\w+):", body):
            if f"`{group}.{key}`" not in settings:
                flag("settings", "shell/config/Config.qml", 1, f"`{group}.{key}` has no README settings row (rules/architecture.md)")

    schema = dict(files).get("shell/utils/Schema.js", "")
    fallbacks = dict(re.findall(r"^\s*\"(\w+\.\w+)\": \{ type: \"\w+\", fallback: (.+?)(?:, choices: .*)? \},?$", schema, re.M))
    defaults = {
        f"{group}.{key}": value
        for group, body in re.findall(r"property JsonObject (\w+): JsonObject \{(.*?)\n            \}", config, re.S)
        for key, value in re.findall(r"property \w+ (\w+): (.+)", body)
    }
    rows = set(re.findall(r"^\| `(\w+\.\w+)` \|", settings, re.M))
    assigned = set(re.findall(r"adapter\.(\w+\.\w+) = ", config))
    accepted = set(re.findall(r"accept\(\"(\w+\.\w+)\"", config))
    for key in sorted(set(fallbacks) | set(defaults) | rows):
        missing = [place for place, keys in (("utils/Schema.js", fallbacks), ("Config.qml adapter", defaults), ("README settings", rows)) if key not in keys]
        if missing:
            flag("settings", "shell/utils/Schema.js", 1, f"`{key}` is missing from {', '.join(missing)}; the schema, the adapter and the README list the same keys (rules/state.md)")
        elif fallbacks[key] != defaults[key]:
            flag("settings", "shell/config/Config.qml", 1, f"`{key}` defaults to {defaults[key]} in the adapter but {fallbacks[key]} in utils/Schema.js (rules/state.md)")
    for key in sorted(assigned - accepted):
        flag("settings", "shell/config/Config.qml", 1, f"the setter for `{key}` does not check it with accept() against utils/Schema.js (rules/state.md)")
    return found


def main():
    is_hook = "--hook" in sys.argv
    if is_hook:
        try:
            payload = json.load(sys.stdin)
        except Exception:
            payload = {}
        if payload.get("stop_hook_active"):
            return 0
    found = check(list(shell_files()))
    if not found:
        if not is_hook:
            print("All hard rules hold.")
        return 0
    if is_hook:
        reason = "Hard rules are broken. Fix these before stopping (tools/check-rules.py):\n" + "\n".join(found)
        print(json.dumps({"decision": "block", "reason": reason}))
        return 0
    print("\n".join(found))
    print(f"\n{len(found)} violation(s).")
    return 1


if __name__ == "__main__":
    sys.exit(main())
