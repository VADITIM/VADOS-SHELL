import json
import lzma
import os
import re
import select
import sys

REPORT = 32
TIMEOUT = 0.5
RAW_USAGE = bytes([0x06, 0x60, 0xFF, 0x09, 0x61])
PROTOCOL_VERSION = 0x01
GET_KEYCODE = 0x04
SET_KEYCODE = 0x05
LAYER_COUNT = 0x11
BUFFER_GET = 0x12
VIAL_PREFIX = 0xFE
VIAL_KEYBOARD = 0x00
VIAL_SIZE = 0x01
VIAL_DEFINITION = 0x02
BUFFER_CHUNK = 28
DEVICE_PATTERN = re.compile("^/dev/hidraw[0-9]+$")
DENIED = 3
REFUSED = 2


def log(message):
    print("vados: keyboards: " + message, file=sys.stderr)


def class_folder(path):
    return os.path.join("/sys/class/hidraw", os.path.basename(path), "device")


def read_text(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return ""


def is_raw_interface(path):
    try:
        with open(os.path.join(class_folder(path), "report_descriptor"), "rb") as handle:
            return RAW_USAGE in handle.read()
    except OSError:
        return False


def describe(path):
    event = dict(line.split("=", 1) for line in read_text(os.path.join(class_folder(path), "uevent")).splitlines() if "=" in line)
    identity = event.get("HID_ID", "0:0:0").split(":")
    return {
        "path": path,
        "name": event.get("HID_NAME", os.path.basename(path)),
        "vendor": identity[1][-4:] if len(identity) > 2 else "",
        "product": identity[2][-4:] if len(identity) > 2 else "",
        "isWritable": os.access(path, os.R_OK | os.W_OK),
    }


def boards():
    found = []
    for name in sorted(os.listdir("/sys/class/hidraw")) if os.path.isdir("/sys/class/hidraw") else []:
        path = "/dev/" + name
        if is_raw_interface(path):
            found.append(describe(path))
    return found


def exchange(handle, payload):
    report = bytes(payload) + bytes(REPORT - len(payload))
    os.write(handle, bytes([0]) + report)
    ready, _, _ = select.select([handle], [], [], TIMEOUT)
    if not ready:
        raise TimeoutError("the keyboard did not answer")
    return os.read(handle, REPORT)


def definition_of(handle):
    answer = exchange(handle, [VIAL_PREFIX, VIAL_KEYBOARD])
    if answer[0] == 0xFF and answer[1] == VIAL_KEYBOARD:
        return None
    size_answer = exchange(handle, [VIAL_PREFIX, VIAL_SIZE])
    size = int.from_bytes(size_answer[0:4], "little")
    if size <= 0 or size > 1 << 20:
        return None
    packed = bytearray()
    page = 0
    while len(packed) < size:
        packed += exchange(handle, [VIAL_PREFIX, VIAL_DEFINITION] + list(page.to_bytes(4, "little")))
        page += 1
    try:
        return json.loads(lzma.decompress(bytes(packed[:size])))
    except (lzma.LZMAError, ValueError):
        return None


def keymap_of(handle, layers, rows, columns):
    total = layers * rows * columns * 2
    data = bytearray()
    offset = 0
    while offset < total:
        length = min(BUFFER_CHUNK, total - offset)
        answer = exchange(handle, [BUFFER_GET, offset >> 8, offset & 0xFF, length])
        data += answer[4:4 + length]
        offset += length
    codes = [int.from_bytes(data[index:index + 2], "big") for index in range(0, total, 2)]
    return [[codes[(layer * rows + row) * columns:(layer * rows + row + 1) * columns] for row in range(rows)] for layer in range(layers)]


def checked(path):
    if not DEVICE_PATTERN.match(path) or not is_raw_interface(path):
        log(path + " is not a VIA or Vial keyboard interface, nothing was touched")
        sys.exit(REFUSED)
    try:
        return os.open(path, os.O_RDWR)
    except PermissionError:
        log("no access to " + path + "; read it again as admin")
        sys.exit(DENIED)


def summary(handle):
    protocol_answer = exchange(handle, [PROTOCOL_VERSION])
    protocol = int.from_bytes(protocol_answer[1:3], "big")
    layers = exchange(handle, [LAYER_COUNT])[1]
    definition = definition_of(handle)
    result = {"protocol": protocol, "layers": layers, "rows": 0, "columns": 0, "layout": [], "keymap": [], "hasDefinition": definition is not None}
    if definition is not None:
        matrix = definition.get("matrix", {})
        result["rows"] = int(matrix.get("rows", 0))
        result["columns"] = int(matrix.get("cols", 0))
        result["layout"] = definition.get("layouts", {}).get("keymap", [])
        if result["rows"] > 0 and result["columns"] > 0 and layers > 0:
            result["keymap"] = keymap_of(handle, layers, result["rows"], result["columns"])
    return result


def read(path):
    handle = checked(path)
    try:
        print(json.dumps(summary(handle)))
    finally:
        os.close(handle)


def write(path, requested):
    changes = json.loads(requested)
    handle = checked(path)
    try:
        state = summary(handle)
        written = 0
        for change in changes:
            layer, row, column, code = (int(change[name]) for name in ("layer", "row", "column", "code"))
            if not (0 <= layer < state["layers"] and 0 <= row < state["rows"] and 0 <= column < state["columns"] and 0 <= code <= 0xFFFF):
                log(f"refused key {layer}:{row}:{column}, it is outside the keyboard's matrix")
                continue
            exchange(handle, [SET_KEYCODE, layer, row, column, code >> 8, code & 0xFF])
            answer = exchange(handle, [GET_KEYCODE, layer, row, column])
            if int.from_bytes(answer[4:6], "big") == code:
                written += 1
            else:
                log(f"key {layer}:{row}:{column} reads back another code, the keyboard may block it (Vial locks QK_BOOT)")
        log(f"wrote {written} of {len(changes)} keys to {path}")
        print(json.dumps(summary(handle)))
    finally:
        os.close(handle)


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "list"
    try:
        if command == "list":
            print(json.dumps(boards()))
        elif command == "read" and len(sys.argv) > 2:
            read(sys.argv[2])
        elif command == "write" and len(sys.argv) > 3:
            write(sys.argv[2], sys.argv[3])
        else:
            log("usage: keyboards.py list | read <hidraw> | write <hidraw> <changes>")
            sys.exit(REFUSED)
    except (OSError, TimeoutError, ValueError, KeyError, TypeError) as error:
        log(f"{command} failed: {error}")
        sys.exit(1)


main()
