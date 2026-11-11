pragma Singleton
import QtQuick
import Quickshell
import "../utils/Features.js" as Features

Singleton {
    id: overlays

    readonly property var kinds: Features.overlayKinds()
    property var screens: ({})
    property var stack: []
    property var awayScreens: []
    property var gathering: []
    property var taskbarParts: ({})
    property var visitors: ({})
    property var phases: ({})
    property var swaps: ({})
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

    function isHolding(screenName) {
        return isAnyOn(screenName) || Object.keys(phases[screenName] ?? {}).length > 0
    }

    function isWanted(key, screenName) {
        return isOpen(key, screenName) || phaseOf(key, screenName) !== "idle"
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

    function isWaiting(key, screenName) {
        const swap = swaps[screenName]
        return swap !== undefined && swap.to === key && !swap.isReady
    }

    function hasCircle(key, screenName) {
        const swap = swaps[screenName]
        return swap !== undefined && swap.to === key
    }

    function isHandingOver(key, screenName) {
        const swap = swaps[screenName]
        return swap !== undefined && swap.to !== key
    }

    function placeSwap(screenName, swap) {
        const placed = Object.assign({}, swaps)
        if (swap)
            placed[screenName] = swap
        else
            delete placed[screenName]
        swaps = placed
    }

    function settleSwap(screenName) {
        const swap = swaps[screenName]
        if (swap && !swap.isReady)
            placeSwap(screenName, { to: swap.to, isReady: true })
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
            settleSwap(screenName)
        if (phase === "active" && swaps[screenName]?.to === key)
            placeSwap(screenName, null)
        if (phase === "idle")
            returnTaskbar(screenName)
    }

    function keepScreens(screenNames) {
        for (const key of stack.slice()) {
            if (screenNames.indexOf(screens[key]) < 0)
                close(key)
        }
        awayScreens = awayScreens.filter(screenName => screenNames.indexOf(screenName) >= 0)
        gathering = gathering.filter(screenName => screenNames.indexOf(screenName) >= 0)
        taskbarParts = keepOnly(taskbarParts, screenNames)
        visitors = keepOnly(visitors, screenNames)
        phases = keepOnly(phases, screenNames)
        swaps = keepOnly(swaps, screenNames)
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

    function isGathering(screenName) {
        return gathering.indexOf(screenName) >= 0
    }

    function open(key, screenName) {
        if (!kinds[key] || screenName.length === 0)
            return
        const layer = kinds[key].layer
        const isKeeping = kinds[key].keepsTaskbar === true
        const isSwap = !isKeeping && stack.some(other => other !== key && screens[other] === screenName && phaseOf(other, screenName) !== "idle" && kinds[other].layer <= layer)
        if (isSwap)
            placeSwap(screenName, { to: key, isReady: false })
        if (!isKeeping)
            gatherTaskbar(screenName)
        const displaced = stack.filter(other => other !== key && kinds[other].layer <= layer)
        const placed = Object.assign({}, screens)
        placed[key] = screenName
        screens = placed
        stack = stack.filter(other => other !== key).concat([key])
        for (const other of displaced)
            close(other)
    }

    function close(key) {
        if (screenOf(key).length === 0)
            return
        const screenName = screenOf(key)
        if (swaps[screenName]?.to === key)
            placeSwap(screenName, null)
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
        gathering = gathering.concat([screenName])
        taskbarGathering(screenName)
        awayScreens = awayScreens.concat([screenName])
    }

    function carryTaskbar(screenName) {
        if (!isGathering(screenName))
            return
        taskbarGathering(screenName)
        gathering = gathering.filter(held => held !== screenName)
    }

    function returnTaskbar(screenName) {
        if (isAnyOn(screenName))
            return
        gathering = gathering.filter(held => held !== screenName)
        awayScreens = awayScreens.filter(away => away !== screenName)
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
        if (visitor && visitor.isReleasing === true && visitor.release > 0)
            returnTaskbar(screenName)
    }

    function visitorOn(screenName) {
        const onScreen = visitors[screenName] ?? {}
        return Object.keys(onScreen).map(key => onScreen[key]).find(visitor => visitor) ?? null
    }
}
