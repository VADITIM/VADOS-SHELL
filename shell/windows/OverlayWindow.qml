import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.state

PanelWindow {
    id: window

    required property string overlayKey
    property bool isPresent: false
    property string phase: "idle"
    readonly property string screenName: screen?.name ?? ""
    property bool isComplete: false
    readonly property bool isOpen: isComplete && Overlays.isOpen(overlayKey, screenName) && !Overlays.isWaiting(overlayKey, screenName)
    readonly property bool isHandingOver: Overlays.isHandingOver(overlayKey, screenName)
    readonly property bool hasCircle: Overlays.hasCircle(overlayKey, screenName)
    readonly property var parts: Overlays.taskbarParts[screenName] ?? []
    readonly property bool shouldStream: Config.data.taskbar.gather === "merge"
    readonly property bool canHandOff: Config.data.taskbar.style !== "bare" && !Occupancy.isCovered(screenName, true)
    readonly property bool isPointedAt: !Compositor.capabilities.focusTracking || Compositor.focusedScreen === screenName
    readonly property bool hasKeyboard: Overlays.ownsKeyboard(overlayKey, screenName) && isPointedAt && !FrameDebug.isActive

    function requestClose() {
        Overlays.close(overlayKey)
    }

    function land() {
        Overlays.settleSwap(screenName)
        Overlays.returnTaskbar(screenName)
    }

    function carry(isCarrying) {
        if (isCarrying)
            Overlays.carryTaskbar(screenName)
    }

    function placeVisitor(visitor) {
        Overlays.placeVisitor(overlayKey, screenName, visitor)
    }

    onPhaseChanged: Overlays.reportPhase(overlayKey, screenName, phase)
    Component.onCompleted: isComplete = true

    FrameTap {
        target: window.contentItem
        screenName: window.screenName
        isLive: window.visible
        order: 1
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    visible: isPresent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vados-" + overlayKey
    WlrLayershell.keyboardFocus: hasKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
}
