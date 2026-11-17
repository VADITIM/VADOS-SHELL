import re
import subprocess
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

IWD = "net.connman.iwd"
AGENT_PATH = "/vados/wifi/agent"
CANCELED = "net.connman.iwd.Agent.Error.Canceled"
FOREVER = GLib.MAXINT32
IWD_STORAGE = "/var/lib/iwd/"
PLAIN_NAME = re.compile(r"^[A-Za-z0-9 _-]+$")
NO_AGENT = ("No authentication agent", "textual authentication agent")
PKEXEC_DISMISSED = 126
KNOWN_WAIT_SECONDS = 3
KNOWN_POLL_SECONDS = 0.2
AGENT_INTERFACE = """
<node>
  <interface name="net.connman.iwd.Agent">
    <method name="Release"/>
    <method name="RequestPassphrase">
      <arg type="o" direction="in"/>
      <arg type="s" direction="out"/>
    </method>
    <method name="RequestPrivateKeyPassphrase">
      <arg type="o" direction="in"/>
      <arg type="s" direction="out"/>
    </method>
    <method name="RequestUserNameAndPassword">
      <arg type="o" direction="in"/>
      <arg type="s" direction="out"/>
      <arg type="s" direction="out"/>
    </method>
    <method name="RequestUserPassword">
      <arg type="o" direction="in"/>
      <arg type="s" direction="in"/>
      <arg type="s" direction="out"/>
    </method>
    <method name="Cancel">
      <arg type="s" direction="in"/>
    </method>
  </interface>
</node>
"""
ASKED_BY_METHOD = {
    "RequestPassphrase": ("passphrase", 1),
    "RequestPrivateKeyPassphrase": ("key", 1),
    "RequestUserNameAndPassword": ("identity", 2),
    "RequestUserPassword": ("password", 1),
}


def say(line):
    print(line, flush=True)


class Answers:
    def __init__(self):
        self.lines = []
        self.waiting = None
        channel = GLib.IOChannel.unix_new(sys.stdin.fileno())
        GLib.io_add_watch(channel, GLib.PRIORITY_DEFAULT, GLib.IOCondition.IN | GLib.IOCondition.HUP, self.read)

    def read(self, channel, condition):
        status, line, length, terminator = channel.read_line()
        if status != GLib.IOStatus.NORMAL:
            self.cancel()
            return False
        self.lines.append(line.rstrip("\n"))
        self.deliver()
        return True

    def ask(self, kind, count, invocation):
        self.cancel()
        self.lines = []
        self.waiting = (count, invocation)
        say("ask " + kind)

    def deliver(self):
        if self.waiting is None or len(self.lines) < self.waiting[0]:
            return
        count, invocation = self.waiting
        values = self.lines[:count]
        self.lines = self.lines[count:]
        self.waiting = None
        invocation.return_value(GLib.Variant("(" + "s" * count + ")", tuple(values)))

    def cancel(self):
        if self.waiting is not None:
            self.waiting[1].return_dbus_error(CANCELED, "canceled")
            self.waiting = None


def read_identity():
    say("ask identity")
    user = sys.stdin.readline().rstrip("\n").replace("\r", "")
    password = sys.stdin.readline().rstrip("\n").replace("\r", "")
    return user, password


def provisioning_path(ssid):
    if PLAIN_NAME.match(ssid):
        name = ssid
    else:
        name = "=" + ssid.encode("utf-8").hex()
    return IWD_STORAGE + name + ".8021x"


def provisioning_text(user, password):
    return "\n".join([
        "[Security]",
        "EAP-Method=PEAP",
        "EAP-Identity=" + user,
        "EAP-PEAP-Phase2-Method=MSCHAPV2",
        "EAP-PEAP-Phase2-Identity=" + user,
        "EAP-PEAP-Phase2-Password=" + password,
        "",
        "[Settings]",
        "AutoConnect=true",
        "",
    ])


def provision_iwd(ssid, user, password):
    command = ["pkexec", "/usr/bin/sh", "-c", 'umask 077 && cat > "$1"', "sh", provisioning_path(ssid)]
    try:
        result = subprocess.run(command, input=provisioning_text(user, password), capture_output=True, text=True)
    except FileNotFoundError:
        return "failed admin"
    if result.returncode == 0:
        return None
    if any(message in result.stderr for message in NO_AGENT):
        return "failed admin"
    if result.returncode == PKEXEC_DISMISSED:
        return "failed canceled"
    return "failed error"


def iwd_objects(bus):
    return bus.call_sync(IWD, "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects", None, None, Gio.DBusCallFlags.NONE, -1, None).unpack()[0]


def find_network(objects, station, ssid):
    return next(((path, interfaces["net.connman.iwd.Network"]) for path, interfaces in objects.items() if interfaces.get("net.connman.iwd.Network", {}).get("Name") == ssid and interfaces["net.connman.iwd.Network"].get("Device") == station), (None, {}))


def wait_until_known(bus, station, ssid):
    deadline = time.monotonic() + KNOWN_WAIT_SECONDS
    while time.monotonic() < deadline:
        if "KnownNetwork" in find_network(iwd_objects(bus), station, ssid)[1]:
            return
        time.sleep(KNOWN_POLL_SECONDS)


def remote_name(error):
    return Gio.DBusError.get_remote_error(error) or ""


