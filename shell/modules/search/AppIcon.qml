import QtQuick
import qs.config

Item {
    id: icon

    property var app: null
    property real size: Appearance.search.tile

    width: size
    height: size

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
