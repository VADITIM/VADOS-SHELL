import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

PanelWindow {
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Appearance.barHeight
    color: "transparent"

    Surface {
        anchors.fill: parent
        radius: 0

        Text {
            anchors.centerIn: parent
            text: DateTime.time
            color: Appearance.color.onSurface
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
        }
    }
}
