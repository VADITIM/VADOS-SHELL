import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.path.join(ROOT, "shell")

ENGINE_TESTS = {
    "shell/utils/Liquid.js": "tst_liquid.qml",
    "shell/state/Overlays.qml": "tst_overlays.qml",
    "shell/state/Attention.qml": "tst_attention.qml",
    "shell/components/Gesture.qml": "tst_gesture.qml",
    "shell/components/Burst.qml": "tst_burst.qml",
    "shell/services/StateFile.qml": "tst_statefile.qml",
    "shell/services/Confinement.qml": "tst_confinement.qml",
    "shell/utils/Phases.js": "tst_lifecycle.qml",
    "shell/components/Lifecycle.qml": "tst_lifecycle.qml",
    "shell/components/Launch.qml": "tst_launch.qml",
    "shell/utils/Geometry.js": "tst_geometry.qml",
    "shell/utils/Platform.js": "tst_geometry.qml",
}

TIMERS_NOT_MOTION = {"Motion.reveal.dwell"}


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
    only_in("overlays", r"WlrLayershell\.keyboardFocus|WlrLayer\.Overlay", {"shell/windows/OverlayWindow.qml"},
            "overlays are OverlayWindows registered in state/Overlays.qml (rules/interaction.md)")
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

    config = dict(files).get("shell/config/Config.qml", "")
    settings = readme_section("Settings (`shell.json`)")
    for group, body in re.findall(r"property JsonObject (\w+): JsonObject \{(.*?)\n            \}", config, re.S):
        for key in re.findall(r"property \w+ (\w+):", body):
            if f"`{group}.{key}`" not in settings:
                flag("settings", "shell/config/Config.qml", 1, f"`{group}.{key}` has no README settings row (rules/architecture.md)")
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
