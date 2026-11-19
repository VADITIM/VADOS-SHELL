import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.services

TestCase {
    name: "Lock"

    readonly property string markerPath: Quickshell.env("HOME") + "/.cache/vados/lock.json"
    property int unlockedCount: 0

    Connections {
        id: unlockWatch
        target: null
        ignoreUnknownSignals: true

        function onUnlocked() {
            unlockedCount += 1
        }
    }

    Component.onCompleted: {
        Compositor.isDriftwm = true
        unlockWatch.target = Lock
    }

    function part(name) {
        const found = findChild(Lock, name)
        verify(found !== null, name)
        return found
    }

    function marker() {
        const text = Quickshell.readFile(markerPath)
        return text.length > 0 ? JSON.parse(text).data : null
    }

    function cleanup() {
        const pam = part("pam")
        const patience = part("patience")
        if (Lock.isChecking)
            patience.interval = 50
        tryVerify(() => !Lock.isChecking, 3000)
        patience.interval = Motion.lock.patience
        pam.canStart = true
        pam.isAnswering = true
        Compositor.isDriftwm = true
        Config.setLockBlankAfter(60)
        Config.setReducedMotion(false)
        part("engageWait").interval = Motion.lock.engageWait
        if (Lock.isLocking)
            Lock.lock()
        if (Lock.isLocked) {
            Lock.submit("secret")
            tryVerify(() => !Lock.isLocked, 3000)
        }
        unlockedCount = 0
    }

    function test_startsUnlockedAndLocksOnlyWhenAsked() {
        verify(!Lock.isLocked)
        verify(!Lock.isSecure)
        compare(Lock.status, "unlocked")
        verify(Quickshell.watchFiles)
        verify(Lock.lock())
        verify(Lock.isLocked)
        compare(marker().isLocked, true, "the lock is written at once, so a crash right after it recovers")
        verify(!Quickshell.watchFiles, "a reload while locked would unlock, so the shell stops watching its files")
        verify(Lock.lock(), "asking again keeps it locked")
    }

    function test_aRequestWaitsForTheLockScreenToCover() {
        verify(Lock.request())
        verify(Lock.isLocking)
        verify(!Lock.isLocked, "the session lock waits until the lock screen covers the desktop")
        compare(Lock.status, "locking")
        compare(marker().isLocked, true, "a crash during the enter still locks on the next start")
        verify(!Quickshell.watchFiles)
        verify(Lock.request(), "asking again keeps the one enter")
        verify(Lock.lock())
        verify(Lock.isLocked)
        verify(!Lock.isLocking)
    }

    function test_aRequestLocksEvenIfTheEnterNeverReports() {
        part("engageWait").interval = 60
        verify(Lock.request())
        verify(!Lock.isLocked)
        tryVerify(() => Lock.isLocked, 2000)
        verify(!Lock.isLocking)
    }

    function test_reducedMotionLocksAtOnce() {
        Config.setReducedMotion(true)
        verify(Lock.request())
        verify(Lock.isLocked)
        verify(!Lock.isLocking)
    }

    function test_aLockLostDuringTheEnterLetsGo() {
        verify(Lock.request())
        Compositor.isDriftwm = false
        verify(!Lock.lock())
        verify(!Lock.isLocking)
        verify(!Lock.isLocked)
        compare(marker().isLocked, false)
        verify(Quickshell.watchFiles)
    }

    function test_withoutTheCapabilityNothingLocks() {
        Compositor.isDriftwm = false
        verify(!Lock.canLock)
        verify(!Lock.lock())
        verify(!Lock.request())
        verify(!Lock.isLocked)
        verify(!Lock.isLocking)
        compare(Lock.status, "unsupported")
    }

    function test_wrongPasswordKeepsTheLockAndSaysSo() {
        Lock.lock()
        Lock.submit("guess")
        verify(Lock.isChecking)
        tryVerify(() => !Lock.isChecking, 3000)
        verify(Lock.isLocked)
        compare(Lock.message, "WRONG PASSWORD")
        verify(Lock.isMessageError)
        compare(Lock.failures, 1)
        compare(unlockedCount, 0)
        compare(marker().isLocked, true)
    }

    function test_rightPasswordUnlocksAtOnce() {
        Lock.lock()
        Lock.reportSecure(true)
        verify(Lock.isSecure)
        Lock.submit("secret")
        tryVerify(() => !Lock.isLocked, 3000)
        verify(!Lock.isSecure)
        compare(unlockedCount, 1)
        compare(Lock.message, "")
        compare(marker().isLocked, false)
        verify(Quickshell.watchFiles)
    }

    function test_emptyOrUnlockedSubmitsAreIgnored() {
        Lock.submit("secret")
        verify(!Lock.isChecking, "nothing to unlock")
        Lock.lock()
        Lock.submit("")
        verify(!Lock.isChecking, "an empty password never reaches PAM")
    }

    function test_onlyOneCheckRunsAtOnce() {
        const pam = part("pam")
        pam.isAnswering = false
        part("patience").interval = 300
        const before = pam.responses
        Lock.lock()
        Lock.submit("secret")
        Lock.submit("other")
        tryVerify(() => pam.responses > before, 2000)
        wait(50)
        compare(pam.responses, before + 1, "a second submit while checking is ignored")
        tryVerify(() => !Lock.isChecking, 2000)
        compare(Lock.message, "AUTHENTICATION TIMED OUT", "PAM that never answers gives the field back")
        verify(Lock.isLocked)
        verify(!pam.active, "the stuck conversation is aborted")
    }

    function test_pamThatCannotStartIsShown() {
        part("pam").canStart = false
        Lock.lock()
        Lock.submit("secret")
        verify(!Lock.isChecking)
        compare(Lock.message, "AUTHENTICATION COULD NOT START")
        verify(Lock.isLocked, "a PAM failure never unlocks")
    }

    function test_lostLockFollowsTheCompositor() {
        Lock.lock()
        Lock.reportLost()
        verify(!Lock.isLocked)
        compare(marker().isLocked, false)
        verify(Quickshell.watchFiles)
    }

    function test_blanksOnlyWhileSecurelyLocked() {
        const idle = part("idle")
        Config.setLockBlankAfter(1)
        Lock.lock()
        verify(!idle.enabled, "no idle timer before the compositor confirms the lock")
        Lock.reportSecure(true)
        verify(idle.enabled)
        compare(idle.timeout, 1)
        const before = Compositor.powered.length
        tryVerify(() => Lock.isBlank, 3000)
        compare(Lock.status, "blank")
        compare(Compositor.powered[Compositor.powered.length - 1], false)
        idle.touch()
        verify(!Lock.isBlank, "input wakes the screen to the lock")
        compare(Compositor.powered[Compositor.powered.length - 1], true)
        compare(Compositor.powered.length, before + 2)
        Lock.submit("secret")
        tryVerify(() => !Lock.isLocked, 3000)
        verify(!idle.enabled, "the unlocked desktop never blanks")
    }

    function test_hibernatesAfterTheScreenWentOff() {
        const rest = part("rest")
        Config.setLockBlankAfter(1)
        Config.setLockSleepAfter(1)
        Lock.lock()
        verify(!rest.enabled, "no sleep before the compositor confirms the lock")
        Lock.reportSecure(true)
        compare(rest.timeout, 2)
        verify(rest.respectInhibitors, "a playing video holds the sleep off")
        const before = Power.hibernated
        tryVerify(() => Lock.isAsleep, 4000)
        compare(Power.hibernated, before + 1)
        rest.touch()
        Lock.submit("secret")
        tryVerify(() => !Lock.isLocked, 3000)
        verify(!rest.enabled, "the unlocked desktop never sleeps on its own")
        Config.setLockSleepAfter(300)
    }

    function test_zeroNeverSleeps() {
        Config.setLockSleepAfter(0)
        Lock.lock()
        Lock.reportSecure(true)
        verify(!part("rest").enabled)
        Config.setLockSleepAfter(300)
    }

    function test_zeroNeverBlanks() {
        Config.setLockBlankAfter(0)
        Lock.lock()
        Lock.reportSecure(true)
        verify(!part("idle").enabled)
    }
}
