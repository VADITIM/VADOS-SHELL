import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.services
import qs.modules.prompt

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isRight: Config.data.taskbar.side === "right"
    readonly property bool isOverMenu: Overlays.isHolding(screenName)
    readonly property bool isOpen: ActivityState.isPromptOn(screenName)
    readonly property string stackKey: Overlays.stack.join(" ")
    property bool isRestacking: false

    function restack() {
        if (!isOpen)
            return
        isRestacking = true
        restackTimer.restart()
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    visible: isOpen && !isRestacking
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vados-prompt-dismiss"
    WlrLayershell.keyboardFocus: isOpen && isOverMenu ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onStackKeyChanged: restack()
    onIsOverMenuChanged: restack()
    onVisibleChanged: {
        if (visible && isOverMenu)
            prompt.focusZone()
    }
    mask: Region {
        width: window.width
        height: window.height

        Region {
            readonly property rect zone: window.isOverMenu ? Qt.rect(0, 0, 0, 0) : ActivityState.clipboardZoneOn(window.screenName)
            x: zone.x
            y: zone.y
            width: zone.width
            height: zone.height
            intersection: Intersection.Subtract
        }
    }

    Timer {
        id: restackTimer
        interval: Motion.prompt.restack
        onTriggered: window.isRestacking = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Passwords.cancel("a click outside it")
    }

    Rectangle {
        id: panel
        visible: window.isOverMenu
        x: window.isRight ? window.width - width - Appearance.taskbar.margin : Appearance.taskbar.margin
        y: (window.height - height) / 2
        width: prompt.bodySize.width
        height: prompt.bodySize.height
        radius: Appearance.clipboard.radius
        color: Appearance.color.raised

        MouseArea {
            anchors.fill: parent
        }

        Prompt {
            id: prompt
            anchors.fill: parent
            isMirrored: window.isRight
            request: Passwords.request
            body: Qt.rect(0, 0, panel.width, panel.height)
            isBodyShown: window.isOpen && window.isOverMenu
            onSubmitted: (password, isChoiceChosen) => Passwords.submit(password, isChoiceChosen)
            onCancelled: reason => Passwords.cancel(reason)
        }
    }
}
