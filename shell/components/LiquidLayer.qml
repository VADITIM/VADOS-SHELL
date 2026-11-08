import QtQuick
import QtQuick.Effects
import qs.config

Item {
    id: liquid

    required property bool isShown
    property color fill: "black"
    property color rim: "grey"
    property real fillAlpha: 1
    property int melt: 12
    property real fillThreshold: Appearance.liquid.fillThreshold
    property real rimThreshold: Appearance.liquid.rimThreshold
    readonly property Item shapes: shapeHolder
    readonly property bool isRendering: isShown && opacity > 0
    readonly property int blurRadius: Rendering.blur(melt)
    readonly property bool isBlurring: isRendering && blurRadius > 0

    visible: isRendering

    Item {
        id: shapeHolder
        anchors.fill: parent
    }

    ShaderEffectSource {
        id: shapeTexture
        objectName: "shapeTexture"
        anchors.fill: parent
        sourceItem: shapeHolder
        hideSource: true
        live: liquid.isRendering
        visible: false
    }

    MultiEffect {
        id: blurredShapes
        objectName: "blurPass"
        anchors.fill: parent
        source: shapeTexture
        visible: liquid.isBlurring
        blurEnabled: liquid.isBlurring
        blur: 1
        blurMax: liquid.blurRadius
    }

    ShaderEffectSource {
        id: blurredTexture
        objectName: "blurredTexture"
        anchors.fill: parent
        sourceItem: blurredShapes
        hideSource: true
        live: liquid.isBlurring
        visible: false
    }

    Rectangle {
        id: rimSurface
        objectName: "rimSurface"
        anchors.fill: parent
        color: liquid.rim
        visible: false
        layer.enabled: liquid.isBlurring
    }

    Rectangle {
        id: fillSurface
        objectName: "fillSurface"
        anchors.fill: parent
        color: liquid.fill
        visible: false
        layer.enabled: liquid.isRendering
    }

    Item {
        objectName: "passes"
        anchors.fill: parent
        opacity: liquid.fillAlpha
        layer.enabled: liquid.isBlurring && liquid.fillAlpha < 1

        MultiEffect {
            objectName: "rimPass"
            anchors.fill: parent
            source: rimSurface
            visible: liquid.isBlurring
            maskEnabled: true
            maskSource: blurredTexture
            maskThresholdMin: liquid.rimThreshold
            maskSpreadAtMin: Appearance.liquid.edgeSoftness
        }

        MultiEffect {
            objectName: "fillPass"
            anchors.fill: parent
            source: fillSurface
            visible: liquid.isBlurring
            maskEnabled: true
            maskSource: blurredTexture
            maskThresholdMin: liquid.fillThreshold
            maskSpreadAtMin: Appearance.liquid.edgeSoftness
        }

        MultiEffect {
            objectName: "corePass"
            anchors.fill: parent
            source: fillSurface
            maskEnabled: true
            maskSource: shapeTexture
            maskThresholdMin: Appearance.liquid.coreThreshold
            maskSpreadAtMin: Appearance.liquid.coreSoftness
        }
    }
}
