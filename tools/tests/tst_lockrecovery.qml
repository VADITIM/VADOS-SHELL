import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.services

TestCase {
    name: "LockRecovery"

    readonly property string markerPath: Quickshell.env("HOME") + "/.cache/vados/lock.json"
    property string bootId: ""

    Component.onCompleted: {
        Quickshell.environment = { XDG_SESSION_ID: "7" }
        bootId = Quickshell.readFile("/proc/sys/kernel/random/boot_id").trim()
        Quickshell.writeFile(markerPath, JSON.stringify({ version: 1, data: { isLocked: true, session: bootId + ":7" } }))
        Compositor.isDriftwm = true
    }

    function test_restartInsideTheLockedSessionLocksAgain() {
        verify(bootId.length > 0, "the boot id is readable")
        tryVerify(() => Lock.hasRecovered, 3000)
        verify(Lock.isLocked, "a shell that starts inside the session it locked locks again, so a crash never leaves a blank lock")
        verify(!Quickshell.watchFiles)
        Lock.submit("secret")
        tryVerify(() => !Lock.isLocked, 3000)
        compare(JSON.parse(Quickshell.readFile(markerPath)).data.isLocked, false)
    }
}
