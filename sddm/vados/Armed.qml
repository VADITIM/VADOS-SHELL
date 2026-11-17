import QtQuick

Pill {
    id: armed

    property string title: ""
    property string prompt: "SURE?"
    property bool isArmed: false

    signal confirmed()

    isLit: isArmed
    labelColor: isArmed ? look.tokens.color.danger : look.tokens.color.text
    label: isArmed ? prompt : title

    onTapped: {
        if (isArmed) {
            isArmed = false
            confirmed()
            return
        }
        isArmed = true
        disarm.restart()
    }

    Timer {
        id: disarm

        interval: armed.look.tokens.motion.armed
        onTriggered: armed.isArmed = false
    }
}
