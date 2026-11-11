pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../utils/Capture.js" as Shots
import "../utils/Log.js" as Log

Singleton {
    id: capture

    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string picturesFolder: Quickshell.env("XDG_PICTURES_DIR") || home + "/Pictures"
    readonly property string videosFolder: Quickshell.env("XDG_VIDEOS_DIR") || home + "/Videos"
    readonly property string defaultScreenshots: Shots.folderOf("", home, picturesFolder, Shots.stillFolder)
    readonly property string defaultRecordings: Shots.folderOf("", home, videosFolder, Shots.motionFolder)
    readonly property string screenshotFolder: Shots.folderOf(Config.data.capture.screenshots, home, picturesFolder, Shots.stillFolder)
    readonly property string recordingFolder: Shots.folderOf(Config.data.capture.recordings, home, videosFolder, Shots.motionFolder)

    property string shootingScreen: ""
    readonly property bool isShooting: shooter.running
    property int frameStamp: 0
    property string lastScreenshot: ""

    property var recorder: null
    readonly property bool canRecord: recorder !== null
    readonly property bool canPause: recorder?.canPause ?? false
    readonly property bool isRecording: recording.running
    property string recordingScreen: ""
    property string recordingFile: ""
    property bool isPaused: false
    property int seconds: 0
    readonly property string clock: Shots.clockOf(seconds)

    signal shot(string screenName)

    function frameOf(screenName) {
        return Quickshell.cachePath("vados-shot-" + screenName + ".png")
    }

    function cutPath() {
        return Quickshell.cachePath("vados-shot-cut.png")
    }

    function shoot(screenName) {
        if (screenName.length === 0 || shooter.running)
            return
        shootingScreen = screenName
        shooter.command = ["sh", "-c", "mkdir -p -- \"$(dirname -- \"$2\")\" && exec grim -o \"$1\" \"$2\"", "sh", screenName, frameOf(screenName)]
        shooter.running = true
    }

    function deliver(file) {
        if (delivery.running) {
            Log.warn("capture", "a screenshot is still being saved, this one stays at " + file)
            return
        }
        const target = screenshotFolder + "/" + Shots.stillNameOf(new Date())
        lastScreenshot = target
        delivery.command = ["sh", "-c", "mkdir -p -- \"$(dirname -- \"$2\")\" && cp -- \"$1\" \"$2\" && wl-copy --type image/png < \"$1\"", "sh", file, target]
        delivery.running = true
    }

    function toggleRecording(screenName) {
        if (isRecording)
            stop()
        else
            record(screenName)
    }

    function record(screenName) {
        if (isRecording || screenName.length === 0)
            return
        if (!recorder) {
            Log.warn("capture", "no screen recorder found (install gpu-screen-recorder or wf-recorder), nothing is recorded")
            return
        }
        recordingFile = recordingFolder + "/" + Shots.motionNameOf(new Date())
        recordingScreen = screenName
        isPaused = false
        seconds = 0
        recording.command = ["sh", "-c", "mkdir -p -- \"$(dirname -- \"$1\")\" && shift && exec \"$@\"", "sh", recordingFile].concat(Shots.recordCommand(recorder, screenName, recordingFile))
        recording.running = true
        Log.info("capture", "recording " + screenName + " with " + recorder.key + " to " + recordingFile)
    }

    function togglePause() {
        if (!isRecording || !canPause)
            return
        recording.signal(Shots.pauseSignal)
        isPaused = !isPaused
    }

    function stop() {
        if (isRecording)
            recording.signal(Shots.stopSignal)
    }

    Process {
        id: shooter
        onExited: code => {
            if (code !== 0) {
                Log.warn("capture", "grim exited with code " + code + " on " + capture.shootingScreen + ", no screenshot is taken")
                return
            }
            capture.frameStamp++
            capture.shot(capture.shootingScreen)
        }
    }

    Process {
        id: delivery
        onExited: code => {
            if (code === 0)
                Log.info("capture", "screenshot copied to the clipboard and saved to " + capture.lastScreenshot)
            else
                Log.warn("capture", "saving or copying the screenshot exited with code " + code + ", it stays at " + capture.cutPath())
        }
    }

    Process {
        id: recording
        onExited: code => {
            capture.isPaused = false
            if (code === 0)
                Log.info("capture", "recording saved to " + capture.recordingFile)
            else
                Log.warn("capture", capture.recorder.key + " exited with code " + code + ", the recording may be incomplete at " + capture.recordingFile)
        }
    }

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "for name in \"$@\"; do command -v \"$name\" >/dev/null 2>&1 && echo \"$name\"; done", "sh"].concat(Shots.recorders.map(recorder => recorder.key))
        stdout: StdioCollector {
            onStreamFinished: capture.recorder = Shots.pickRecorder(text.split("\n"))
        }
    }

    Timer {
        interval: Motion.capture.tick
        repeat: true
        running: capture.isRecording && !capture.isPaused
        onTriggered: capture.seconds++
    }
}
