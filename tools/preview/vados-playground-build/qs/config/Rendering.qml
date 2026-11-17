pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property bool isLite: Config.data.rendering.quality === "lite"

    function blur(radius) {
        return isLite ? 0 : radius * Config.data.pills.blur
    }
}
