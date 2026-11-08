pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../utils/Platform.js" as Platform

Singleton {
    id: compositor

    readonly property bool isHyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== null && Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== ""
    property bool isDriftwm: false
    readonly property string name: isHyprland ? "hyprland" : isDriftwm ? "driftwm" : "generic"
    readonly property var capabilities: Platform.capabilitiesOf(name)
    readonly property string level: Platform.levelOf(capabilities)

    property var canvasState: null
    property var activeWindow: null
    property string focusedScreen: Quickshell.screens[0]?.name ?? ""
    property string monitorsText: ""
    property bool hasNoCanvas: false
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
        const focused = (state.windows ?? []).find(window => window.is_focused)
        if (!focused || !focusedOutput) {
            activeWindow = null
        } else {
            const home = outputs.find(viewport => {
                const rectangle = toScreen(focused, viewport)
                const middleX = rectangle.x + rectangle.width / 2
                const middleY = rectangle.y + rectangle.height / 2
                return middleX >= 0 && middleX <= viewport.width && middleY >= 0 && middleY <= viewport.height
            }) ?? focusedOutput
            const rectangle = toScreen(focused, home)
            activeWindow = {
                id: focused.id,
                appId: focused.app_id ?? "",
                screen: home.name,
                x: rectangle.x,
                y: rectangle.y,
                width: rectangle.width,
                height: rectangle.height,
                isFullscreen: isListed(state.fullscreen, focused.id)
            }
        }
        canvasChanged()
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
