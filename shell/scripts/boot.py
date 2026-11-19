import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

ASSETS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "boot")
SPLASH = "/usr/share/vados/boot/splash.bmp"
THEME = "/usr/share/plymouth/themes/vados"
BACKUP = "/var/lib/vados/boot"
MKINITCPIO = "/etc/mkinitcpio.conf"
CMDLINE = "/etc/kernel/cmdline"
PLYMOUTH = "/etc/plymouth/plymouthd.conf"
PRESETS = "/etc/mkinitcpio.d"
PLYMOUTH_HOOK = "/usr/lib/initcpio/install/plymouth"
IMAGE_ROOTS = ("/boot/", "/efi/")
MARK_SIZE = 256
BUBBLE_SIZE = 14
MARK_ACCENT = "#f0f0f0"
SPACE_MARGIN = 64 * 1024 * 1024
ACCENT_PATTERN = re.compile(r"#[0-9a-fA-F]{6}")
PRESET_PATTERN = re.compile(r"/etc/mkinitcpio\.d/[A-Za-z0-9_.+-]+\.preset")


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return None


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def status():
    presets = {}
    if os.path.isdir(PRESETS):
        for name in sorted(os.listdir(PRESETS)):
            if name.endswith(".preset"):
                text = read(os.path.join(PRESETS, name))
                if text is not None:
                    presets[os.path.join(PRESETS, name)] = text
    print(json.dumps({
        "hasMkinitcpio": shutil.which("mkinitcpio") is not None and read(MKINITCPIO) is not None,
        "hasPlymouth": os.path.exists(PLYMOUTH_HOOK),
        "hasRenderer": shutil.which("rsvg-convert") is not None,
        "presets": presets,
        "mkinitcpio": read(MKINITCPIO) or "",
        "cmdline": read(CMDLINE),
        "plymouth": read(PLYMOUTH) or "",
    }))


def is_allowed(path):
    return path in (MKINITCPIO, CMDLINE, PLYMOUTH) or PRESET_PATTERN.fullmatch(path) is not None


def is_image(path):
    real = os.path.realpath(path)
    return real == path and real.endswith(".efi") and real.startswith(IMAGE_ROOTS) and os.path.isfile(real)


def render(svg, size, target):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False, encoding="utf-8") as handle:
        handle.write(svg)
        source = handle.name
    try:
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), "-o", target, source], check=True, capture_output=True)
    finally:
        os.remove(source)


def paeth(left, above, corner):
    estimate = left + above - corner
    distances = (abs(estimate - left), abs(estimate - above), abs(estimate - corner))
    if distances[0] <= distances[1] and distances[0] <= distances[2]:
        return left
    return above if distances[1] <= distances[2] else corner


