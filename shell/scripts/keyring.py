import json
import sys

import gi

gi.require_version("Gcr", "4")
from gi.repository import Gcr, Gio, GLib

PROMPTER = "org.gnome.keyring.SystemPrompter"
PATH = "/org/gnome/keyring/Prompter"
INTERFACE = "org.gnome.keyring.internal.Prompter"
CALLBACK = "org.gnome.keyring.internal.Prompter.Callback"
FLAGS = ("choice-chosen", "password-new")
SHOWN = ("title", "message", "description", "warning", "choice-label", "choice-chosen", "password-new", "continue-label", "cancel-label")
NODE = Gio.DBusNodeInfo.new_for_xml(f"""
<node>
  <interface name="{INTERFACE}">
    <method name="BeginPrompting"><arg type="o" name="callback" direction="in"/></method>
    <method name="PerformPrompt">
      <arg type="o" name="callback" direction="in"/>
      <arg type="s" name="type" direction="in"/>
      <arg type="a{{sv}}" name="properties" direction="in"/>
      <arg type="s" name="exchange" direction="in"/>
    </method>
    <method name="StopPrompting"><arg type="o" name="callback" direction="in"/></method>
  </interface>
</node>
""")
PROMPTS = {}
COUNTER = [0]


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


class Prompt:
    def __init__(self, identity, caller, callback):
        self.identity = identity
        self.caller = caller
        self.callback = callback
        self.exchange = Gcr.SecretExchange.new(None)
        self.properties = {}
        self.kind = ""

    def ready(self, reply, changed, exchange):
        connection.call(
            self.caller, self.callback, CALLBACK, "PromptReady",
            GLib.Variant("(sa{sv}s)", (reply, changed, exchange)),
            None, Gio.DBusCallFlags.NONE, -1, None, None)

    def done(self):
        connection.call(self.caller, self.callback, CALLBACK, "PromptDone", None, None, Gio.DBusCallFlags.NONE, -1, None, None)

    def perform(self, kind, properties, exchange):
        self.kind = kind
        self.properties.update(properties)
        if exchange:
            self.exchange.receive(exchange)
        shown = {key.replace("-", "_"): self.properties.get(key, False if key in FLAGS else "") for key in SHOWN}
        send({"id": self.identity, "kind": kind, **shown})

    def answer(self, reply):
        is_continue = reply.get("reply") == "continue"
        changed = {}
        if "choice" in reply:
            self.properties["choice-chosen"] = reply["choice"] is True
            changed["choice-chosen"] = GLib.Variant("v", GLib.Variant("b", reply["choice"] is True))
        if is_continue and self.kind == "password":
            secret = self.exchange.send(reply.get("password", ""), -1)
        else:
            secret = ""
        self.kind = ""
        self.ready("yes" if is_continue else "no", changed, secret)


def handle(bus, sender, path, interface, method, parameters, invocation):
    callback = parameters.unpack()[0]
    key = sender + callback
    if method == "BeginPrompting":
        if key in PROMPTS:
            invocation.return_dbus_error("org.gnome.keyring.Prompter.InProgress", "Already begun prompting for this prompt callback")
            return
        COUNTER[0] += 1
        prompt = Prompt(COUNTER[0], sender, callback)
        PROMPTS[key] = prompt
        invocation.return_value(None)
        prompt.ready("", {}, prompt.exchange.begin())
    elif method == "PerformPrompt":
        prompt = PROMPTS.get(key)
        if prompt is None:
            invocation.return_dbus_error("org.freedesktop.DBus.Error.InvalidArgs", "Not begun prompting for this prompt callback")
            return
        _, kind, properties, exchange = parameters.unpack()
        invocation.return_value(None)
        prompt.perform(kind, properties, exchange)
    elif method == "StopPrompting":
        prompt = PROMPTS.pop(key, None)
        invocation.return_value(None)
        if prompt is not None:
            send({"id": prompt.identity, "kind": "close"})


def read_reply(channel, condition):
    line = sys.stdin.readline()
    if not line:
        for prompt in list(PROMPTS.values()):
            if prompt.kind:
                prompt.answer({"reply": "cancel"})
            prompt.done()
        loop.quit()
        return False
    try:
        reply = json.loads(line)
    except ValueError:
        return True
    for prompt in PROMPTS.values():
        if prompt.identity == reply.get("id") and prompt.kind:
            prompt.answer(reply)
    return True


def vanished(bus, sender, path, interface, signal, parameters):
    name, old, new = parameters.unpack()
    if new:
        return
    for key in [key for key, prompt in PROMPTS.items() if prompt.caller == name]:
        send({"id": PROMPTS.pop(key).identity, "kind": "close"})


def acquired(bus, name):
    send({"kind": "ready"})


def lost(bus, name):
    send({"kind": "lost"})
    loop.quit()


name = sys.argv[1] if len(sys.argv) > 1 else PROMPTER
loop = GLib.MainLoop()
connection = Gio.bus_get_sync(Gio.BusType.SESSION, None)
connection.register_object(PATH, NODE.interfaces[0], handle, None, None)
connection.signal_subscribe("org.freedesktop.DBus", "org.freedesktop.DBus", "NameOwnerChanged", "/org/freedesktop/DBus", None, Gio.DBusSignalFlags.NONE, vanished)
Gio.bus_own_name_on_connection(connection, name, Gio.BusNameOwnerFlags.DO_NOT_QUEUE, acquired, lost)
GLib.io_add_watch(GLib.IOChannel.unix_new(sys.stdin.fileno()), GLib.PRIORITY_DEFAULT, GLib.IOCondition.IN | GLib.IOCondition.HUP, read_reply)
loop.run()
