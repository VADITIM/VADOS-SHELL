import QtQuick
import qs.config

Text {
    property var stroke: ({ points: [{ x: 0, y: 0 }], text: "", color: "white", width: Appearance.capture.textSize })

    x: stroke.points[0].x
    y: stroke.points[0].y
    text: stroke.text ?? ""
    color: stroke.color
    font.family: Appearance.font.fixedMono
    font.pixelSize: stroke.width
    font.bold: true
    style: Text.Outline
    styleColor: Appearance.color.shadow
}
