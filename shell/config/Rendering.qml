pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property bool isLite: Config.data.rendering.quality === "lite"
    readonly property int frost: isLite ? 0 : Math.round(Appearance.liquid.frost * Config.data.pills.blur)

    function blur(radius) {
        return isLite ? 0 : radius
    }
}
