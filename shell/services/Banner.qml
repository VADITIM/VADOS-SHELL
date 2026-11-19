pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Figlet.js" as Figlet

Singleton {
    id: banner

    property var font: null

    function render(text) {
        return Figlet.render(font, text)
    }

    FileView {
        path: Qt.resolvedUrl("../assets/fonts/def-leppard.flf").toString().replace("file://", "")
        onLoaded: banner.font = Figlet.parse(text())
    }
}
