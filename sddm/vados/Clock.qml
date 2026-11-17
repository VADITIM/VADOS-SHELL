import QtQuick

Column {
    id: clock

    required property var look
    property date now: new Date()
    readonly property string time: Qt.formatTime(now, "hh:mm")

    spacing: look.tokens.login.gap / 2

    Row {
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: clock.time.length

            Digit {
                required property int index

                look: clock.look
                glyph: clock.time.charAt(index)
                size: clock.look.tokens.login.time
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(clock.now, "dddd d MMMM").toUpperCase()
        color: clock.look.accent
        font.family: clock.look.mono
        font.pixelSize: clock.look.tokens.font.label
        font.letterSpacing: clock.look.tokens.font.labelSpacing
    }

    Timer {
        interval: clock.look.tokens.motion.tick
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
