import QtQuick
import qs.config
import qs.components

Turn {
    id: vacant

    enterDuration: Motion.search.tileEnter

    Rectangle {
        width: vacant.width
        height: vacant.height
        radius: Appearance.radius.large
        color: "transparent"
        border.width: 1
        border.color: Appearance.color.textMuted

        TypedText {
            anchors.centerIn: parent
            target: "[EMPTY]"
            isShown: vacant.presence > 0.5
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.degrees
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }
}
