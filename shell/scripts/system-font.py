import os
import subprocess
import sys
from xml.sax.saxutils import escape

SCHEMA = "org.gnome.desktop.interface"
KEY = "font-name"
ALIASES = ("sans-serif", "system-ui", "ui-sans-serif")


def config_path():
    home = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
    return os.path.join(home, "fontconfig", "conf.d", "99-vados-system-font.conf")


def read_interface_font():
    try:
        found = subprocess.run(["gsettings", "get", SCHEMA, KEY], capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return ""
    return found.stdout.strip().strip("'")


def write_interface_font(value):
    command = ["gsettings", "set", SCHEMA, KEY, value] if value else ["gsettings", "reset", SCHEMA, KEY]
    try:
        subprocess.run(command, check=False, capture_output=True)
    except OSError:
        pass


def size_of(font_name):
    last = font_name.rsplit(" ", 1)[-1] if font_name else ""
    return last if last.replace(".", "", 1).isdigit() else "11"


def apply(family):
    previous = read_interface_font()
    path = config_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    aliases = "".join(
        f"  <alias binding=\"strong\">\n    <family>{alias}</family>\n    <prefer><family>{escape(family)}</family></prefer>\n  </alias>\n"
        for alias in ALIASES
    )
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("<?xml version=\"1.0\"?>\n<!DOCTYPE fontconfig SYSTEM \"urn:fontconfig:fonts.dtd\">\n<fontconfig>\n" + aliases + "</fontconfig>\n")
    write_interface_font(f"{family} {size_of(previous)}")
    print(previous)


def restore(previous):
    path = config_path()
    if os.path.exists(path):
        os.remove(path)
    write_interface_font(previous)


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "apply" and sys.argv[2].strip():
        apply(sys.argv[2].strip())
    elif len(sys.argv) >= 2 and sys.argv[1] == "restore":
        restore(sys.argv[2] if len(sys.argv) >= 3 else "")
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
