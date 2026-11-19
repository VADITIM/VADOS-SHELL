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
    property string frostSource: ""
    property size frostSize: Qt.size(width, height)
    property bool isFrostMirrored: false
    readonly property int frostRadius: Rendering.frost
    readonly property bool wantsFrost: isRendering && frostRadius > 0 && frostSource.length > 0
    readonly property bool isFrosting: wantsFrost && frostPicture.status === Image.Ready
    readonly property int frostBleed: isFrosting ? frostRadius : 0

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

    Item {
        id: frostHolder
        objectName: "frostHolder"
        x: -liquid.frostBleed
        y: -liquid.frostBleed
        width: liquid.width + liquid.frostBleed * 2
        height: liquid.height + liquid.frostBleed * 2
        clip: true

        Image {
            id: frostPicture
            objectName: "frostPicture"
            width: liquid.frostSize.width + liquid.frostBleed * 2
            height: liquid.frostSize.height + liquid.frostBleed * 2
            source: !liquid.wantsFrost ? "" : liquid.frostSource.startsWith("/") ? "file://" + liquid.frostSource : liquid.frostSource
            sourceSize: Qt.size(Math.max(1, Math.round(liquid.frostSize.width * Appearance.liquid.frostDetail)), Math.max(1, Math.round(liquid.frostSize.height * Appearance.liquid.frostDetail)))
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            transform: Upright {
                isMirrored: liquid.isFrostMirrored
                axis: frostPicture.width / 2
            }
        }
    }

    ShaderEffectSource {
        id: frostTexture
        objectName: "frostTexture"
        anchors.fill: frostHolder
        sourceItem: frostHolder
        hideSource: true
        live: liquid.isFrosting
        visible: false
    }

    MultiEffect {
        id: frostBlur
        objectName: "frostBlurPass"
        anchors.fill: frostHolder
        source: frostTexture
        visible: liquid.isFrosting
        blurEnabled: liquid.isFrosting
        blur: 1
        blurMax: liquid.frostRadius
        autoPaddingEnabled: false
    }

    ShaderEffectSource {
        id: frostBlurred
        objectName: "frostBlurred"
        anchors.fill: parent
        sourceItem: frostBlur
        sourceRect: Qt.rect(liquid.frostBleed, liquid.frostBleed, liquid.width, liquid.height)
        hideSource: true
        live: liquid.isFrosting
        visible: false
    }

    Rectangle {
        id: rimSurface
        objectName: "rimSurface"
        anchors.fill: parent
        color: liquid.rim
    }

    ShaderEffectSource {
        id: rimTexture
        objectName: "rimTexture"
        anchors.fill: parent
        sourceItem: rimSurface
        hideSource: true
        live: liquid.isBlurring
        visible: false
    }

    Rectangle {
        id: fillSurface
        objectName: "fillSurface"
        anchors.fill: parent
        color: liquid.fill
    }

    ShaderEffectSource {
        id: fillTexture
        objectName: "fillTexture"
        anchors.fill: parent
        sourceItem: fillSurface
        hideSource: true
        live: liquid.isRendering
        visible: false
    }

    MultiEffect {
        objectName: "frostPass"
        anchors.fill: parent
        source: frostBlurred
        visible: liquid.isFrosting
        maskEnabled: true
        maskSource: liquid.isBlurring ? blurredTexture : shapeTexture
        maskThresholdMin: liquid.isBlurring ? liquid.fillThreshold : Appearance.liquid.coreThreshold
        maskSpreadAtMin: liquid.isBlurring ? Appearance.liquid.edgeSoftness : Appearance.liquid.coreSoftness
    }

    Item {
        objectName: "passes"
        anchors.fill: parent
        opacity: liquid.fillAlpha
        layer.enabled: liquid.isBlurring && liquid.fillAlpha < 1

        MultiEffect {
            objectName: "rimPass"
            anchors.fill: parent
            source: rimTexture
            visible: liquid.isBlurring
            maskEnabled: true
            maskSource: blurredTexture
            maskThresholdMin: liquid.rimThreshold
            maskSpreadAtMin: Appearance.liquid.edgeSoftness
        }

        MultiEffect {
            objectName: "fillPass"
            anchors.fill: parent
            source: fillTexture
            visible: liquid.isBlurring
            maskEnabled: true
            maskSource: blurredTexture
            maskThresholdMin: liquid.fillThreshold
            maskSpreadAtMin: Appearance.liquid.edgeSoftness
        }

        MultiEffect {
            objectName: "corePass"
            anchors.fill: parent
            source: fillTexture
            maskEnabled: true
            maskSource: shapeTexture
            maskThresholdMin: Appearance.liquid.coreThreshold
            maskSpreadAtMin: Appearance.liquid.coreSoftness
        }
    }
}
