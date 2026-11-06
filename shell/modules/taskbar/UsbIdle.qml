import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: usbIdle

    idleKey: "usb"
    isAvailable: Removable.devices.length > 0
    glyphName: "usb"

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 6

        Repeater {
            model: Removable.devices

            Row {
                id: device

                required property var modelData
                required property int index

                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                TypedText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(fullWidth, 110)
                    clip: true
                    isShown: usbIdle.isUnfolded
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    target: device.modelData.label
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }

                Turn {
                    anchors.verticalCenter: parent.verticalCenter
                    isShown: usbIdle.isUnfolded
                    enterDelay: (device.index + 1) * Motion.pill.elementStagger
                    enterDuration: Motion.stateDuration
                    enterEasing: Easing.OutBack
                    leaveWindow: 0

                    GlyphButton {
                        glyphName: "eject"
                        onClicked: Removable.eject(device.modelData)
                    }
                }
            }
        }
    }
}
