import QtQuick
import qs.config
import qs.state

Item {
    id: tap

    required property Item target
    required property string screenName
    required property bool isLive
    property string side: "full"
    property int order: 0

    readonly property bool canGrab: isLive && (FrameDebug.isActive || FrameDebug.isSnapping) && target.width > 0 && target.height > 0

    Component {
        id: keeperComponent

        Image {
            visible: false
            cache: true
            asynchronous: false
        }
    }

    function grab(token, scale) {
        const width = target.width
        const height = target.height
        const pixels = Qt.size(Math.round(width * scale * Screen.devicePixelRatio), Math.round(height * scale * Screen.devicePixelRatio))
        const isStarted = target.grabToImage(result => FrameDebug.store(token, {
            keeper: keeperComponent.createObject(tap, { source: result.url }),
            url: result.url,
            screenName: tap.screenName,
            side: tap.side,
            order: tap.order,
            width: width,
            height: height,
            bytes: pixels.width * pixels.height * Motion.frames.bytesPerPixel
        }), pixels)
        if (!isStarted)
            FrameDebug.skip()
    }

    Connections {
        target: FrameDebug

        function onCaptureRequested(token, scale) {
            if (!tap.canGrab)
                return
            FrameDebug.expect()
            tap.grab(token, scale)
        }
    }
}
