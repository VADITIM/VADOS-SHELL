pragma Singleton
import QtQuick
import "../utils/Capture.js" as Shots
QtObject {
    property string defaultScreenshots: "/home/vadim/Pictures/Screenshots"
    property string defaultRecordings: "/home/vadim/Videos/Recordings"
    property string screenshotFolder: defaultScreenshots
    property string recordingFolder: defaultRecordings
    property string shootingScreen: ""
    property bool isShooting: false
    property int frameStamp: 0
    property string lastScreenshot: ""
    property var recorder: Shots.recorders[0]
    readonly property bool canRecord: recorder !== null
    readonly property bool canPause: recorder?.canPause ?? false
    property bool isRecording: false
    property string recordingScreen: ""
    property string recordingFile: ""
    property bool isPaused: false
    property int seconds: 0
    readonly property string clock: Shots.clockOf(seconds)
    property var delivered: []
    signal shot(string screenName)
    function frameOf(screenName) { return "" }
    function cutPath() { return "" }
    function shoot(screenName) { shootingScreen = screenName; frameStamp++; shot(screenName) }
    function deliver(file) { delivered = delivered.concat([file]) }
    function toggleRecording(screenName) { if (isRecording) stop(); else record(screenName) }
    function record(screenName) { if (isRecording || !recorder) return; recordingScreen = screenName; isPaused = false; seconds = 0; isRecording = true }
    function togglePause() { if (isRecording && canPause) isPaused = !isPaused }
    function stop() { isRecording = false; isPaused = false }
    property Timer ticker: Timer {
        interval: 1000; repeat: true; running: isRecording && !isPaused
        onTriggered: seconds++
    }
}
