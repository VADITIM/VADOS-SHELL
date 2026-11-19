pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import "../utils/Displays.js" as Displays
import "../utils/Log.js" as Log
import "../utils/Platform.js" as Platform
import "../utils/Toml.js" as Toml
import "../utils/Keyboards.js" as KeyboardLayouts

Singleton {
    id: compositor

    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== null && Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    property bool isDriftwm: false
    readonly property string name: isHyprland ? "hyprland" : isDriftwm ? "driftwm" : "generic"
    readonly property string label: isHyprland ? "HYPRLAND" : isDriftwm ? "DRIFTWM" : "WAYLAND"
    readonly property var capabilities: Platform.capabilitiesOf(name)
    readonly property string level: Platform.levelOf(capabilities)

    property var canvasState: null
    property var activeWindow: null
    property var lastWindow: null
    property var windows: []
    property string focusedScreen: Quickshell.screens[0]?.name ?? ""
    property string monitorsText: ""
    property bool hasNoCanvas: false
    property bool hasSettings: false
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property string settingsPath: configHome + "/driftwm/config.toml"
    readonly property string hyprlandOutputsPath: configHome + "/hypr/vados-displays.conf"
    readonly property string hyprlandKeyboardsPath: configHome + "/hypr/vados-keyboards.conf"
    property bool isWatchingOutputs: false
    property var outputs: []
    property var outputTrial: Displays.idle()
    property real trialNow: 0
    readonly property int outputTrialLeft: Displays.remaining(outputTrial, trialNow)
    property bool hasRecoveredOutputs: false
    readonly property bool canRecoverOutputs: outputStore.isLoaded && (isHyprland || (isDriftwm && hasSettings))
    readonly property var hyprlandEvents: [
        "openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2",
        "focusedmon", "focusedmonv2", "changefloatingmode", "fullscreen", "activewindowv2",
        "moveworkspace", "moveworkspacev2", "activespecial", "activespecialv2", "minimized", "resizewindow"
    ]

    signal canvasChanged()

    function isListed(value, windowId) {
        if (value === null || value === undefined || value === false)
            return false
        if (typeof value === "number")
            return value === windowId
        if (Array.isArray(value))
            return value.some(entry => isListed(entry, windowId))
        if (typeof value === "object")
            return value.id === windowId || value.window === windowId || Object.values(value).some(entry => isListed(entry, windowId))
        return false
    }

    function viewportOf(output) {
        const camera = output.camera ?? canvasState?.camera ?? [0, 0]
        const size = output.size ?? [output.width ?? 0, output.height ?? 0]
        return { name: output.name ?? "", centerX: camera[0], centerY: camera[1], zoom: output.zoom ?? canvasState?.zoom ?? 1, width: size[0], height: size[1], isActive: output.active === true }
    }

    function toScreen(window, viewport) {
        const width = window.size[0] * viewport.zoom
        const height = window.size[1] * viewport.zoom
        const centerX = (window.position[0] - viewport.centerX) * viewport.zoom + viewport.width / 2
        const centerY = (viewport.centerY - window.position[1]) * viewport.zoom + viewport.height / 2
        return { x: centerX - width / 2, y: centerY - height / 2, width: width, height: height }
    }

    function viewports() {
        return (canvasState?.outputs ?? []).map(output => viewportOf(output))
    }

    function readCanvas(line) {
        let message
        try {
            message = JSON.parse(line)
        } catch (error) {
            return
        }
        const state = message.State ?? message.Ok?.State
        if (!state)
            return
        isDriftwm = true
        canvasState = state
        const outputs = viewports()
        const focusedOutput = outputs.find(viewport => viewport.isActive) ?? outputs[0]
        if (focusedOutput)
            focusedScreen = focusedOutput.name
        const windows = state.windows ?? []
        const focused = windows.find(window => window.is_focused)
        activeWindow = focused && focusedOutput ? describeCanvasWindow(focused, outputs, focusedOutput, state) : null
        const last = focused ?? windows.find(window => window.id === lastWindow?.id)
        lastWindow = last && focusedOutput ? describeCanvasWindow(last, outputs, focusedOutput, state) : null
        canvasChanged()
    }

    function describeCanvasWindow(window, outputs, fallback, state) {
        const home = outputs.find(viewport => {
            const rectangle = toScreen(window, viewport)
            const middleX = rectangle.x + rectangle.width / 2
            const middleY = rectangle.y + rectangle.height / 2
            return middleX >= 0 && middleX <= viewport.width && middleY >= 0 && middleY <= viewport.height
        }) ?? fallback
        const rectangle = toScreen(window, home)
        return {
            id: window.id,
            appId: window.app_id ?? "",
            screen: home.name,
            x: rectangle.x,
            y: rectangle.y,
            width: rectangle.width,
            height: rectangle.height,
            isFullscreen: isListed(state.fullscreen, window.id)
        }
    }

    function refreshWindows() {
        if (!capabilities.windowGeometry)
            windows = []
        else if (isHyprland)
            clientQuery.running = true
        else
            windows = describeCanvasWindows()
    }

    function describeCanvasWindows() {
        const state = canvasState
        const outputs = viewports()
        if (!state || outputs.length === 0)
            return []
        return (state.windows ?? []).map(window => describeCanvasWindow(window, outputs, outputs[0], state))
    }

    function readHyprlandWindows(clientText) {
        let monitors
        let clients
        try {
            monitors = JSON.parse(monitorsText)
            clients = JSON.parse(clientText)
        } catch (error) {
            windows = []
            return
        }
        windows = clients.flatMap(client => {
            const monitor = monitors.find(candidate => candidate.id === client.monitor)
            if (!monitor || !client.mapped || client.hidden || client.workspace?.id !== monitor.activeWorkspace?.id)
                return []
            return [{ id: client.address, appId: client.class ?? "", screen: monitor.name, x: client.at[0] - monitor.x, y: client.at[1] - monitor.y, width: client.size[0], height: client.size[1], isFullscreen: (client.fullscreen ?? 0) > 0 }]
        })
    }

    function windowsOn(screenName) {
        return windows.filter(window => window.screen === screenName)
    }

    function readHyprland(windowText) {
        let monitors
        let window
        try {
            monitors = JSON.parse(monitorsText)
            window = JSON.parse(windowText)
        } catch (error) {
            return
        }
        if (!window || !window.at || window.hidden) {
            activeWindow = null
            return
        }
        const monitor = monitors.find(candidate => candidate.id === window.monitor)
        if (!monitor) {
            activeWindow = null
            return
        }
        activeWindow = {
            id: window.address,
            appId: window.class ?? "",
            screen: monitor.name,
            x: window.at[0] - monitor.x,
            y: window.at[1] - monitor.y,
            width: window.size[0],
            height: window.size[1],
            isFullscreen: (window.fullscreen ?? 0) > 0
        }
    }

    function readGeneric() {
        const toplevel = ToplevelManager.activeToplevel
        if (!toplevel || !(toplevel.fullscreen || toplevel.maximized)) {
            activeWindow = null
            return
        }
        const screen = toplevel.screens?.[0] ?? Quickshell.screens[0]
        activeWindow = {
            id: 0,
            appId: toplevel.appId ?? "",
            screen: screen?.name ?? "",
            x: 0,
            y: 0,
            width: screen?.width ?? 0,
            height: screen?.height ?? 0,
            isFullscreen: toplevel.fullscreen
        }
    }

    function refreshHyprland() {
        if (!monitorQuery.running && !windowQuery.running)
            monitorQuery.running = true
    }

    function send(argumentsList) {
        if (capabilities.windowControl)
            Quickshell.execDetached(["driftwm", "msg"].concat(argumentsList))
    }

    function action(spec) {
        send(["action"].concat(spec.split(" ")))
    }

    function powerDisplays(isOn) {
        if (!capabilities.displayPower)
            return
        if (isHyprland)
            Quickshell.execDetached(["hyprctl", "dispatch", "dpms", isOn ? "on" : "off"])
        else
            Quickshell.execDetached(["wlopm", isOn ? "--on" : "--off", "*"])
    }

    function setBackground(path) {
        if (!isDriftwm || path.length === 0)
            return
        if (!hasSettings) {
            Log.warn("compositor", "cannot read " + settingsPath + ", the driftwm background stays as it is")
            return
        }
        const current = settingsFile.text()
        const next = Toml.withTable(current, "background", { type: "wallpaper", path: path })
        if (next !== current)
            settingsFile.setText(next)
    }

    function applyKeyboardLayouts(entries) {
        if (!capabilities.keyboardLayout)
            return false
        const requested = capabilities.deviceKeyboardLayout ? Array.from(entries ?? []) : KeyboardLayouts.overridesOf(entries).filter(entry => entry.device === KeyboardLayouts.everyKeyboard).map(KeyboardLayouts.encode)
        if (isHyprland) {
            hyprlandKeyboardsFile.setText(KeyboardLayouts.hyprlandConfig(requested))
            Quickshell.execDetached(["hyprctl", "reload"])
            Log.info("compositor", "wrote " + requested.length + " keyboard layouts to " + hyprlandKeyboardsPath + " and reloaded Hyprland")
            return true
        }
        if (!hasSettings) {
            Log.warn("compositor", "cannot read " + settingsPath + ", the keyboard layout stays as it is")
            return false
        }
        const before = settingsFile.text()
        const stored = keyboardStore.values.previous
        const hasOverride = KeyboardLayouts.overrideFor(requested, KeyboardLayouts.everyKeyboard) !== null
        if (hasOverride && !stored.isSaved)
            keyboardStore.update({ previous: Object.assign({ isSaved: true }, KeyboardLayouts.driftwmLayout(before)) })
        const previous = keyboardStore.values.previous
        const written = KeyboardLayouts.driftwmText(before, requested, previous.isSaved ? previous : null)
        if (!hasOverride)
            keyboardStore.update({ previous: { isSaved: false, layout: "", variant: "" } })
        keyboardStore.flush()
        if (written !== before)
            settingsFile.setText(written)
        Log.info("compositor", hasOverride ? "set the driftwm keyboard layout" : "put the driftwm keyboard layout back")
        return true
    }

    function readOutputs() {
        if (!capabilities.outputConfiguration)
            return
        if (isHyprland) {
            if (!hyprlandOutputQuery.running)
                hyprlandOutputQuery.running = true
        } else if (!headQuery.running) {
            headQuery.running = true
        }
    }

    function startTrial(trial) {
        outputTrial = trial
        trialNow = Date.now()
        outputStore.update({ trial: trial })
        outputStore.flush()
        outputSettle.restart()
    }

    function applyOutputs(requested) {
        if (!capabilities.outputConfiguration)
            return false
        const layout = Array.from(requested ?? [])
        const problem = Displays.problemOf(layout)
        if (problem.length > 0 || outputs.length === 0) {
            Log.warn("compositor", "refused an output layout (" + (problem || "no outputs read yet") + "), the outputs stay as they are")
            return false
        }
        const applied = Displays.normalized(layout)
        const now = Date.now()
        if (isHyprland) {
            startTrial(Displays.begun(outputTrial, outputs, applied, now, Motion.displays.keep, "", ""))
            Quickshell.execDetached(["hyprctl", "--batch", Displays.hyprlandBatch(applied)])
        } else {
            if (!hasSettings) {
                Log.warn("compositor", "cannot read " + settingsPath + ", the outputs stay as they are")
                return false
            }
            const before = settingsFile.text()
            const written = Displays.driftwmText(before, applied)
            startTrial(Displays.begun(outputTrial, outputs, applied, now, Motion.displays.keep, before, written))
            if (written !== before)
                settingsFile.setText(written)
        }
        Log.info("compositor", "applied a new output layout, the previous one comes back in " + Math.round(Motion.displays.keep / 1000) + " s unless it is kept")
        return true
    }

    function keepOutputs() {
        if (outputTrial.phase !== "trying")
            return
        if (isHyprland)
            hyprlandOutputsFile.setText(Displays.hyprlandConfig(outputTrial.applied))
        outputTrial = Displays.idle()
        outputStore.update({ trial: outputTrial })
        outputStore.flush()
        Log.info("compositor", "kept the new output layout")
    }

    function revertOutputs() {
        if (outputTrial.phase !== "trying")
            return
        const trial = outputTrial
        outputTrial = Displays.idle()
        outputStore.update({ trial: outputTrial })
        outputStore.flush()
        if (isHyprland) {
            Quickshell.execDetached(["hyprctl", "--batch", Displays.hyprlandBatch(trial.previous)])
        } else if (hasSettings) {
            const current = settingsFile.text()
            const next = Displays.revertText(current, trial)
            if (next !== current)
                settingsFile.setText(next)
        } else {
            Log.warn("compositor", "cannot read " + settingsPath + " to put the previous output layout back")
            return
        }
        Log.info("compositor", "the new output layout was not kept, the previous one is back")
        outputSettle.restart()
    }

    function recoverOutputs() {
        hasRecoveredOutputs = true
        const stored = outputStore.values.trial
        const action = Displays.recovery(stored, Date.now())
        if (action === "none")
            return
        outputTrial = stored
        trialNow = Date.now()
        if (action === "revert") {
            Log.warn("compositor", "found an output layout that was never kept, putting the previous one back")
            revertOutputs()
        } else {
            Log.info("compositor", "an output layout is still on trial, the previous one comes back in " + Math.round(outputTrialLeft / 1000) + " s unless it is kept")
        }
    }

    function readHeads(text) {
        let answer = null
        try {
            answer = JSON.parse(text)
        } catch (error) {
            Log.warn("compositor", "could not read the output heads, the Displays tab shows none")
            return
        }
        if (!answer.supported)
            Log.warn("compositor", "the compositor offers no output management" + (answer.error ? " (" + answer.error + ")" : "") + ", the Displays tab shows none")
        outputs = Displays.fromHeads(answer)
    }

    function readHyprlandOutputs(text) {
        try {
            outputs = Displays.fromHyprland(JSON.parse(text))
        } catch (error) {
            Log.warn("compositor", "could not read hyprctl monitors, the Displays tab shows none")
        }
    }

    onIsWatchingOutputsChanged: {
        if (isWatchingOutputs)
            readOutputs()
    }
    onCanRecoverOutputsChanged: {
        if (canRecoverOutputs && !hasRecoveredOutputs)
            recoverOutputs()
    }

    onActiveWindowChanged: {
        if (activeWindow && !isDriftwm)
            lastWindow = activeWindow
    }

    Component.onCompleted: {
        if (isHyprland)
            refreshHyprland()
    }

    Connections {
        target: Hyprland
        enabled: compositor.isHyprland

        function onRawEvent(event) {
            if (compositor.hyprlandEvents.includes(event.name))
                hyprlandSettle.restart()
        }

        function onFocusedMonitorChanged() {
            compositor.focusedScreen = Hyprland.focusedMonitor?.name ?? compositor.focusedScreen
        }
    }

    Connections {
        target: ToplevelManager
        enabled: !compositor.isHyprland && !compositor.isDriftwm

        function onActiveToplevelChanged() {
            compositor.readGeneric()
        }
    }

    Connections {
        target: ToplevelManager.activeToplevel
        enabled: !compositor.isHyprland && !compositor.isDriftwm
        ignoreUnknownSignals: true

        function onFullscreenChanged() {
            compositor.readGeneric()
        }

        function onMaximizedChanged() {
            compositor.readGeneric()
        }
    }

    Connections {
        target: Quickshell
        enabled: compositor.isWatchingOutputs

        function onScreensChanged() {
            compositor.readOutputs()
        }
    }

    Timer {
        interval: Motion.displays.tick
        running: compositor.outputTrial.phase === "trying"
        repeat: true
        onTriggered: {
            compositor.trialNow = Date.now()
            if (Displays.isExpired(compositor.outputTrial, compositor.trialNow))
                compositor.revertOutputs()
        }
    }

    Timer {
        id: outputSettle
        interval: Motion.displays.settle
        onTriggered: compositor.readOutputs()
    }

    StateFile {
        id: outputStore
        name: "displays"
        defaults: ({ trial: Displays.idle() })
    }

    StateFile {
        id: keyboardStore
        name: "keyboards"
        defaults: ({ previous: { isSaved: false, layout: "", variant: "" } })
    }

    FileView {
        id: hyprlandKeyboardsFile
        path: compositor.isHyprland ? compositor.hyprlandKeyboardsPath : ""
        printErrors: false
    }

    FileView {
        id: hyprlandOutputsFile
        path: compositor.isHyprland ? compositor.hyprlandOutputsPath : ""
        printErrors: false
    }

    Process {
        id: headQuery
        command: ["python3", Quickshell.shellPath("scripts/outputs.py")]
        stdout: StdioCollector {
            onStreamFinished: compositor.readHeads(text)
        }
    }

    Process {
        id: hyprlandOutputQuery
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: compositor.readHyprlandOutputs(text)
        }
    }

    Timer {
        id: hyprlandSettle
        interval: 60
        onTriggered: compositor.refreshHyprland()
    }

    Timer {
        interval: 2000
        running: compositor.isHyprland
        repeat: true
        onTriggered: compositor.refreshHyprland()
    }

    FileView {
        id: settingsFile
        path: compositor.isDriftwm ? compositor.settingsPath : ""
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: compositor.hasSettings = true
        onLoadFailed: compositor.hasSettings = false
        onSaved: compositor.action("reload-config")
    }

    Process {
        id: monitorQuery
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                compositor.monitorsText = text
                windowQuery.running = true
            }
        }
    }

    Process {
        id: clientQuery
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: compositor.readHyprlandWindows(text)
        }
    }

    Process {
        id: windowQuery
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: compositor.readHyprland(text)
        }
    }

    Process {
        id: canvasStream
        command: ["driftwm", "msg", "--json", "subscribe"]
        stdout: SplitParser {
            onRead: line => compositor.readCanvas(line)
        }
        onExited: {
            if (compositor.isDriftwm)
                return
            compositor.hasNoCanvas = true
            compositor.readGeneric()
        }
    }

    Supervisor {
        name: "compositor"
        process: canvasStream
        isActive: !compositor.isHyprland && !compositor.hasNoCanvas
    }
}
