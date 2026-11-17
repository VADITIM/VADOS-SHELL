pragma Singleton
import QtQuick
import Quickshell
import qs.config
import "../utils/Playing.js" as Playing
import "../utils/Log.js" as Log

Singleton {
    id: frameDebug

    property bool isActive: false
    property bool isStepping: false
    property bool isSnapping: false
    property bool isArmed: false
    property bool wasPlaying: false
    property string screenName: ""
    property string label: ""
    property int frame: 0
    property real advanced: 0
    property int pending: 0
    property int serial: 0
    property int cursor: -1
    property real memory: Motion.frames.memory
    property var history: []
    property var snapshot: null
    property var heldSnapshot: []

    readonly property bool isPlaying: label.length > 0
    readonly property bool isViewingPast: cursor >= 0 && cursor < history.length - 1
    readonly property var viewed: isViewingPast ? history[cursor] : null
    readonly property string counter: viewed ? viewed.counter + " REPLAY" : (isPlaying ? "FRAME " + frame : "HELD")
    readonly property string shownLabel: viewed ? viewed.label : label

    signal captureRequested(int token, real scale)
    signal snapshotReady(var shots)

    property FrameAnimation heartbeat: FrameAnimation {
        running: frameDebug.isActive
        onTriggered: frameDebug.beat()
    }

    property Timer fallback: Timer {
        interval: Motion.frames.stepTimeout
        onTriggered: frameDebug.expire()
    }

    function shotsOn(name) {
        return viewed ? viewed.shots.filter(shot => shot.screenName === name) : []
    }

    function toggle(name) {
        if (isActive)
            close()
        else
            begin(name)
    }

    function begin(name) {
        if (isActive)
            return
        screenName = name
        frame = 0
        wasPlaying = false
        isStepping = false
        history = []
        cursor = -1
        isActive = true
        Motion.isHeld = true
        refresh()
        Log.info("frames", "held, up steps one frame, down goes back, plus copies a screenshot, escape resumes")
    }

    function beat() {
        if (!isStepping) {
            refresh()
            return
        }
        if (!isArmed)
            return
        if (advanced >= Motion.frames.stepMinimum) {
            finishStep()
            return
        }
        advanced += heartbeat.frameTime * 1000
    }

    function refresh() {
        if (isStepping)
            return
        Motion.holdAgain()
        label = Playing.names().join(" + ")
        if (!wasPlaying)
            frame = 0
        if (isPlaying && !wasPlaying)
            capture()
        wasPlaying = isPlaying
    }

    function step() {
        if (!isActive || isStepping)
            return
        if (isViewingPast) {
            cursor++
            return
        }
        advanced = 0
        isArmed = false
        isStepping = true
        Motion.isHeld = false
        Qt.callLater(arm)
        fallback.restart()
    }

    function back() {
        if (isActive && !isStepping && cursor > 0)
            cursor--
    }

    function arm() {
        isArmed = isStepping
    }

    function finishStep() {
        if (!isStepping)
            return
        fallback.stop()
        Motion.isHeld = true
        isStepping = false
        isArmed = false
        const wasAnimating = isPlaying
        if (wasAnimating)
            frame++
        label = Playing.names().join(" + ")
        wasPlaying = isPlaying
        if (wasAnimating || isPlaying)
            capture()
    }

    function expire() {
        Log.warn("frames", "the frame clock stopped during a step, resumed by time instead")
        finishStep()
    }

    function release(entries) {
        for (const entry of entries) {
            for (const shot of entry.shots)
                shot.keeper?.destroy()
        }
    }

    function capture() {
        serial++
        const entry = { id: serial, counter: counter, label: label, shots: [] }
        history = history.concat([entry])
        cursor = history.length - 1
        trim()
        captureRequested(serial, Motion.frames.scale)
    }

    function weigh(entry) {
        return entry.shots.reduce((total, shot) => total + (shot.bytes ?? 0), 0)
    }

    function trim() {
        let total = history.reduce((sum, entry) => sum + weigh(entry), 0)
        let dropped = 0
        while (history.length - dropped > 1 && (history.length - dropped > Motion.frames.history || total > memory)) {
            total -= weigh(history[dropped])
            dropped++
        }
        if (dropped === 0)
            return
        release(history.slice(0, dropped))
        history = history.slice(dropped)
        cursor = Math.max(0, cursor - dropped)
    }

    function expect() {
        pending++
    }

    function skip() {
        pending = Math.max(0, pending - 1)
        settleSnapshot()
    }

    function store(token, shot) {
        if (snapshot && snapshot.id === token) {
            snapshot.shots = snapshot.shots.concat([shot])
        } else {
            const entry = history.find(candidate => candidate.id === token)
            if (entry) {
                entry.shots = entry.shots.concat([shot])
                history = history.slice()
                trim()
            } else {
                release([{ shots: [shot] }])
            }
        }
        skip()
    }

    function snap(name) {
        if (isSnapping)
            return
        isSnapping = true
        if (isViewingPast) {
            const shots = viewed.shots
            Qt.callLater(() => snapshotReady(shots))
            return
        }
        if (!isActive)
            screenName = name
        serial++
        snapshot = { id: serial, shots: [] }
        captureRequested(serial, 1)
        Qt.callLater(settleSnapshot)
    }

    function settleSnapshot() {
        if (!snapshot || pending > 0)
            return
        const shots = snapshot.shots
        snapshot = null
        heldSnapshot = shots
        snapshotReady(shots)
    }

    function finishSnap() {
        release([{ shots: heldSnapshot }])
        heldSnapshot = []
        isSnapping = false
    }

    function close() {
        fallback.stop()
        isStepping = false
        isArmed = false
        isActive = false
        Motion.isHeld = false
        label = ""
        frame = 0
        wasPlaying = false
        release(history)
        history = []
        cursor = -1
        pending = 0
    }
}
