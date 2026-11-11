import QtQuick
import Quickshell
import qs.state

Scope {
    id: slot

    required property ShellScreen modelData
    required property string overlayKey
    default property Component surface
    readonly property string screenName: modelData?.name ?? ""
    readonly property bool isWanted: Overlays.isWanted(overlayKey, screenName) || (loader.item?.isPresent ?? false)
    property bool isLoaded: false

    function release() {
        isLoaded = isWanted
    }

    onIsWantedChanged: {
        if (isWanted)
            isLoaded = true
        else
            Qt.callLater(release)
    }

    LazyLoader {
        id: loader
        active: slot.isLoaded
        component: slot.surface
    }
}
