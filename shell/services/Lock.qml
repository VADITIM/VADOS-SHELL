pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import "../utils/Locking.js" as Locking
import "../utils/Log.js" as Log

Singleton {
    id: locker

    readonly property bool canLock: Compositor.capabilities.sessionLock
    property bool isLocking: false
    property bool isLocked: false
    property bool isSecure: false
    property bool isChecking: false
    property string screenName: ""
    property string message: ""
    property bool isMessageError: false
    property int failures: 0
    property string response: ""
    property string bootId: ""
    property bool hasRecovered: false
    readonly property string sessionKey: Locking.sessionKey(bootId, Quickshell.env("XDG_SESSION_ID"))
    readonly property int blankAfter: Config.data.lock.blankAfter
    readonly property int sleepAfter: Config.data.lock.sleepAfter
    readonly property bool isBlank: idle.enabled && idle.isIdle
    readonly property bool isAsleep: rest.enabled && rest.isIdle
    readonly property string status: !canLock ? "unsupported" : isLocking ? "locking" : !isLocked ? "unlocked" : isBlank ? "blank" : isSecure ? "locked" : "locking"

    signal unlocked()

    function request() {
        if (isLocked || isLocking)
            return true
        if (!canLock)
            return false
        if (Motion.isReduced)
            return lock()
        prepare()
        isLocking = true
        engageWait.restart()
        Log.info("lock", "locking the session once the lock screen covers it, modules on " + (screenName || "the first screen"))
        return true
    }

    function prepare() {
        screenName = Compositor.focusedScreen
        message = ""
        isMessageError = false
        failures = 0
        Quickshell.watchFiles = false
        remember(true)
    }

    function lock() {
        if (isLocked)
            return true
        engageWait.stop()
        if (!canLock) {
            if (isLocking) {
                isLocking = false
                remember(false)
                Quickshell.watchFiles = true
                Log.warn("lock", "the compositor lost the session lock before it engaged, showing the desktop")
            }
            return false
        }
        if (!isLocking)
            prepare()
        isLocking = false
        isLocked = true
        Log.info("lock", "locking the session, modules on " + (screenName || "the first screen"))
        return true
    }

    function submit(password) {
        if (!isLocked || isChecking || password.length === 0)
            return
        response = password
        message = ""
        isMessageError = false
        isChecking = true
        patience.restart()
        if (!pam.start())
            fail("startFailed", "PAM did not start (config " + pam.config + ")")
    }

    function answer() {
        if (!isChecking)
            return
        if (!pam.responseRequired) {
            if (pam.message.length > 0) {
                message = pam.message
                isMessageError = pam.messageIsError
            }
            return
        }
        if (response.length === 0) {
            fail("error", "PAM asked a second question the lock cannot answer (" + pam.message + ")")
            pam.abort()
            return
        }
        const given = response
        response = ""
        pam.respond(given)
    }

    function finish(result) {
        if (!isChecking)
            return
        if (result === PamResult.Success) {
            patience.stop()
            isChecking = false
            response = ""
            release("unlocked")
            return
        }
        if (result === PamResult.Failed) {
            failures += 1
            fail("failed", "wrong password (attempt " + failures + ")")
            return
        }
        if (result === PamResult.MaxTries) {
            fail("maxTries", "PAM refused after too many attempts")
            return
        }
        fail("error", "PAM reported an error")
    }

    function fail(kind, detail) {
        if (!isChecking)
            return
        patience.stop()
        isChecking = false
        response = ""
        message = Locking.failureOf(kind)
        isMessageError = true
        Log.warn("lock", detail + ", the session stays locked")
    }

    function release(reason) {
        if (!isLocked)
            return
        isLocked = false
        isSecure = false
        isChecking = false
        response = ""
        message = ""
        isMessageError = false
        failures = 0
        remember(false)
        Quickshell.watchFiles = true
        Log.info("lock", "session " + reason)
        unlocked()
    }

    function reportSecure(isConfirmed) {
        if (isSecure === isConfirmed)
            return
        isSecure = isConfirmed && isLocked
        if (isSecure)
            Log.info("lock", "the compositor confirmed the lock")
    }

    function reportLost() {
        if (!isLocked)
            return
        Log.warn("lock", "the compositor ended or refused the session lock, showing the desktop")
        release("lost")
    }

    function remember(isOn) {
        marker.update({ isLocked: isOn, session: sessionKey })
        marker.flush()
    }

    function recover() {
        if (hasRecovered || !marker.isLoaded || sessionKey.length === 0 || !canLock)
            return
        hasRecovered = true
        if (!Locking.shouldRecover(marker.values, sessionKey))
            return
        Log.warn("lock", "the shell started while this session was locked, locking again")
        locker.lock()
    }

    onCanLockChanged: recover()
    onSessionKeyChanged: recover()
    onIsBlankChanged: {
        Log.info("lock", isBlank ? "no input for " + blankAfter + " s, switching the displays off" : "input again, switching the displays on")
        Compositor.powerDisplays(!isBlank)
    }

    onIsAsleepChanged: {
        if (!isAsleep)
            return
        Log.info("lock", "no input for " + (blankAfter + sleepAfter) + " s on the lock screen, hibernating (suspending where hibernation is unavailable)")
        Power.hibernate()
    }

    StateFile {
        id: marker
        name: "lock"
        defaults: ({ isLocked: false, session: "" })
        onIsLoadedChanged: locker.recover()
    }

    FileView {
        id: bootFile
        path: "/proc/sys/kernel/random/boot_id"
        printErrors: false
        onLoaded: locker.bootId = text().trim()
    }

    PamContext {
        id: pam
        objectName: "pam"
        config: "login"
        onPamMessage: locker.answer()
        onCompleted: result => locker.finish(result)
        onError: error => locker.fail("error", "PAM failed (" + error + ")")
    }

    IdleMonitor {
        id: idle
        objectName: "idle"
        enabled: locker.isSecure && locker.blankAfter > 0
        timeout: Math.max(1, locker.blankAfter)
        respectInhibitors: false
    }

    IdleMonitor {
        id: rest
        objectName: "rest"
        enabled: locker.isSecure && locker.sleepAfter > 0
        timeout: Math.max(1, locker.blankAfter + locker.sleepAfter)
        respectInhibitors: true
    }

    Timer {
        id: engageWait
        objectName: "engageWait"
        interval: Motion.lock.engageWait
        onTriggered: {
            Log.warn("lock", "the lock screen did not report covering every screen in " + interval + " ms, locking now")
            locker.lock()
        }
    }

    Timer {
        id: patience
        objectName: "patience"
        interval: Motion.lock.patience
        onTriggered: {
            locker.fail("timedOut", "PAM gave no answer in " + interval / 1000 + " s")
            pam.abort()
        }
    }
}
