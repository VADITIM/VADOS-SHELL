import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: clock

    property bool isShown: false

    width: Math.max(time.fullWidth, date.fullWidth)
    height: time.height + Appearance.taskbar.clockLine + date.height

    Roll {
        id: time
        target: DateTime.time
        isShown: clock.isShown
        color: Appearance.color.clockText
        style: Text.Raised
        styleColor: Appearance.color.clockShade
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.taskbarClock
        font.weight: Font.DemiBold
        font.features: Appearance.font.tabularFigures
    }

    Roll {
        id: date
        y: time.height + Appearance.taskbar.clockLine
        target: DateTime.date
        isShown: clock.isShown
        color: Appearance.color.clockText
        opacity: Appearance.color.clockDateOpacity
        style: Text.Raised
        styleColor: Appearance.color.clockShade
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.label
        font.weight: Font.Medium
        font.letterSpacing: Appearance.font.clockDateSpacing
        font.features: Appearance.font.tabularFigures
    }
}