def failure_reason(error, was_asked, is_enterprise):
    name = remote_name(error)
    if is_enterprise and name.endswith("Failed"):
        return "failed wrong"
    if name.endswith("AlreadyConnected"):
        return "connected"
    if name.endswith("NotFound"):
        return "failed missing"
    if name.endswith("Aborted") or name.endswith("Canceled"):
        return "failed canceled"
    if was_asked and (name.endswith("Failed") or name.endswith("InvalidFormat")):
        return "failed wrong"
    return "failed error"


def connect_iwd(device, ssid, is_hidden, is_again):
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    objects = iwd_objects(bus)
    station = next((path for path, interfaces in objects.items() if "net.connman.iwd.Station" in interfaces and interfaces.get("net.connman.iwd.Device", {}).get("Name") == device), None)
    if station is None:
        say("failed missing")
        return
    properties = find_network(objects, station, ssid)[1]
    is_enterprise = properties.get("Type") == "8021x"
    if is_enterprise and (is_again or "KnownNetwork" not in properties):
        user, password = read_identity()
        failure = provision_iwd(ssid, user, password)
        if failure is not None:
            say(failure)
            return
        wait_until_known(bus, station, ssid)
        objects = iwd_objects(bus)
    loop = GLib.MainLoop()
    answers = Answers()
    asked = {"any": False}

    def handle(connection, sender, path, interface, method, parameters, invocation):
        if method in ASKED_BY_METHOD:
            kind, count = ASKED_BY_METHOD[method]
            asked["any"] = True
            answers.ask(kind, count, invocation)
            return
        if method == "Cancel":
            answers.cancel()
            say("cancel")
        invocation.return_value(None)

    node = Gio.DBusNodeInfo.new_for_xml(AGENT_INTERFACE)
    bus.register_object(AGENT_PATH, node.interfaces[0], handle, None, None)
    bus.call_sync(IWD, "/net/connman/iwd", "net.connman.iwd.AgentManager", "RegisterAgent", GLib.Variant("(o)", (AGENT_PATH,)), None, Gio.DBusCallFlags.NONE, -1, None)

    def finish(source, result):
        try:
            bus.call_finish(result)
            say("connected")
        except GLib.Error as error:
            if is_hidden and remote_name(error).endswith("NotHidden"):
                connect_visible()
                return
            say(failure_reason(error, asked["any"], is_enterprise))
        loop.quit()

    def connect_visible():
        network = find_network(objects, station, ssid)[0]
        if network is None:
            say("failed missing")
            loop.quit()
            return False
        bus.call(IWD, network, "net.connman.iwd.Network", "Connect", None, None, Gio.DBusCallFlags.NONE, FOREVER, None, finish)
        return True

    if is_hidden:
        bus.call(IWD, station, "net.connman.iwd.Station", "ConnectHiddenNetwork", GLib.Variant("(s)", (ssid,)), None, Gio.DBusCallFlags.NONE, FOREVER, None, finish)
    elif not connect_visible():
        return
    loop.run()


def is_known_to_nmcli(ssid):
    names = subprocess.run(["nmcli", "-t", "-f", "NAME", "connection", "show"], capture_output=True, text=True).stdout.split("\n")
    return ssid.replace(":", "\\:") in names


def connect_nmcli_enterprise(device, ssid, is_again):
    is_known = is_known_to_nmcli(ssid)
    if is_known and not is_again:
        return ["nmcli", "connection", "up", "id", ssid], ""
    user, password = read_identity()
    if is_known:
        subprocess.run(["nmcli", "connection", "modify", "id", ssid, "802-1x.identity", user], capture_output=True)
    else:
        command = ["nmcli", "connection", "add", "type", "wifi", "con-name", ssid, "ssid", ssid, "wifi-sec.key-mgmt", "wpa-eap", "802-1x.eap", "peap", "802-1x.phase2-auth", "mschapv2", "802-1x.identity", user]
        if device:
            command += ["ifname", device]
        subprocess.run(command, capture_output=True)
    return ["nmcli", "--ask", "connection", "up", "id", ssid], password


def connect_nmcli(device, ssid, is_hidden, security, is_again):
    secret = ""
    if security == "enterprise":
        command, secret = connect_nmcli_enterprise(device, ssid, is_again)
    elif is_known_to_nmcli(ssid):
        command = ["nmcli", "connection", "up", "id", ssid]
    else:
        command = ["nmcli", "--ask", "device", "wifi", "connect", ssid]
        if device:
            command += ["ifname", device]
        if is_hidden:
            command += ["hidden", "yes"]
        if security != "open" or is_hidden:
            say("ask passphrase")
            secret = sys.stdin.readline().rstrip("\n")
    result = subprocess.run(command, input=secret + "\n", capture_output=True, text=True)
    if result.returncode == 0:
        say("connected")
    elif "No network with SSID" in result.stderr:
        say("failed missing")
    elif "Secrets were required" in result.stderr or "password" in result.stderr.lower():
        say("failed wrong")
    else:
        say("failed error")


def main():
    if len(sys.argv) < 7 or sys.argv[1] != "connect":
        say("failed error")
        return
    backend, device, ssid = sys.argv[2], sys.argv[3], sys.argv[4]
    is_hidden = sys.argv[5] == "hidden"
    security = sys.argv[6]
    is_again = len(sys.argv) > 7 and sys.argv[7] == "again"
    try:
        if backend == "iwd":
            connect_iwd(device, ssid, is_hidden, is_again)
        else:
            connect_nmcli(device, ssid, is_hidden, security, is_again)
    except GLib.Error:
        say("failed error")


main()
