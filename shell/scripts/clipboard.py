import hashlib
import json
import os
import subprocess
import sys

PASSWORD_HINT = "x-kde-passwordManagerHint"
FILE_TYPE = "text/uri-list"
TEXT_TYPES = ["text/plain;charset=utf-8", "text/plain", "UTF8_STRING", "STRING", "TEXT"]
IMAGE_EXTENSIONS = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif", "image/bmp": "bmp"}
QUIET_STATES = {"nil", "clear", "sensitive"}
NAME_LENGTH = 32
TIMEOUT = 5


def paste(mime):
    return subprocess.run(["wl-paste", "--no-newline", "--type", mime], capture_output=True, timeout=TIMEOUT, check=False).stdout


def offered():
    result = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True, timeout=TIMEOUT, check=False)
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def report(entry):
    sys.stdout.write(json.dumps(entry) + "\n")
    sys.stdout.flush()


def keep_image(mime, directory):
    content = paste(mime)
    if not content:
        return ""
    os.makedirs(directory, mode=0o700, exist_ok=True)
    path = os.path.join(directory, hashlib.sha256(content).hexdigest()[:NAME_LENGTH] + "." + IMAGE_EXTENSIONS[mime])
    if not os.path.exists(path):
        with open(path, "wb") as handle:
            handle.write(content)
    return path


def read(directory, is_keeping_images):
    sys.stdin.buffer.read()
    if os.environ.get("CLIPBOARD_STATE", "data") in QUIET_STATES:
        return
    types = offered()
    if PASSWORD_HINT in types and paste(PASSWORD_HINT).strip() == b"secret":
        report({"skip": "secret"})
        return
    if FILE_TYPE in types:
        report({"kind": "file", "text": paste(FILE_TYPE).decode("utf-8", "replace")})
        return
    text_type = next((mime for mime in TEXT_TYPES if mime in types), None)
    image_type = next((mime for mime in IMAGE_EXTENSIONS if mime in types), None)
    if image_type and not text_type:
        path = keep_image(image_type, directory) if is_keeping_images else ""
        report({"kind": "image", "path": path} if path else {"skip": "image"})
        return
    if text_type:
        report({"kind": "text", "text": paste(text_type).decode("utf-8", "replace")})


def main():
    if len(sys.argv) < 4 or sys.argv[1] != "read":
        sys.stderr.write("usage: clipboard.py read <image folder> <images|text>\n")
        sys.exit(2)
    try:
        read(sys.argv[2], sys.argv[3] == "images")
    except (OSError, subprocess.SubprocessError) as error:
        sys.stderr.write("clipboard: " + str(error) + "\n")


if __name__ == "__main__":
    main()
