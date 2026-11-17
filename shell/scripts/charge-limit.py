import glob
import os
import sys

candidates = ["/sys/bus/wmi/drivers/acer-wmi-battery/health_mode"] + sorted(glob.glob("/sys/class/power_supply/BAT*/charge_control_end_threshold"))


def read(path):
    try:
        with open(path) as handle:
            return handle.read().strip()
    except OSError:
        return ""


def probe():
    print(read("/sys/class/dmi/id/sys_vendor"))
    for path in candidates:
        if os.path.exists(path):
            access = "w" if os.access(path, os.W_OK) else "r"
            print(path, access, read(path))
            return


def apply(path, value):
    if path not in candidates:
        sys.exit(2)
    with open(path, "w") as handle:
        handle.write(value)


if sys.argv[1] == "probe":
    probe()
elif sys.argv[1] == "apply":
    apply(sys.argv[2], sys.argv[3])
