import QtQuick
import "../utils/Geometry.js" as Geometry

Item {
    id: gather

    property var parts: []
    property bool isMirrored: false
    property bool isShown: true
    property real seedX: 0
    property real seedY: 0
    property real merge: 0
    property real lag: 0.45

    readonly property var placed: (parts || []).map(part => isMirrored ? Qt.rect(width - part.x - part.width, part.y, part.width, part.height) : part)
    readonly property real reach: {
        let longest = 1
        for (const part of placed)
            longest = Math.max(longest, Math.abs(part.y - seedY), Math.abs(part.y + part.height - seedY))
        return longest
    }

    function shareAt(value) {
        return Geometry.clampUnit((merge - lag * Math.abs(value - seedY) / reach) / (1 - lag))
    }

    function formOf(part) {
        const topShare = shareAt(part.y)
        const bottomShare = shareAt(part.y + part.height)
        const top = part.y + (seedY - part.y) * topShare * topShare
        const bottom = part.y + part.height + (seedY - part.y - part.height) * bottomShare * bottomShare
        const drawn = Math.max(topShare, bottomShare)
        const swallowed = Math.min(topShare, bottomShare)
        const thickness = part.width * (1 - swallowed * swallowed)
        const centerX = part.x + part.width / 2 + (seedX - part.x - part.width / 2) * drawn
        const middle = (Math.min(top, bottom) + Math.max(top, bottom)) / 2
        const length = Math.max(Math.abs(bottom - top), thickness)
        return { x: centerX - thickness / 2, y: middle - length / 2, width: thickness, height: length }
    }

    anchors.fill: parent
    visible: isShown && merge < 1

    Repeater {
        model: gather.placed

        LiquidShape {
            required property var modelData
            readonly property var shape: gather.formOf(modelData)
            visible: shape.width > 0.5
            x: shape.x
            y: shape.y
            width: shape.width
            height: shape.height
        }
    }
}
