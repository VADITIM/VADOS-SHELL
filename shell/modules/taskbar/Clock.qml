import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: clock

    property bool isShown: false

    width: Math.max(time.fullWidth, date.fullWidth)
    height: time.height + date.height

    Roll {
        id: time
        target: DateTime.time
        isShown: clock.isShown
        color: Appearance.color.text
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.clock
        font.bold: true
    }

    Roll {
        id: date
        y: time.height
        target: DateTime.date
        isShown: clock.isShown
        color: Appearance.color.textMuted
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
    }
}
