import QtQuick
import QtTest
import "../../shell/utils/Senders.js" as Senders

TestCase {
    name: "Senders"

    function test_everySenderHasItsFields() {
        for (const sender of Senders.senders) {
            verify(sender.key.length > 0)
            verify(sender.name.length > 0)
            verify(sender.binary.length > 0)
            verify(Senders.sendCommand(sender, "peer", "/tmp/a.txt").length > 0, sender.key + " builds a send command")
        }
    }

    function test_blipSendsToAPeerOrOpensItsOwnWindow() {
        const blip = Senders.byKey("blip")
        compare(Senders.sendCommand(blip, "phone", "/home/me/a b.png"), ["blip", "--peer=phone", "--file=/home/me/a b.png"])
        compare(Senders.sendCommand(blip, "", "/home/me/a.png"), ["blip", "--file=/home/me/a.png"])
    }

    function test_devicesAreNameAndPeer() {
        const devices = Senders.devicesOf(["Phone:pixel-8", "Laptop : work:42", "broken", ":nameless", "Empty:"])
        compare(devices.length, 2)
        compare(devices[0].name, "Phone")
        compare(devices[0].peer, "pixel-8")
        compare(devices[1].name, "Laptop")
        compare(devices[1].peer, "work:42", "a peer may hold a colon")
    }

    function test_nextCyclesOnlyInstalledApps() {
        compare(Senders.nextOf(["blip"], "blip"), "blip")
        compare(Senders.nextOf([], "blip"), "blip", "nothing installed keeps the choice")
    }
}
