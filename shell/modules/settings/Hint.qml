import QtQuick
import qs.config

Piece {
    id: hint

    property string text
    property string family: Appearance.font.sans

    role: "hint"

    width: parent ? parent.width : implicitWidth
    height: isWanted ? line.implicitHeight : 0

    Text {
        id: line
        width: hint.width
        wrapMode: Text.WordWrap
        text: hint.text
        color: Appearance.color.textMuted
        lineHeight: Appearance.settings.section.hintLine
        font.family: hint.family
        font.pixelSize: Appearance.font.chip
        font.letterSpacing: Appearance.font.labelSpacing
    }
}
