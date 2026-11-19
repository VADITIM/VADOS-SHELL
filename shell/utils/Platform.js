.pragma library

const backends = {
    driftwm: { activeWindow: true, windowGeometry: true, fullscreenDetection: true, focusTracking: true, windowControl: true, windowMinimize: true, windowSnap: true, workspaceManagement: false, freeCanvas: true, layerShell: true, sessionLock: true, displayPower: true, ownBackground: true, outputConfiguration: true, keyboardLayout: true, deviceKeyboardLayout: false },
    hyprland: { activeWindow: true, windowGeometry: true, fullscreenDetection: true, focusTracking: true, windowControl: false, windowMinimize: false, windowSnap: false, workspaceManagement: false, freeCanvas: false, layerShell: true, sessionLock: true, displayPower: true, ownBackground: false, outputConfiguration: true, keyboardLayout: true, deviceKeyboardLayout: true },
    generic: { activeWindow: true, windowGeometry: false, fullscreenDetection: true, focusTracking: false, windowControl: false, windowMinimize: false, windowSnap: false, workspaceManagement: false, freeCanvas: false, layerShell: true, sessionLock: false, displayPower: false, ownBackground: false, outputConfiguration: false, keyboardLayout: false, deviceKeyboardLayout: false }
}

function capabilitiesOf(name) {
    return backends[name] ?? backends.generic
}

function levelOf(capabilities) {
    if (capabilities.freeCanvas && capabilities.windowControl)
        return "native"
    if (capabilities.windowGeometry)
        return "extended"
    return "core"
}
