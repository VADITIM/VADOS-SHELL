import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: batteryIdle

    idleKey: "battery"
    extensionKey: "power"
    isAvailable: Battery.isPresent
    glyphName: "battery"
    glyphLevel: Battery.level
    isCharging: Battery.isCharging
    ringLevel: Battery.level
    ringCap: Battery.cap
    ringColor: Appearance.chargeColor(Battery.level, Battery.isCharging)
    glyphColor: Battery.level < 0.15 && !Battery.isCharging ? Appearance.color.danger : Appearance.color.textBody

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 10

        ScrambleText {
            anchors.verticalCenter: parent.verticalCenter
            label: "battery level"
            target: Math.round(Battery.level * 100) + "%"
            isShown: batteryIdle.isUnfolded
            pixelSize: Appearance.font.body + 2
            spacing: 0
        }
    }
}
