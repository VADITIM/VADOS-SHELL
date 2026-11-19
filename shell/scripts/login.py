import getpass
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

SHELL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALLER = os.path.join(os.path.dirname(SHELL), "sddm", "install.py")
TARGET = "/usr/share/sddm/themes/vados"
FACES = "/usr/share/sddm/faces"
MAIN_CONFIG = "/etc/sddm.conf"
CONFIG_FOLDER = "/etc/sddm.conf.d"
SELECTION = "/etc/sddm.conf.d/vados.conf"
STAGE_PATTERN = re.compile(r"/tmp/vados-sddm-[A-Za-z0-9_]+/vados")
USER_PATTERN = re.compile(r"[a-z_][a-z0-9_-]*")


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return None


def theme_of(text, current):
    section = ""
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
        elif section == "Theme" and line.startswith("Current="):
            current = line.split("=", 1)[1].strip()
    return current


def current_theme(skip=None):
    current = ""
    if os.path.isdir(CONFIG_FOLDER):
        for name in sorted(os.listdir(CONFIG_FOLDER)):
            path = os.path.join(CONFIG_FOLDER, name)
            if name.endswith(".conf") and path != skip:
                current = theme_of(read(path) or "", current)
    return theme_of(read(MAIN_CONFIG) or "", current)


def installer():
    specification = importlib.util.spec_from_file_location("vados_sddm_install", INSTALLER)
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def status():
    print(json.dumps({
        "hasSddm": shutil.which("sddm") is not None,
        "hasTheme": os.path.isfile(INSTALLER),
        "current": current_theme(),
        "main": current_theme(skip=SELECTION),
    }))


def stage():
    tempfile.tempdir = "/tmp"
    module = installer()
    settings = module.read_settings()
    picture = os.path.expanduser(module.setting(settings, "profile.picture", "").removeprefix("file://"))
    print(json.dumps({
        "folder": module.stage(settings),
        "picture": picture if os.path.isfile(picture) else "",
        "user": getpass.getuser(),
    }))


def apply(choice, folder, picture, user):
    if choice == "main":
        if os.path.exists(SELECTION):
            os.remove(SELECTION)
        return
    if choice != "vados" or not STAGE_PATTERN.fullmatch(folder) or not os.path.isdir(folder):
        sys.stderr.write("refused: the theme must come from a staged folder\n")
        sys.exit(2)
    if os.path.isdir(TARGET):
        shutil.rmtree(TARGET)
    shutil.copytree(folder, TARGET)
    subprocess.call(["chmod", "-R", "a+rX", TARGET])
    mirror = os.path.join(TARGET, "Xsetup")
    if os.path.isfile(mirror):
        os.chmod(mirror, 0o755)
    if picture and USER_PATTERN.fullmatch(user) and os.path.isfile(picture):
        os.makedirs(FACES, exist_ok=True)
        face = os.path.join(FACES, f"{user}.face.icon")
        shutil.copyfile(picture, face)
        os.chmod(face, 0o644)
    os.makedirs(CONFIG_FOLDER, exist_ok=True)
    with open(SELECTION, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("[Theme]\nCurrent=vados\n")
        if os.path.isfile(mirror):
            handle.write(f"\n[X11]\nDisplayCommand={mirror}\n")


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "status":
        status()
    elif len(sys.argv) >= 2 and sys.argv[1] == "stage":
        stage()
    elif len(sys.argv) == 6 and sys.argv[1] == "apply":
        apply(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    else:
        sys.stderr.write("usage: login.py status | stage | apply <vados|main> <folder> <picture> <user>\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
