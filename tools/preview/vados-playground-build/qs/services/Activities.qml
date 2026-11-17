pragma Singleton
import QtQuick
QtObject {
    readonly property var keys: ["recording", "call", "media", "notifications", "tray"]
    readonly property int notificationCount: Notifications.list.length
    readonly property int unreadCount: Notifications.unreadCount
    readonly property var trayItems: Tray.items
    property bool hasMedia: true
    property bool isPlaying: true
    property string mediaSource: "Spotify"
    property var tracks: [["Midnight City", "M83"], ["Teardrop", "Massive Attack"], ["Windowlicker", "Aphex Twin"]]
    property int track: 0
    readonly property string title: tracks[track][0]
    readonly property string artist: tracks[track][1]
    property string artUrl: ""
    property real length: 243
    property real position: 61
    readonly property real progress: length > 0 ? position / length : 0
    property bool isCalling: true
    property string callSource: "Discord"
    property bool isMicMuted: false
    property bool isDeafened: false
    property int callSeconds: 754
    readonly property var liveKeys: keys.filter(key => isLive(key))
    readonly property var order: liveKeys.concat(keys.filter(key => !isLive(key) && key !== "recording"))
    readonly property bool isAnyLive: liveKeys.length > 0
    function isLive(key) { return key === "recording" ? Capture.isRecording : key === "call" ? isCalling : key === "media" ? hasMedia : key === "notifications" ? Notifications.hasUnread : false }
    function togglePlaying() { isPlaying = !isPlaying }
    function next() { track = (track + 1) % tracks.length; position = 0 }
    function previous() { track = (track + tracks.length - 1) % tracks.length; position = 0 }
    function toggleMic() { isMicMuted = !isMicMuted }
    function toggleDeafen() { isDeafened = !isDeafened }
    property Timer ticker: Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            if (isPlaying) position = (position + 1) % length
            if (isCalling) callSeconds++
        }
    }
}
