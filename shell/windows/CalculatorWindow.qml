import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.calculator

FloatingWindow {
    id: window

    title: "Calculator"
    implicitWidth: Appearance.calculator.width
    implicitHeight: Appearance.calculator.height
    minimumSize: Qt.size(Appearance.calculator.minimumWidth, Appearance.calculator.minimumHeight)
    color: Appearance.color.ground
    visible: true
    onClosed: Builtins.close("calculator")

    Calculator {
        anchors.fill: parent
        isShown: window.visible
    }
}
