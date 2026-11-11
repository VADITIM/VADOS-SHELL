import QtQuick
import qs.config
import qs.services
import qs.state
import qs.modules.screenshot

OverlayWindow {
    id: window

    readonly property var pill: ActivityState.placeOn(window.screenName)

    overlayKey: "screenshot"
    isPresent: screenshot.isPresent
    phase: screenshot.phase

    Screenshot {
        id: screenshot
        anchors.fill: parent
        isOpen: window.isOpen
        frame: "file://" + Capture.frameOf(window.screenName) + "?" + Capture.frameStamp
        isMirrored: Config.data.taskbar.side === "right"
        pillSpineX: window.pill?.spineX ?? Appearance.taskbar.margin + Appearance.taskbar.thickness / 2
        pillCenterY: window.pill?.centerY ?? height / 2
        pillSize: Qt.size(window.pill?.width ?? 0, window.pill?.height ?? 0)
        pillGlyph: window.pill?.glyph ?? ""
        onCloseRequested: window.requestClose()
        onCutReady: result => {
            const path = Capture.cutPath()
            if (result.saveToFile(path)) {
                Capture.deliver(path)
                Attention.announce(ActivityState.copiedNotice(path), window.screenName)
            }
            window.requestClose()
        }
    }
}
