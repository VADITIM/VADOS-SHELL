import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: dashboard

    property Item host: null
    property bool isShown: false
    readonly property var look: Appearance.lock
    readonly property var readings: [
        { key: "cpu", label: "CPU", share: Hardware.cpuLoad, isShown: true },
        { key: "ram", label: "RAM", share: Hardware.memoryTotal > 0 ? Hardware.memoryUsed / Hardware.memoryTotal : 0, isShown: true },
        { key: "battery", label: Battery.isCharging ? "CHARGING" : "BATTERY", share: Battery.level, isShown: Battery.isPresent }
    ]

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        width: parent.width - dashboard.look.padding * 2
        spacing: dashboard.look.readingGap

        Repeater {
            model: dashboard.readings.length

            Turn {
                id: row

                required property int index
                readonly property var reading: dashboard.readings[index]

                width: parent.width
                visible: reading.isShown
                isShown: dashboard.isShown && reading.isShown
                enterDelay: index * Motion.pill.elementStagger
                enterEasing: Easing.OutBack

                Column {
                    width: parent.width
                    spacing: Appearance.unit.base

                    Item {
                        width: parent.width
                        height: label.implicitHeight

                        Text {
                            id: label
                            text: row.reading.label
                            color: Appearance.color.textMuted
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                        }

                        Text {
                            anchors.right: parent.right
                            text: Math.round(row.reading.share * 100) + "%"
                            color: Appearance.color.text
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.font.label
                        }
                    }

                    Item {
                        width: parent.width
                        height: dashboard.look.bar

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Appearance.color.wash
                        }

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, row.reading.share))
                            height: parent.height
                            radius: height / 2
                            color: Appearance.color.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: Motion.pace(Motion.stateDuration)
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
