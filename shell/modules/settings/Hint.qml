import QtQuick
import qs.config

Piece {
    id: hint

    property string text
    property string family: Appearance.font.sans
    property int lines: 0
    property color tint: Appearance.color.textMuted
    property int alignment: Text.AlignLeft

    role: "hint"

    width: parent ? parent.width : implicitWidth
    height: isWanted ? Math.max(line.implicitHeight, lines * line.implicitHeight / Math.max(1, line.lineCount)) : 0

    Text {
        id: line
        width: hint.width
        wrapMode: Text.WordWrap
        text: hint.text
        color: hint.tint
        horizontalAlignment: hint.alignment
        lineHeight: Appearance.settings.section.hintLine
        font.family: hint.family
        font.pixelSize: Appearance.font.chip
        font.letterSpacing: Appearance.font.labelSpacing
    }
}
