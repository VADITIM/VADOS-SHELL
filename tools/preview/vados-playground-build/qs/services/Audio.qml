pragma Singleton
import QtQuick
QtObject {
    property bool isReady: true
    property real volume: 0.64
    property bool isMuted: false
    property var outputs: [
        { key: "1", node: null, label: "Speakers", volume: 0.64, isMuted: false, isDefault: true },
        { key: "2", node: null, label: "Headphones", volume: 0.4, isMuted: false, isDefault: false }
    ]
    property var inputs: [{ key: "3", node: null, label: "Microphone", volume: 0.8, isMuted: false, isDefault: true }]
    property var streams: [
        { key: "4", node: null, label: "Spotify", volume: 0.7, isMuted: false, isDefault: false },
        { key: "5", node: null, label: "Discord", volume: 1, isMuted: false, isDefault: false }
    ]
    property var routed: []
    function setVolume(value) { isMuted = false; volume = Math.max(0, Math.min(1, value)) }
    function setRowVolume(row, value) {}
    function toggleMute() { isMuted = !isMuted }
    function makeDefault(row) { outputs = outputs.map(output => Object.assign({}, output, { isDefault: output.key === row.key })) }
    function route(stream, output) { routed = routed.concat([stream.label + ">" + output.label]) }
}
