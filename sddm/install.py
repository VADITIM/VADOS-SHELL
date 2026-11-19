import getpass
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
THEME = os.path.join(HERE, "vados")
SETTINGS = os.path.join(os.path.expanduser("~"), ".config", "vados", "shell.json")
TARGET = "/usr/share/sddm/themes/vados"
FACES = "/usr/share/sddm/faces"
SELECTION = "/etc/sddm.conf.d/vados.conf"


def read_settings():
    try:
        with open(SETTINGS, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return {}


def setting(settings, dotted, fallback):
    group, key = dotted.split(".")
    value = settings.get(group, {}).get(key, fallback)
    return fallback if value in (None, "") else value


def stage(settings):
    folder = os.path.join(tempfile.mkdtemp(prefix="vados-sddm-"), "vados")
    shutil.copytree(THEME, folder)
    background = ""
    wallpaper = os.path.expanduser(setting(settings, "lock.wallpaper", ""))
    if wallpaper and os.path.isfile(wallpaper):
        name = "background" + os.path.splitext(wallpaper)[1].lower()
        shutil.copyfile(wallpaper, os.path.join(folder, name))
        background = f"{TARGET}/{name}"
    lines = [
        "[General]",
        f"background={background}",
        f"accent={setting(settings, 'appearance.accent', '#ffffff')}",
        f"reducedMotion={'true' if setting(settings, 'motion.reduced', False) is True else 'false'}",
        f"quality={setting(settings, 'rendering.quality', 'full')}",
    ]
    with open(os.path.join(folder, "theme.conf.user"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
    return folder


def commands(folder, settings):
    quoted = shlex.quote(folder)
    steps = [
        f"sudo rm -rf {TARGET}",
        f"sudo cp -r {quoted} {TARGET}",
        f"sudo chmod -R a+rX {TARGET}",
        f"sudo chmod 755 {TARGET}/Xsetup",
        "sudo mkdir -p /etc/sddm.conf.d",
        f"printf '[Theme]\\nCurrent=vados\\n\\n[X11]\\nDisplayCommand={TARGET}/Xsetup\\n' | sudo tee {SELECTION}",
    ]
    picture = os.path.expanduser(setting(settings, "profile.picture", ""))
    if picture and os.path.isfile(picture):
        steps.append(f"sudo install -m 644 {shlex.quote(picture)} {FACES}/{getpass.getuser()}.face.icon")
    return steps


def main():
    settings = read_settings()
    folder = stage(settings)
    if "--preview" in sys.argv:
        return subprocess.call(["sddm-greeter-qt6", "--test-mode", "--theme", folder])
    print(f"Staged the theme with your shell.json in {folder}")
    print("Nothing system-wide changed. To install it, run:\n")
    for step in commands(folder, settings):
        print(step)
    print("\nPreview first with: python sddm/install.py --preview")
    return 0


if __name__ == "__main__":
    sys.exit(main())
