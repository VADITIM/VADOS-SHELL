pragma Singleton
import QtQuick
import qs.config
import "../utils/Platform.js" as Platform
import "../utils/Displays.js" as Displays
QtObject {
    property bool isHyprland: false
    property bool isDriftwm: false
    readonly property string name: isHyprland ? "hyprland" : isDriftwm ? "driftwm" : "generic"
    readonly property var capabilities: Platform.capabilitiesOf(name)
    readonly property string level: Platform.levelOf(capabilities)
    property var canvasState: null
    property var activeWindow: null
    property var lastWindow: null
    property string focusedScreen: "play"
    property var sent: []
    signal canvasChanged()
    function isListed(value, windowId) { return false }
    function viewports() { return [] }
    function send(argumentsList) { sent = sent.concat([argumentsList.join(" ")]) }
    function action(spec) {}
    property var powered: []
    function powerDisplays(isOn) { if (capabilities.displayPower) powered = powered.concat([isOn]) }
    function setBackground(path) {}
    property bool isWatchingOutputs: false
    property var outputs: [
        { name: "eDP-1", description: "Built-in panel", make: "", model: "", x: 0, y: 0, scale: 1, transform: "normal", mode: { width: 1920, height: 1080, refresh: 144000 }, modes: [{ width: 1920, height: 1080, refresh: 144000, isPreferred: true }, { width: 1920, height: 1080, refresh: 60000, isPreferred: false }, { width: 1280, height: 720, refresh: 60000, isPreferred: false }] },
        { name: "DP-2", description: "Desk monitor", make: "", model: "", x: 1920, y: 0, scale: 1, transform: "normal", mode: { width: 2560, height: 1440, refresh: 60000 }, modes: [{ width: 2560, height: 1440, refresh: 60000, isPreferred: true }, { width: 1920, height: 1080, refresh: 60000, isPreferred: false }] }
    ]
    property var outputTrial: Displays.idle()
    property real trialNow: 0
    readonly property int outputTrialLeft: Displays.remaining(outputTrial, trialNow)
    property var appliedOutputs: []
    function readOutputs() {}
    function applyOutputs(layout) {
        if (!capabilities.outputConfiguration || Displays.problemOf(layout).length > 0)
            return false
        const applied = Displays.normalized(layout)
        appliedOutputs = appliedOutputs.concat([applied])
        trialNow = Date.now()
        outputTrial = Displays.begun(outputTrial, outputs, applied, trialNow, Motion.displays.keep, "", "")
        outputs = applied.map(entry => Object.assign({}, outputs.find(output => output.name === entry.name), entry))
        return true
    }
    function keepOutputs() { outputTrial = Displays.idle() }
    function revertOutputs() {
        if (outputTrial.phase !== "trying")
            return
        outputs = outputTrial.previous
        outputTrial = Displays.idle()
    }
}
