import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    property var readings: []
    readonly property var look: Appearance.widgets
    readonly property real columnWidth: (width - look.gap * 2) / 3
    readonly property real dialSize: Math.min(columnWidth, height - Appearance.font.label - look.captionGap)

    function share(used, total) {
        return total > 0 ? used / total : 0
    }

    function percent(value) {
        return String(Math.round(value * 100)).padStart(3, " ") + "%"
    }

    Binding on readings {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: [
            { label: "CPU", glyph: "cpu", value: Hardware.cpuLoad, isKnown: true },
            { label: "GPU", glyph: "gpu", value: Hardware.gpuLoad, isKnown: Hardware.hasGpu },
            { label: "RAM", glyph: "ram", value: face.share(Hardware.memoryUsed, Hardware.memoryTotal), isKnown: Hardware.memoryTotal > 0 }
        ]
    }

    Row {
        spacing: face.look.gap

        Repeater {
            model: 3

            Column {
                id: column

                required property int index
                readonly property var reading: face.readings[index] ?? { label: "", glyph: "", value: 0, isKnown: false }

                width: face.columnWidth
                spacing: face.look.captionGap

                Dial {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: face.dialSize
                    height: face.dialSize
                    value: column.reading.isKnown ? column.reading.value : 0
                    tint: Appearance.bandColor(column.reading.value, face.look.usageBands)
                    glyph: column.reading.glyph
                    isShown: face.isShown
                }

                Roll {
                    anchors.horizontalCenter: parent.horizontalCenter
                    target: column.reading.label + (column.reading.isKnown ? face.percent(column.reading.value) : "  --")
                    isShown: face.isShown
                    holdsWidth: true
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                }
            }
        }
    }
}
