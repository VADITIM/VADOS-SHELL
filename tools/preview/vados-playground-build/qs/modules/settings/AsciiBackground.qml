import QtQuick
import qs.config
import "../../utils/Banner.js" as Banner

Item {
    id: background

    property bool isShown: false
    property real presence: isShown ? 1 : 0

    readonly property var look: Appearance.settings.ascii
    readonly property int columns: Banner.lines.reduce((widest, line) => Math.max(widest, line.length), 0)
    readonly property real tileWidth: Math.max(1, measure.advanceWidth * columns + look.gap)
    readonly property real tileHeight: Math.max(1, measure.height * Banner.lines.length + look.gap)
    readonly property real diagonal: Math.hypot(width, height)
    readonly property int tilesAcross: Math.ceil(diagonal / tileWidth) + 3
    readonly property int tilesDown: Math.ceil(diagonal / tileHeight) + 2
    readonly property string rowText: composeRow()
    property real drift: 0

    visible: presence > 0.01
    opacity: presence * look.shade
    clip: true

    Behavior on presence {
        NumberAnimation {
            duration: Motion.pace(background.isShown ? Motion.settings.asciiEnter : Motion.settings.asciiLeave)
            easing.type: background.isShown ? Easing.OutQuad : Easing.InQuad
        }
    }

    function composeRow() {
        const spaces = Math.max(1, Math.round(look.gap / Math.max(1, measure.advanceWidth)))
        const padding = " ".repeat(spaces)
        return Banner.lines.map(line => (line.padEnd(columns, " ") + padding).repeat(tilesAcross)).join("\n")
    }

    TextMetrics {
        id: measure
        font.family: Appearance.font.fixedMono
        font.pixelSize: background.look.size
        text: "E"
    }

    NumberAnimation {
        target: background
        property: "drift"
        from: 0
        to: background.tileWidth
        duration: Motion.pace(background.tileWidth / Motion.settings.asciiSpeed * 1000)
        loops: Animation.Infinite
        running: background.visible && !Motion.isReduced
        paused: Motion.isHeld && running
    }

    Item {
        x: (background.width - width) / 2
        y: (background.height - height) / 2
        width: background.tileWidth * background.tilesAcross
        height: background.tileHeight * background.tilesDown
        rotation: background.look.angle

        Repeater {
            model: background.tilesDown

            Text {
                required property int index
                x: background.drift - background.tileWidth * (1 + (index % 2) / 2)
                y: index * background.tileHeight
                text: background.rowText
                textFormat: Text.PlainText
                color: Appearance.color.text
                font.family: Appearance.font.fixedMono
                font.preferShaping: false
                font.pixelSize: background.look.size
                lineHeight: 1
            }
        }
    }
}
