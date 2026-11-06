import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: batteryIdle

    idleKey: "battery"
    isAvailable: Battery.isPresent
    glyphName: "battery"
    glyphLevel: Battery.level
    isCharging: Battery.isCharging
    glyphColor: Battery.level < 0.15 && !Battery.isCharging ? Appearance.color.danger : Appearance.color.textBody

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 10

        TypedText {
            anchors.verticalCenter: parent.verticalCenter
            target: Math.round(Battery.level * 100) + "%"
            isShown: batteryIdle.isUnfolded
            holdsWidth: true
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.body + 2
            font.bold: true
        }

        TypedText {
            anchors.verticalCenter: parent.verticalCenter
            isShown: batteryIdle.isUnfolded
            holdsWidth: true
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            target: {
                const hours = Math.floor(Battery.secondsLeft / 3600)
                const minutes = Math.floor(Battery.secondsLeft % 3600 / 60)
                const left = Battery.secondsLeft > 0 ? hours + "H " + minutes + "M " : ""
                return Battery.isCharging ? left + "TO FULL" : left + "LEFT"
            }
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }
}
