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

                ScrambleText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 110)
                    clip: true
                    label: "usb name"
                    isShown: usbIdle.isUnfolded
                    target: device.modelData.label
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
                        hoverName: "EJECT"
                        onClicked: Removable.eject(device.modelData)
                    }
                }
            }
        }
    }
}
