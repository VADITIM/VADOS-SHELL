import QtQuick
import QtQuick.Effects
import qs.config

Item {
    id: backdrop

    required property bool isShown
    property string source: ""
    property int blur: 0
    property real detail: 1
    property color ground: "black"
    property bool isImmediate: false
    readonly property bool isRendering: isShown && opacity > 0
    readonly property int blurRadius: Rendering.blur(blur)
    readonly property bool hasPicture: picture.status === Image.Ready
    readonly property bool isBlurring: isRendering && blurRadius > 0 && hasPicture
    readonly property int bleed: isBlurring ? blurRadius : 0

    visible: isRendering
    clip: true

    Rectangle {
        objectName: "ground"
        anchors.fill: parent
        color: backdrop.ground
    }

    Image {
        id: picture
        objectName: "picture"
        anchors.fill: parent
        anchors.margins: -backdrop.bleed
        source: backdrop.source.length === 0 || backdrop.width < 1 || backdrop.height < 1 ? "" : backdrop.source.startsWith("/") ? "file://" + backdrop.source : backdrop.source
        sourceSize: Qt.size(Math.max(1, Math.round(backdrop.width * backdrop.detail)), Math.max(1, Math.round(backdrop.height * backdrop.detail)))
        fillMode: Image.PreserveAspectCrop
        asynchronous: !backdrop.isImmediate
        cache: true
        smooth: true
    }

    ShaderEffectSource {
        id: pictureTexture
        objectName: "pictureTexture"
        anchors.fill: picture
        sourceItem: picture
        hideSource: backdrop.isBlurring
        live: backdrop.isBlurring
        visible: false
    }

    MultiEffect {
        objectName: "blurPass"
        anchors.fill: picture
        source: pictureTexture
        visible: backdrop.isBlurring
        blurEnabled: backdrop.isBlurring
        blur: 1
        blurMax: backdrop.blurRadius
        autoPaddingEnabled: false
    }
}
