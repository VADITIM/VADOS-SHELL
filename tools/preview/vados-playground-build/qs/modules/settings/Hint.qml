import QtQuick
import qs.config

Piece {
    id: hint

    property string text

    role: "hint"

    width: parent ? parent.width : implicitWidth
    height: line.implicitHeight

    Text {
        id: line
        width: hint.width
        wrapMode: Text.WordWrap
        text: hint.text
        color: Appearance.color.textMuted
        lineHeight: Appearance.settings.section.hintLine
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.chip
        font.letterSpacing: Appearance.font.labelSpacing
    }
}
