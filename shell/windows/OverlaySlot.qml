import QtQuick
import Quickshell
import qs.state

Scope {
    id: slot

    required property string overlayKey
    default property Component surface
    property string screenName: ""
    readonly property string openOn: Overlays.screenOf(overlayKey)
    readonly property ShellScreen screen: Array.from(Quickshell.screens).find(shown => shown.name === screenName) ?? Quickshell.screens[0] ?? null

    onOpenOnChanged: {
        if (openOn.length > 0)
            screenName = openOn
    }

    LazyLoader {
        active: true
        component: slot.surface
    }
}
