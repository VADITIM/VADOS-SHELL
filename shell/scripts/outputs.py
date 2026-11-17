import json
import os
import socket
import struct
import sys

MANAGER_INTERFACE = "zwlr_output_manager_v1"
MANAGER_VERSION = 4
DISPLAY_ID = 1
REGISTRY_ID = 2
CALLBACK_ID = 3
MANAGER_ID = 4
TIMEOUT_SECONDS = 2


def socket_path():
    display = os.environ.get("WAYLAND_DISPLAY", "wayland-0")
    if display.startswith("/"):
        return display
    return os.path.join(os.environ.get("XDG_RUNTIME_DIR", ""), display)


def encoded_string(text):
    data = text.encode("utf-8") + b"\0"
    padding = (4 - len(data) % 4) % 4
    return struct.pack("<I", len(data)) + data + b"\0" * padding


def message(object_id, opcode, payload):
    return struct.pack("<II", object_id, ((8 + len(payload)) << 16) | opcode) + payload


class Reader:
    def __init__(self, payload):
        self.payload = payload
        self.offset = 0

    def unsigned(self):
        value = struct.unpack_from("<I", self.payload, self.offset)[0]
        self.offset += 4
        return value

    def signed(self):
        value = struct.unpack_from("<i", self.payload, self.offset)[0]
        self.offset += 4
        return value

    def fixed(self):
        return self.signed() / 256

    def string(self):
        length = self.unsigned()
        if length == 0:
            return ""
        text = self.payload[self.offset:self.offset + length - 1].decode("utf-8", "replace")
        self.offset += length + (4 - length % 4) % 4
        return text


class Session:
    def __init__(self, connection):
        self.connection = connection
        self.buffer = b""
        self.globals = {}
        self.heads = {}
        self.modes = {}
        self.order = []
        self.isSynced = False
        self.isDone = False

    def send(self, object_id, opcode, payload=b""):
        self.connection.sendall(message(object_id, opcode, payload))

    def pump(self, isFinished):
        while not isFinished():
            chunk = self.connection.recv(65536)
            if not chunk:
                raise ConnectionError("the compositor closed the connection")
            self.buffer += chunk
            while len(self.buffer) >= 8:
                object_id, word = struct.unpack_from("<II", self.buffer, 0)
                size = word >> 16
                if len(self.buffer) < size:
                    break
                self.dispatch(object_id, word & 0xFFFF, Reader(self.buffer[8:size]))
                self.buffer = self.buffer[size:]

    def dispatch(self, object_id, opcode, reader):
        if object_id == DISPLAY_ID and opcode == 0:
            reader.unsigned()
            code = reader.unsigned()
            raise ConnectionError(f"protocol error {code}: {reader.string()}")
        if object_id == REGISTRY_ID and opcode == 0:
            name = reader.unsigned()
            interface = reader.string()
            self.globals[interface] = (name, reader.unsigned())
        elif object_id == CALLBACK_ID and opcode == 0:
            self.isSynced = True
        elif object_id == MANAGER_ID:
            self.read_manager(opcode, reader)
        elif object_id in self.heads:
            self.read_head(self.heads[object_id], opcode, reader)
        elif object_id in self.modes:
            self.read_mode(self.modes[object_id], opcode, reader)

    def read_manager(self, opcode, reader):
        if opcode == 0:
            head_id = reader.unsigned()
            self.heads[head_id] = {"name": "", "description": "", "make": "", "model": "", "serial": "", "enabled": False, "x": 0, "y": 0, "transform": 0, "scale": 1, "modes": [], "current": -1}
            self.order.append(head_id)
        elif opcode in (1, 2):
            self.isDone = True

    def read_head(self, head, opcode, reader):
        if opcode == 0:
            head["name"] = reader.string()
        elif opcode == 1:
            head["description"] = reader.string()
        elif opcode == 3:
            mode_id = reader.unsigned()
            self.modes[mode_id] = {"width": 0, "height": 0, "refresh": 0, "preferred": False, "head": head}
            head["modes"].append(mode_id)
        elif opcode == 4:
            head["enabled"] = reader.signed() != 0
        elif opcode == 5:
            mode_id = reader.unsigned()
            head["current"] = head["modes"].index(mode_id) if mode_id in head["modes"] else -1
        elif opcode == 6:
            head["x"] = reader.signed()
            head["y"] = reader.signed()
        elif opcode == 7:
            head["transform"] = reader.signed()
        elif opcode == 8:
            head["scale"] = reader.fixed()
        elif opcode == 10:
            head["make"] = reader.string()
        elif opcode == 11:
            head["model"] = reader.string()
        elif opcode == 12:
            head["serial"] = reader.string()

    def read_mode(self, mode, opcode, reader):
        if opcode == 0:
            mode["width"] = reader.signed()
            mode["height"] = reader.signed()
        elif opcode == 1:
            mode["refresh"] = reader.signed()
        elif opcode == 2:
            mode["preferred"] = True

    def described(self):
        result = []
        for head_id in self.order:
            head = dict(self.heads[head_id])
            head["modes"] = [{key: value for key, value in self.modes[mode_id].items() if key != "head"} for mode_id in head["modes"]]
            result.append(head)
        return result


def main():
    connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    connection.settimeout(TIMEOUT_SECONDS)
    try:
        connection.connect(socket_path())
        session = Session(connection)
        session.send(DISPLAY_ID, 1, struct.pack("<I", REGISTRY_ID))
        session.send(DISPLAY_ID, 0, struct.pack("<I", CALLBACK_ID))
        session.pump(lambda: session.isSynced)
        if MANAGER_INTERFACE not in session.globals:
            print(json.dumps({"supported": False, "heads": []}))
            return 0
        name, version = session.globals[MANAGER_INTERFACE]
        payload = struct.pack("<I", name) + encoded_string(MANAGER_INTERFACE) + struct.pack("<II", min(version, MANAGER_VERSION), MANAGER_ID)
        session.send(REGISTRY_ID, 0, payload)
        session.pump(lambda: session.isDone)
        print(json.dumps({"supported": True, "heads": session.described()}))
        return 0
    except (OSError, ConnectionError, struct.error) as error:
        print(json.dumps({"supported": False, "heads": [], "error": str(error)}))
        return 1
    finally:
        connection.close()


if __name__ == "__main__":
    sys.exit(main())
