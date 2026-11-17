import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: clock

    property Item host: null
    property bool isShown: false
    readonly property var look: Appearance.lock

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        spacing: clock.look.rowGap

        Turn {
            anchors.horizontalCenter: parent.horizontalCenter
            isShown: clock.isShown
            enterEasing: Easing.OutBack

            Text {
                text: Qt.formatDateTime(DateTime.now, "hh:mm")
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: clock.look.clock
            }
        }

        TypedText {
            anchors.horizontalCenter: parent.horizontalCenter
            target: DateTime.date
            isShown: clock.isShown
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: clock.look.date
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }
}
