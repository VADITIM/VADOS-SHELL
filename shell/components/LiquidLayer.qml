import QtQuick
import QtQuick.Effects
import qs.config

Item {
    id: liquid

    property color fill: "black"
    property color rim: "grey"
    property real fillAlpha: 1
    property int melt: 12
    property real fillThreshold: Appearance.liquid.fillThreshold
    property real rimThreshold: Appearance.liquid.rimThreshold
    readonly property Item shapes: shapeHolder

    Item {
        id: shapeHolder
        anchors.fill: parent
    }

    ShaderEffectSource {
        id: shapeTexture
        anchors.fill: parent
        sourceItem: shapeHolder
        hideSource: true
        live: true
        visible: false
    }

    MultiEffect {
        id: blurredShapes
        anchors.fill: parent
        source: shapeTexture
        blurEnabled: true
        blur: 1
        blurMax: liquid.melt
    }

    ShaderEffectSource {
        id: blurredTexture
        anchors.fill: parent
        sourceItem: blurredShapes
        hideSource: true
        live: true
        visible: false
    }

    Rectangle {
        id: rimSurface
        anchors.fill: parent
        color: liquid.rim
        visible: false
        layer.enabled: true
    }

    Rectangle {
        id: fillSurface
        anchors.fill: parent
        color: liquid.fill
        visible: false
        layer.enabled: true
    }

    Item {
        anchors.fill: parent
        opacity: liquid.fillAlpha
        layer.enabled: liquid.fillAlpha < 1

        MultiEffect {
            anchors.fill: parent
            source: rimSurface
            maskEnabled: true
            maskSource: blurredTexture
            maskThresholdMin: liquid.rimThreshold
            maskSpreadAtMin: Appearance.liquid.edgeSoftness
        }

        MultiEffect {
            anchors.fill: parent
            source: fillSurface
            maskEnabled: true
            maskSource: blurredTexture
            maskThresholdMin: liquid.fillThreshold
            maskSpreadAtMin: Appearance.liquid.edgeSoftness
        }

        MultiEffect {
            anchors.fill: parent
            source: fillSurface
            maskEnabled: true
            maskSource: shapeTexture
            maskThresholdMin: Appearance.liquid.coreThreshold
            maskSpreadAtMin: Appearance.liquid.coreSoftness
        }
    }
}
