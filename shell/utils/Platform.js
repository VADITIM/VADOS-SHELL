.pragma library

const backends = {
    driftwm: { activeWindow: true, windowGeometry: true, windowControl: true, freeCanvas: true, workspaces: false, layerShell: true },
    hyprland: { activeWindow: true, windowGeometry: true, windowControl: false, freeCanvas: false, workspaces: true, layerShell: true },
    generic: { activeWindow: true, windowGeometry: false, windowControl: false, freeCanvas: false, workspaces: false, layerShell: true }
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
