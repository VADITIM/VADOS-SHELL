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
    readonly property bool isOpen: Overlays.isOpen(overlayKey, screenName)
    readonly property var parts: Overlays.taskbarParts[screenName] ?? []

    function requestClose() {
        Overlays.close(overlayKey)
    }

    function land() {
        Overlays.returnTaskbar(screenName)
    }

    function placeVisitor(visitor) {
        Overlays.placeVisitor(overlayKey, screenName, visitor)
    }

    onPhaseChanged: Overlays.reportPhase(overlayKey, screenName, phase)

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
    WlrLayershell.keyboardFocus: Overlays.ownsKeyboard(overlayKey, screenName) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
}
