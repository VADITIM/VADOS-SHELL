import QtQuick
import QtQuick.Effects

Item {
    id: masked

    default property alias content: contentHolder.data
    property alias mask: maskHolder.data
    readonly property bool isRendering: visible && opacity > 0

    Item {
        id: maskHolder
        objectName: "maskShape"
        anchors.fill: parent
        visible: false
        layer.enabled: masked.isRendering
    }

    Item {
        id: contentHolder
        objectName: "maskedContent"
        anchors.fill: parent
        layer.enabled: masked.isRendering
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskHolder
        }
    }
}
