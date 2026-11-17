import QtQuick

Item {
    id: digit

    required property var look
    required property string glyph
    property color color: look.tokens.color.text
    property int size: look.tokens.font.body
    property string shown: glyph
    property string leaving: ""
    property real roll: 1

    onGlyphChanged: {
        if (glyph === shown)
            return
        leaving = shown
        shown = glyph
        roll = 0
        rolling.restart()
    }

    implicitWidth: current.implicitWidth
    implicitHeight: current.implicitHeight
    clip: true

    Text {
        id: current

        y: digit.height * (1 - digit.roll)
        text: digit.shown
        color: digit.color
        font.family: digit.look.mono
        font.pixelSize: digit.size
        font.bold: true
    }

    Text {
        y: -digit.height * digit.roll
        visible: digit.roll < 1
        text: digit.leaving
        color: digit.color
        opacity: 1 - digit.roll
        font.family: digit.look.mono
        font.pixelSize: digit.size
        font.bold: true
    }

    NumberAnimation {
        id: rolling

        target: digit
        property: "roll"
        to: 1
        duration: digit.look.pace(digit.look.tokens.motion.roll)
        easing.type: Easing.OutBack
    }
}
