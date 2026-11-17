import QtQuick
import qs.config

Item {
    id: stage

    property var shots: []

    Rectangle {
        anchors.fill: parent
        color: Appearance.color.ground
    }

    Repeater {
        model: stage.shots.slice().sort((first, second) => first.order - second.order)

        Image {
            required property var modelData
            x: modelData.side === "right" ? stage.width - width : 0
            width: modelData.width
            height: modelData.height
            source: modelData.url
            cache: true
            smooth: true
        }
    }
}
