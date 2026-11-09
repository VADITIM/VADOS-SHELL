import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.state
import qs.modules.framedebug
import "../utils/Log.js" as Log

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isHost: FrameDebug.screenName === screenName
    property string picturePath: ""

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    visible: (FrameDebug.isActive || FrameDebug.isSnapping) && isHost
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vados-frames"
    WlrLayershell.keyboardFocus: FrameDebug.isActive && isHost ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    mask: passThrough

    Region {
        id: passThrough
    }

    Process {
        id: copy
        onExited: code => {
            if (code === 0)
                Log.info("frames", "screenshot copied to the clipboard")
            else
                Log.warn("frames", "wl-copy exited with code " + code + ", the screenshot stays at " + window.picturePath)
            FrameDebug.finishSnap()
        }
    }

    Connections {
        target: FrameDebug

        function onSnapshotReady(shots) {
            if (!window.isHost)
                return
            hud.snapshotShots = shots.filter(shot => shot.screenName === window.screenName)
            const isStarted = hud.capture(result => {
                window.picturePath = Quickshell.cachePath("vados-frame.png")
                result.saveToFile(window.picturePath)
                copy.command = ["sh", "-c", "wl-copy --type image/png < \"$1\"", "sh", window.picturePath]
                copy.running = true
            })
            if (!isStarted) {
                Log.warn("frames", "the screenshot could not be rendered")
                FrameDebug.finishSnap()
            }
        }
    }

    FrameHud {
        id: hud
        anchors.fill: parent
        isActive: FrameDebug.isActive
        isReplay: FrameDebug.isViewingPast
        replayShots: FrameDebug.shotsOn(window.screenName)
        counter: FrameDebug.counter
        label: FrameDebug.shownLabel
        onStepRequested: FrameDebug.step()
        onBackRequested: FrameDebug.back()
        onShotRequested: FrameDebug.snap(window.screenName)
        onCloseRequested: FrameDebug.close()
    }
}
