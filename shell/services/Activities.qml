pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.config

Singleton {
    id: activities

    readonly property var keys: ["call", "media", "notifications", "tray"]
    readonly property var callApplications: ["discord", "vesktop", "webcord", "armcord", "webrtc voiceengine"]

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: pickPlayer(players)
    readonly property bool hasMedia: Config.data.services.mediaPlayer && player !== null && player.playbackState !== MprisPlaybackState.Stopped
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property string mediaSource: player?.identity ?? "Spotify"
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property real position: player?.position ?? 0
    readonly property real length: player?.length ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    readonly property var streams: Pipewire.nodes.values.filter(node => node.isStream)
    readonly property PwNode callInput: streams.find(node => isCallNode(node) && classOf(node) === "Stream/Input/Audio") ?? null
    readonly property PwNode callOutput: streams.find(node => isCallNode(node) && classOf(node) === "Stream/Output/Audio") ?? null
    readonly property bool isCalling: callInput !== null
    readonly property string callSource: "Discord"
    readonly property bool isMicMuted: callInput?.audio?.muted ?? false
    readonly property bool isDeafened: callOutput?.audio?.muted ?? false
    property int callSeconds: 0
    property real callSince: 0

    readonly property int notificationCount: Notifications.list.length
    readonly property int unreadCount: Notifications.unreadCount
    readonly property var trayItems: Tray.items

    readonly property var liveKeys: keys.filter(key => isLive(key))
    readonly property var order: liveKeys.concat(keys.filter(key => !isLive(key)))
    readonly property bool isAnyLive: liveKeys.length > 0

    function isLive(key) {
        if (key === "call")
            return isCalling
        if (key === "media")
            return hasMedia
        if (key === "notifications")
            return Notifications.hasUnread
        return false
    }

    function pickPlayer(candidates) {
        if (!candidates || candidates.length === 0)
            return null
        return candidates.find(candidate => candidate.isPlaying)
            ?? candidates.find(candidate => (candidate.identity ?? "").toLowerCase().includes("spotify"))
            ?? candidates[0]
    }

    function classOf(node) {
        return node.properties?.["media.class"] ?? ""
    }

    function isCallNode(node) {
        const properties = node.properties ?? {}
        const names = [properties["application.name"], properties["application.process.binary"], properties["node.name"], node.name]
            .filter(name => name)
            .join(" ")
            .toLowerCase()
        return callApplications.some(application => names.includes(application))
    }

    function togglePlaying() {
        if (player?.canTogglePlaying)
            player.togglePlaying()
    }

    function next() {
        if (player?.canGoNext)
            player.next()
    }

    function previous() {
        if (player?.canGoPrevious)
            player.previous()
    }

    function toggleMic() {
        if (callInput?.audio)
            callInput.audio.muted = !callInput.audio.muted
    }

    function toggleDeafen() {
        if (callOutput?.audio)
            callOutput.audio.muted = !callOutput.audio.muted
    }

    onIsCallingChanged: {
        callSince = isCalling ? Date.now() : 0
        callSeconds = 0
    }

    PwObjectTracker {
        objects: activities.streams
    }

    Timer {
        interval: Motion.activity.tick
        repeat: true
        running: activities.isPlaying || activities.isCalling
        onTriggered: {
            if (activities.isPlaying)
                activities.player.positionChanged()
            if (activities.isCalling)
                activities.callSeconds = Math.floor((Date.now() - activities.callSince) / 1000)
        }
    }
}
