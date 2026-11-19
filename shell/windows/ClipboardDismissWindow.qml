import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.services
import qs.modules.clipboard

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isRight: Config.data.taskbar.side === "right"
    readonly property bool isOverMenu: Overlays.isHolding(screenName)
    readonly property var look: Appearance.clipboard
    readonly property bool isClipboardOpen: ActivityState.isClipboardOn(screenName)
    readonly property bool isActivityExpanded: screenName.length > 0 && ActivityState.modeOn(screenName) === "expanded" && !isOverMenu
    readonly property real budReach: isActivityExpanded ? Appearance.activity.bud.gap + Appearance.activity.bud.size : 0

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    visible: isClipboardOpen || isActivityExpanded
    WlrLayershell.layer: isOverMenu ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: "vados-clipboard-dismiss"
    color: "transparent"
    mask: Region {
        width: window.width
        height: window.height

        Region {
            readonly property rect zone: window.isOverMenu ? Qt.rect(0, 0, 0, 0) : ActivityState.clipboardZoneOn(window.screenName)
            x: zone.x
            y: zone.y - window.budReach
            width: zone.width
            height: zone.height + window.budReach * 2
            intersection: Intersection.Subtract
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: {
            ActivityState.closeClipboard()
            ActivityState.fold()
        }
    }

    Rectangle {
        id: panel
        visible: window.isOverMenu && window.isClipboardOpen
        x: window.isRight ? window.width - width - Appearance.taskbar.margin : Appearance.taskbar.margin
        y: (window.height - height) / 2
        width: window.look.width
        height: window.look.height
        radius: window.look.radius
        color: Appearance.color.raised

        MouseArea {
            anchors.fill: parent
        }

        ClipboardHistory {
            anchors.fill: parent
            isMirrored: window.isRight
            entries: Clipboard.entries
            body: Qt.rect(0, 0, panel.width, panel.height)
            isBodyShown: panel.visible
            onPickRequested: entry => {
                Clipboard.pick(entry)
                ActivityState.closeClipboard()
            }
            onPinRequested: entry => Clipboard.togglePin(entry)
            onRemoveRequested: entry => Clipboard.remove(entry)
            onClearRequested: Clipboard.clear()
            onCloseRequested: ActivityState.closeClipboard()
        }
    }
}
