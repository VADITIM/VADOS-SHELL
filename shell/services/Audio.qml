pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../utils/Controls.js" as Controls

Singleton {
    id: audio

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool isReady: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool isMuted: sink?.audio?.muted ?? false
    readonly property var nodes: Pipewire.nodes.values.filter(node => node.audio)
    readonly property var outputNodes: nodes.filter(node => node.isSink && !node.isStream)
    readonly property var inputNodes: nodes.filter(node => !node.isSink && !node.isStream)
    readonly property var streamNodes: nodes.filter(node => node.isSink && node.isStream)
    readonly property var outputs: outputNodes.map(node => rowOf(node, node === sink))
    readonly property var inputs: inputNodes.map(node => rowOf(node, node === source))
    readonly property var streams: streamNodes.map(node => rowOf(node, false))
    readonly property string tab: Controls.audioTabOf(store.values.tab ?? "")

    function rowOf(node, isDefault) {
        return {
            key: String(node.id),
            node: node,
            label: node.isStream ? Controls.streamLabel(node.properties, node.description, node.name) : Controls.deviceLabel(node.description, node.nickname, node.name),
            volume: node.audio.volume,
            isMuted: node.audio.muted,
            isDefault: isDefault
        }
    }

    function setVolume(value) {
        setRowVolume({ node: sink }, value)
    }

    function setRowVolume(row, value) {
        if (!row.node?.audio)
            return
        row.node.audio.muted = false
        row.node.audio.volume = Math.max(0, Math.min(1, value))
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted
    }

    function makeDefault(row) {
        if (row.node.isSink)
            Pipewire.preferredDefaultAudioSink = row.node
        else
            Pipewire.preferredDefaultAudioSource = row.node
    }

    function pickTab(key) {
        const next = Controls.audioTabOf(key)
        if (next !== tab)
            store.update(Object.assign({}, store.values, { tab: next }))
    }

    function route(stream, output) {
        Quickshell.execDetached(["pw-metadata", String(stream.node.id), "target.node", String(output.node.id), "Spa:Id"])
    }

    StateFile {
        id: store
        name: "audio"
        defaults: ({ tab: "output" })
    }

    PwObjectTracker {
        objects: audio.nodes.concat([audio.sink, audio.source])
    }
}
