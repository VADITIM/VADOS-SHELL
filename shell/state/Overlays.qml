pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: overlays

    readonly property var kinds: ({
        search: { layer: 1 },
        settings: { layer: 1 },
        dashboard: { layer: 1 }
    })
    property var screens: ({})
    property var stack: []
    property var awayScreens: []
    property var settingsOrigins: ({})
    property var taskbarParts: ({})
    property var visitors: ({})
    property var phases: ({})
    readonly property string top: stack.length > 0 ? stack[stack.length - 1] : ""

    signal taskbarGathering(string screenName)

    function screenOf(key) {
        return screens[key] ?? ""
    }

    function isOpen(key, screenName) {
        return screenName.length > 0 && screenOf(key) === screenName
    }

    function isAnyOpen() {
        return stack.length > 0
    }

    function isAnyOn(screenName) {
        return stack.some(key => screens[key] === screenName)
    }

    function ownsKeyboard(key, screenName) {
        return top === key && isOpen(key, screenName)
    }

    function phaseOf(key, screenName) {
        return (phases[screenName] ?? {})[key] ?? "idle"
    }

    function isSettled(screenName) {
        const onScreen = phases[screenName] ?? {}
        return Object.keys(onScreen).every(key => onScreen[key] === "active")
    }

    function reportPhase(key, screenName, phase) {
        if (!kinds[key] || screenName.length === 0)
            return
        const placed = Object.assign({}, phases)
        const onScreen = Object.assign({}, placed[screenName] ?? {})
        if (phase === "idle")
            delete onScreen[key]
        else
            onScreen[key] = phase
        placed[screenName] = onScreen
        phases = placed
        if (phase === "idle")
            returnTaskbar(screenName)
    }

    function keepScreens(screenNames) {
        for (const key of stack.slice()) {
            if (screenNames.indexOf(screens[key]) < 0)
                close(key)
        }
        awayScreens = awayScreens.filter(screenName => screenNames.indexOf(screenName) >= 0)
        settingsOrigins = keepOnly(settingsOrigins, screenNames)
        taskbarParts = keepOnly(taskbarParts, screenNames)
        visitors = keepOnly(visitors, screenNames)
        phases = keepOnly(phases, screenNames)
    }

    function keepOnly(byScreen, screenNames) {
        const kept = {}
        for (const screenName of Object.keys(byScreen)) {
            if (screenNames.indexOf(screenName) >= 0)
                kept[screenName] = byScreen[screenName]
        }
        return kept
    }

    function isTaskbarAway(screenName) {
        return awayScreens.indexOf(screenName) >= 0
    }

    function open(key, screenName) {
        if (!kinds[key] || screenName.length === 0)
            return
        const layer = kinds[key].layer
        for (const other of stack.slice()) {
            if (other !== key && kinds[other].layer <= layer)
                close(other)
        }
        gatherTaskbar(screenName)
        const placed = Object.assign({}, screens)
        placed[key] = screenName
        screens = placed
        stack = stack.filter(other => other !== key).concat([key])
    }

    function close(key) {
        if (screenOf(key).length === 0)
            return
        const placed = Object.assign({}, screens)
        delete placed[key]
        screens = placed
        stack = stack.filter(other => other !== key)
    }

    function toggle(key, screenName) {
        if (screenOf(key).length > 0)
            close(key)
        else
            open(key, screenName)
    }

    function closeTop() {
        if (top.length > 0)
            close(top)
    }

    function gatherTaskbar(screenName) {
        if (isTaskbarAway(screenName))
            return
        taskbarGathering(screenName)
        awayScreens = awayScreens.concat([screenName])
    }

    function returnTaskbar(screenName) {
        if (!isAnyOn(screenName))
            awayScreens = awayScreens.filter(away => away !== screenName)
    }

    function placeSettingsOrigin(screenName, origin) {
        const origins = Object.assign({}, settingsOrigins)
        origins[screenName] = origin
        settingsOrigins = origins
    }

    function placeTaskbarParts(screenName, parts) {
        const placed = Object.assign({}, taskbarParts)
        placed[screenName] = parts
        taskbarParts = placed
    }

    function placeVisitor(key, screenName, visitor) {
        const placed = Object.assign({}, visitors)
        const onScreen = Object.assign({}, placed[screenName] ?? {})
        onScreen[key] = visitor
        placed[screenName] = onScreen
        visitors = placed
    }

    function visitorOn(screenName) {
        const onScreen = visitors[screenName] ?? {}
        return Object.keys(onScreen).map(key => onScreen[key]).find(visitor => visitor) ?? null
    }
}
