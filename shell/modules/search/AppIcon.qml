import QtQuick
import qs.config
import "../../utils/Tint.js" as Tint

Item {
    id: icon

    property var app: null
    required property real size
    property bool isSampled: false
    readonly property var tintLook: Appearance.search.foundTint
    property string tint: ""

    width: size
    height: size

    onAppChanged: tint = ""

    Image {
        id: image
        anchors.fill: parent
        source: icon.app?.icon ?? ""
        sourceSize.width: icon.size * 2
        sourceSize.height: icon.size * 2
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        onStatusChanged: if (status === Image.Ready && icon.isSampled) sampler.requestPaint()
    }

    Canvas {
        id: sampler
        width: icon.tintLook.sample
        height: icon.tintLook.sample
        opacity: 0
        enabled: false
        visible: icon.isSampled
        onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            context.drawImage(image, 0, 0, width, height)
            icon.tint = Tint.dominant(context.getImageData(0, 0, width, height).data, icon.tintLook)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width * 0.3
        color: Qt.rgba(1, 1, 1, 0.1)
        visible: icon.app !== null && image.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: (icon.app?.name ?? "?").charAt(0).toUpperCase()
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Math.round(icon.size * 0.48)
            font.bold: true
        }
    }
}
