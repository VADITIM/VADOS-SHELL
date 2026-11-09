import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.state

PanelWindow {
    id: window

    required property string overlayKey
    property bool isPresent: false
    property string phase: "idle"
    readonly property string screenName: screen?.name ?? ""
    readonly property bool isOpen: Overlays.isOpen(overlayKey, screenName) && !Overlays.isWaiting(overlayKey, screenName)
    readonly property bool isHandingOver: Overlays.isHandingOver(overlayKey, screenName)
    readonly property bool hasCircle: Overlays.hasCircle(overlayKey, screenName)
    readonly property var parts: Overlays.taskbarParts[screenName] ?? []

    function requestClose() {
        Overlays.close(overlayKey)
    }

    function land() {
        Overlays.settleSwap(screenName)
        Overlays.returnTaskbar(screenName)
    }

    function placeVisitor(visitor) {
        Overlays.placeVisitor(overlayKey, screenName, visitor)
    }

    onPhaseChanged: Overlays.reportPhase(overlayKey, screenName, phase)

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
    WlrLayershell.keyboardFocus: Overlays.ownsKeyboard(overlayKey, screenName) && !FrameDebug.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
}
