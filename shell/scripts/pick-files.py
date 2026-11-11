import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

PORTAL = "org.freedesktop.portal.Desktop"
ACCEPTED = 0


def main():
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    sender = bus.get_unique_name()[1:].replace(".", "_")
    token = "vados" + str(GLib.random_int())
    request = "/org/freedesktop/portal/desktop/request/" + sender + "/" + token
    loop = GLib.MainLoop()

    def respond(connection, sender_name, object_path, interface, signal, parameters):
        response, results = parameters.unpack()
        if response == ACCEPTED:
            for uri in results.get("uris", []):
                path = Gio.File.new_for_uri(uri).get_path()
                if path:
                    print(path, flush=True)
        loop.quit()

    bus.signal_subscribe(PORTAL, "org.freedesktop.portal.Request", "Response", request, None, Gio.DBusSignalFlags.NONE, respond)
    title = sys.argv[1] if len(sys.argv) > 1 else "Choose files"
    is_picture = len(sys.argv) > 2 and sys.argv[2] == "picture"
    options = {"handle_token": GLib.Variant("s", token), "multiple": GLib.Variant("b", not is_picture)}
    if is_picture:
        pictures = ("Pictures", [(1, "image/*")])
        options["filters"] = GLib.Variant("a(sa(us))", [pictures])
        options["current_filter"] = GLib.Variant("(sa(us))", pictures)
    bus.call_sync(PORTAL, "/org/freedesktop/portal/desktop", "org.freedesktop.portal.FileChooser", "OpenFile", GLib.Variant("(ssa{sv})", ("", title, options)), None, Gio.DBusCallFlags.NONE, -1, None)
    loop.run()


main()