def decode(path):
    with open(path, "rb") as handle:
        data = handle.read()
    position = 8
    width = height = 0
    packed = b""
    while position < len(data):
        length, kind = struct.unpack(">I4s", data[position:position + 8])
        body = data[position + 8:position + 8 + length]
        if kind == b"IHDR":
            width, height, depth, colour = struct.unpack(">IIBB", body[:10])
            if depth != 8 or colour != 6:
                raise ValueError("the renderer gave an unexpected picture format")
        elif kind == b"IDAT":
            packed += body
        position += 12 + length
    raw = zlib.decompress(packed)
    stride = width * 4
    rows = []
    above = bytearray(stride)
    offset = 0
    for _ in range(height):
        method = raw[offset]
        line = bytearray(raw[offset + 1:offset + 1 + stride])
        offset += 1 + stride
        for index in range(stride):
            left = line[index - 4] if index >= 4 else 0
            corner = above[index - 4] if index >= 4 else 0
            if method == 1:
                line[index] = (line[index] + left) & 255
            elif method == 2:
                line[index] = (line[index] + above[index]) & 255
            elif method == 3:
                line[index] = (line[index] + (left + above[index]) // 2) & 255
            elif method == 4:
                line[index] = (line[index] + paeth(left, above[index], corner)) & 255
        rows.append(line)
        above = line
    return width, height, rows


def bitmap(picture, target):
    width, height, rows = decode(picture)
    padding = (4 - width * 3 % 4) % 4
    pixels = bytearray()
    for line in reversed(rows):
        for index in range(0, width * 4, 4):
            alpha = line[index + 3]
            pixels += bytes((line[index + 2] * alpha // 255, line[index + 1] * alpha // 255, line[index] * alpha // 255))
        pixels += bytes(padding)
    header = struct.pack("<2sIHHI", b"BM", 54 + len(pixels), 0, 0, 54)
    information = struct.pack("<IiiHHIIiiII", 40, width, height, 1, 24, 0, len(pixels), 2835, 2835, 0, 0)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "wb") as handle:
        handle.write(header + information + pixels)


def install_assets(accent, is_splash, is_plymouth, staging):
    mark = read(os.path.join(ASSETS, "mark.svg")).replace(MARK_ACCENT, accent)
    mark_picture = os.path.join(staging, "mark.png")
    render(mark, MARK_SIZE, mark_picture)
    if is_splash:
        bitmap(mark_picture, SPLASH)
    if is_plymouth:
        os.makedirs(THEME, exist_ok=True)
        shutil.copyfile(mark_picture, os.path.join(THEME, "mark.png"))
        bubble = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16"><circle cx="8" cy="8" r="8" fill="{accent}"/></svg>'
        render(bubble, BUBBLE_SIZE, os.path.join(THEME, "bubble.png"))
        for name in ("vados.plymouth", "vados.script"):
            shutil.copyfile(os.path.join(ASSETS, "plymouth", name), os.path.join(THEME, name))


def remove_unused(is_splash, is_plymouth):
    if not is_splash and os.path.exists(SPLASH):
        os.remove(SPLASH)
    if not is_plymouth and os.path.isdir(THEME):
        shutil.rmtree(THEME)


def keep_images(images):
    for image in images:
        stem, extension = os.path.splitext(image)
        target = f"{stem}-previous{extension}"
        free = shutil.disk_usage(os.path.dirname(image)).free
        existing = os.path.getsize(target) if os.path.exists(target) else 0
        if free + existing < os.path.getsize(image) + SPACE_MARGIN:
            print(f"not enough space to keep {image} as {target}", file=sys.stderr)
            continue
        shutil.copyfile(image, target)


def rebuild():
    found = subprocess.run(["mkinitcpio", "-P"], capture_output=True, text=True)
    if found.returncode != 0:
        print("\n".join((found.stdout + found.stderr).strip().splitlines()[-12:]), file=sys.stderr)
    return found.returncode == 0


def apply():
    if os.geteuid() != 0:
        print("boot.py apply must run as root", file=sys.stderr)
        sys.exit(4)
    try:
        request = json.loads(sys.stdin.read())
    except ValueError:
        sys.exit(2)
    accent = request.get("accent", "")
    files = request.get("files", {})
    images = request.get("images", [])
    is_splash = request.get("splash") is True
    is_plymouth = request.get("plymouth") is True
    if not ACCENT_PATTERN.fullmatch(accent) or not all(is_allowed(path) and isinstance(text, str) for path, text in files.items()) or not all(is_image(image) for image in images):
        print("refused: the request names a file or picture outside the boot setup", file=sys.stderr)
        sys.exit(2)
    originals = {path: read(path) for path in files}
    with tempfile.TemporaryDirectory() as staging:
        install_assets(accent, is_splash, is_plymouth, staging)
    for path, text in originals.items():
        if text is not None:
            write(os.path.join(BACKUP, path.strip("/").replace("/", "_")), text)
    keep_images(images)
    for path, text in files.items():
        write(path, text)
    if rebuild():
        remove_unused(is_splash, is_plymouth)
        return
    for path, text in originals.items():
        if text is None:
            os.remove(path)
        else:
            write(path, text)
    rebuild()
    print("the boot image did not build; every boot file is back as it was", file=sys.stderr)
    sys.exit(3)


def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "status":
        status()
    elif len(sys.argv) >= 2 and sys.argv[1] == "apply":
        apply()
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
