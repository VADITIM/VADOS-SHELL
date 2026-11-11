import json
import os
import sys
import time

PAGE_SIZE = os.sysconf("SC_PAGE_SIZE")
TICKS_PER_SECOND = os.sysconf("SC_CLK_TCK")


def read_text(path):
    try:
        with open(path, "rb") as handle:
            return handle.read().decode("utf-8", "replace")
    except OSError:
        return None


def total_ticks():
    line = read_text("/proc/stat").split("\n", 1)[0]
    return sum(int(value) for value in line.split()[1:9])


def process_ticks(stat):
    after_name = stat[stat.rindex(")") + 2:].split()
    return int(after_name[11]) + int(after_name[12])


def disk_bytes(pid):
    text = read_text(f"/proc/{pid}/io")
    if text is None:
        return -1
    values = dict(line.split(": ") for line in text.strip().split("\n") if ": " in line)
    return int(values.get("read_bytes", 0)) + int(values.get("write_bytes", 0))


def executable(pid, arguments):
    try:
        return os.readlink(f"/proc/{pid}/exe").removesuffix(" (deleted)")
    except OSError:
        return arguments[0] if arguments and arguments[0].startswith("/") else ""


def sample():
    processes = []
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        stat = read_text(f"/proc/{entry}/stat")
        command_line = read_text(f"/proc/{entry}/cmdline")
        statm = read_text(f"/proc/{entry}/statm")
        if not stat or not command_line or not statm:
            continue
        arguments = [part for part in command_line.split("\0") if part]
        path = executable(entry, arguments)
        command = stat[stat.index("(") + 1:stat.rindex(")")]
        name = os.path.basename(path) or command
        pages = statm.split()
        memory = max(0, int(pages[1]) - int(pages[2])) * PAGE_SIZE
        processes.append([int(entry), name, path, process_ticks(stat), memory, disk_bytes(entry)])
    return {"time": time.monotonic(), "ticks": total_ticks(), "hertz": TICKS_PER_SECOND, "processes": processes}


def main():
    interval = int(sys.argv[1]) / 1000 if len(sys.argv) > 1 else 1.5
    while True:
        print(json.dumps(sample(), separators=(",", ":")), flush=True)
        time.sleep(interval)


if __name__ == "__main__":
    main()
