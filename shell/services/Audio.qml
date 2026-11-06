pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: audio

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool isReady: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool isMuted: sink?.audio?.muted ?? false

    function setVolume(value) {
        if (!sink?.audio)
            return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, value))
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted
    }

    PwObjectTracker {
        objects: [audio.sink]
    }
}
