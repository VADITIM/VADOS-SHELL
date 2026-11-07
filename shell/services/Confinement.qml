pragma Singleton
import QtQuick
import Quickshell
import qs.config

Singleton {
    id: confinement

    readonly property string mode: Config.data.desktop.mode
    readonly property bool canConfine: Compositor.capabilities.freeCanvas && Compositor.capabilities.windowControl
    readonly property bool isConfined: canConfine && mode === "desktop"
    readonly property var layout: Appearance.desktop

    property var home: null
    property var parked: ({})
    property var known: ({})
    property int cascade: 0
    property bool hasRecovered: false
    readonly property bool isReady: store.isLoaded && Compositor.canvasState !== null

    function windows() {
        return Compositor.canvasState?.windows ?? []
    }

    function viewport() {
        const outputs = Compositor.viewports()
        return outputs.find(output => output.name === Compositor.focusedScreen) ?? outputs[0] ?? null
    }

    function isMovable(window) {
        return !window.is_widget && !Compositor.isListed(Compositor.canvasState?.pinned, window.id) && !Compositor.isListed(Compositor.canvasState?.fullscreen, window.id)
    }

    function isParked(windowId) {
        return parked[windowId] !== undefined
    }

    function isInside(window, view) {
        const halfWidth = window.size[0] / 2
        const halfHeight = window.size[1] / 2
        return window.position[0] - halfWidth >= view.centerX - view.width / 2
            && window.position[0] + halfWidth <= view.centerX + view.width / 2
            && window.position[1] - halfHeight >= view.centerY - view.height / 2
            && window.position[1] + halfHeight <= view.centerY + view.height / 2
    }

    function clampInto(window, view) {
        const halfWidth = Math.min(window.size[0], view.width) / 2
        const halfHeight = Math.min(window.size[1], view.height) / 2
        const left = view.centerX - view.width / 2 + halfWidth
        const right = view.centerX + view.width / 2 - halfWidth
        const bottom = view.centerY - view.height / 2 + halfHeight
        const top = view.centerY + view.height / 2 - halfHeight
        return [Math.round(Math.max(left, Math.min(right, window.position[0]))), Math.round(Math.max(bottom, Math.min(top, window.position[1])))]
    }

    function moveWindow(windowId, point) {
        Compositor.send(["move", String(point[0]), String(point[1]), "--id", String(windowId)])
    }

    function park(window) {
        if (!home || isParked(window.id) || !isMovable(window))
            return
        const nextParked = Object.assign({}, parked)
        nextParked[window.id] = [window.position[0], window.position[1]]
        parked = nextParked
        Compositor.send(["opacity", "0", "--id", String(window.id)])
        moveWindow(window.id, [home.x + layout.parkReach, home.y + Object.keys(nextParked).length * layout.parkSpacing])
    }

    function restore(windowId) {
        const saved = parked[windowId]
        if (saved === undefined)
            return
        const nextParked = Object.assign({}, parked)
        delete nextParked[windowId]
        parked = nextParked
        moveWindow(windowId, saved)
        Compositor.send(["opacity", "1", "--id", String(windowId)])
        Compositor.send(["focus", "--id", String(windowId)])
    }

    function windowFor(toplevel) {
        const appId = toplevel.appId ?? ""
        const candidates = windows().filter(window => window.app_id === appId)
        return candidates.find(window => window.title === toplevel.title) ?? candidates[0] ?? null
    }

    function activate(toplevel) {
        const window = windowFor(toplevel)
        if (!window) {
            toplevel.activate()
            return
        }
        if (isParked(window.id))
            restore(window.id)
        else if (window.is_focused)
            minimizeWindow(window)
        else
            Compositor.send(["focus", "--id", String(window.id)])
    }

    function focusedWindow() {
        return windows().find(window => window.is_focused) ?? null
    }

    function minimizeWindow(window) {
        park(window)
        const next = windows().find(candidate => candidate.id !== window.id && !isParked(candidate.id) && isMovable(candidate))
        if (next)
            Compositor.send(["focus", "--id", String(next.id)])
    }

    function minimize() {
        const window = focusedWindow()
        if (isConfined && window)
            minimizeWindow(window)
    }

    function maximize() {
        Compositor.action("fit-window")
    }

    function fullscreen() {
        Compositor.action("toggle-fullscreen")
    }

    function snap(direction) {
        const window = focusedWindow()
        const view = viewport()
        if (!isConfined || !window || !view || !isMovable(window))
            return
        const isHorizontal = direction === "left" || direction === "right"
        const width = isHorizontal ? view.width / 2 : view.width
        const height = isHorizontal ? view.height : view.height / 2
        const shift = direction === "left" ? -view.width / 4 : direction === "right" ? view.width / 4 : 0
        const lift = direction === "up" ? view.height / 4 : direction === "down" ? -view.height / 4 : 0
        Compositor.send(["resize", String(Math.round(width)), String(Math.round(height)), "--id", String(window.id)])
        moveWindow(window.id, [Math.round(view.centerX + shift), Math.round(view.centerY + lift)])
    }

    function enter() {
        const view = viewport()
        if (!view)
            return
        home = { x: Math.round(view.centerX), y: Math.round(view.centerY) }
        Compositor.send(["zoom", "1"])
        const seen = {}
        for (const window of windows()) {
            seen[window.id] = true
            if (!window.is_focused)
                park(window)
        }
        known = seen
        cascade = 0
    }

    function recover() {
        if (hasRecovered)
            return
        hasRecovered = true
        const saved = store.values.parked ?? {}
        const living = windows().map(window => String(window.id))
        const alive = {}
        for (const windowId of Object.keys(saved)) {
            if (living.indexOf(windowId) >= 0)
                alive[windowId] = saved[windowId]
        }
        if (isConfined) {
            parked = Object.assign({}, alive, parked)
            return
        }
        for (const windowId of Object.keys(alive)) {
            moveWindow(windowId, alive[windowId])
            Compositor.send(["opacity", "1", "--id", windowId])
        }
        store.update({ parked: {} })
    }

    function leave() {
        for (const windowId of Object.keys(parked)) {
            moveWindow(windowId, parked[windowId])
            Compositor.send(["opacity", "1", "--id", windowId])
        }
        parked = {}
        home = null
    }

    function settle() {
        const view = viewport()
        if (!isConfined || !home || !view)
            return
        if (Math.abs(view.centerX - home.x) > 2 || Math.abs(view.centerY - home.y) > 2)
            Compositor.send(["camera", String(home.x), String(home.y)])
        if (Math.abs(view.zoom - 1) > 0.001)
            Compositor.send(["zoom", "1"])
        const homeView = Object.assign({}, view, { centerX: home.x, centerY: home.y, zoom: 1 })
        const seen = {}
        for (const window of windows()) {
            seen[window.id] = true
            if (isParked(window.id)) {
                if (window.is_focused)
                    restore(window.id)
                continue
            }
            if (!isMovable(window) || isInside(window, homeView))
                continue
            if (!known[window.id]) {
                const offset = (cascade++ % layout.cascadeSteps) * layout.cascadeStep
                moveWindow(window.id, clampInto({ size: window.size, position: [home.x + offset, home.y - offset] }, homeView))
            } else {
                moveWindow(window.id, clampInto(window, homeView))
            }
        }
        known = seen
    }

    onIsReadyChanged: {
        if (!isReady)
            return
        recover()
        if (isConfined)
            enter()
    }
    onIsConfinedChanged: {
        if (isReady)
            isConfined ? enter() : leave()
    }
    onParkedChanged: {
        if (hasRecovered)
            store.update({ parked: parked })
    }

    StateFile {
        id: store
        name: "desktop"
        defaults: ({ parked: {} })
    }

    Connections {
        target: Compositor

        function onCanvasChanged() {
            if (confinement.isConfined)
                settleDelay.restart()
        }
    }

    Timer {
        id: settleDelay
        interval: Motion.desktop.settle
        onTriggered: confinement.settle()
    }
}
