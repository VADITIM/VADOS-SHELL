import QtQuick
import QtQuick.Shapes
import qs.config
import "../utils/Geometry.js" as Geometry

Column {
    id: picker

    required property var look
    property color color: "white"
    property real hue: 0
    property real saturation: 0
    property real value: 1
    readonly property color current: Qt.hsva(hue, saturation, value, 1)
    property real diameter: picker.look.wheel
    property real sliderShare: 1
    property real wheelShare: 1
    readonly property real radius: diameter / 2
    readonly property bool isDragging: wheelArea.pressed || sliderArea.pressed

    signal picked(color value)

    function adopt(source) {
        if (isDragging)
            return
        if (source.hsvHue >= 0)
            hue = source.hsvHue
        saturation = source.hsvSaturation
        value = source.hsvValue
    }

    function emit() {
        picked(current)
    }

    function pickAt(pointX, pointY) {
        const offsetX = pointX - radius
        const offsetY = radius - pointY
        hue = (Math.atan2(offsetY, offsetX) / (2 * Math.PI) + 1) % 1
        saturation = Math.min(1, Math.hypot(offsetX, offsetY) / radius)
        if (value < 0.05)
            value = 1
        emit()
    }

    function slideTo(pointX) {
        value = Geometry.clampUnit(pointX / slider.width)
        emit()
    }

    onColorChanged: adopt(color)
    Component.onCompleted: adopt(color)

    spacing: picker.look.gap

    Item {
        width: picker.diameter
        height: picker.diameter
        scale: Math.max(0.001, picker.wheelShare)
        rotation: (1 - picker.wheelShare) * picker.look.wheelTurn
        opacity: Geometry.clampUnit(picker.wheelShare)

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillGradient: ConicalGradient {
                    centerX: picker.radius
                    centerY: picker.radius
                    angle: 0
                    GradientStop { position: 0; color: Qt.hsva(0, 1, 1, 1) }
                    GradientStop { position: 1 / 6; color: Qt.hsva(1 / 6, 1, 1, 1) }
                    GradientStop { position: 2 / 6; color: Qt.hsva(2 / 6, 1, 1, 1) }
                    GradientStop { position: 3 / 6; color: Qt.hsva(3 / 6, 1, 1, 1) }
                    GradientStop { position: 4 / 6; color: Qt.hsva(4 / 6, 1, 1, 1) }
                    GradientStop { position: 5 / 6; color: Qt.hsva(5 / 6, 1, 1, 1) }
                    GradientStop { position: 1; color: Qt.hsva(0, 1, 1, 1) }
                }

                PathAngleArc {
                    centerX: picker.radius
                    centerY: picker.radius
                    radiusX: picker.radius
                    radiusY: picker.radius
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: picker.radius
                    centerY: picker.radius
                    centerRadius: picker.radius
                    focalX: picker.radius
                    focalY: picker.radius
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }

                PathAngleArc {
                    centerX: picker.radius
                    centerY: picker.radius
                    radiusX: picker.radius
                    radiusY: picker.radius
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "black"
            opacity: 1 - picker.value
        }

        Rectangle {
            readonly property real angle: picker.hue * 2 * Math.PI
            x: picker.radius + Math.cos(angle) * picker.saturation * picker.radius - width / 2
            y: picker.radius - Math.sin(angle) * picker.saturation * picker.radius - height / 2
            width: picker.look.knob
            height: picker.look.knob
            radius: width / 2
            color: picker.current
            border.width: 2
            border.color: "white"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1.5
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.6)
            }
        }

        MouseArea {
            id: wheelArea
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            onPressed: mouse => picker.pickAt(mouse.x, mouse.y)
            onPositionChanged: mouse => picker.pickAt(mouse.x, mouse.y)
        }
    }

    Item {
        id: slider
        width: picker.diameter
        height: picker.look.knob

        Item {
            width: slider.width * picker.sliderShare
            height: slider.height
            clip: true

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: slider.width
                height: picker.look.slider
                radius: height / 2
                border.width: 1
                border.color: Appearance.color.hairline
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "black" }
                    GradientStop { position: 1; color: Qt.hsva(picker.hue, picker.saturation, 1, 1) }
                }
            }

            Rectangle {
                x: picker.value * (slider.width - width)
                width: picker.look.knob
                height: picker.look.knob
                radius: width / 2
                color: picker.current
                border.width: 2
                border.color: "white"
            }
        }

        MouseArea {
            id: sliderArea
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.SizeHorCursor
            onPressed: mouse => picker.slideTo(mouse.x - 6)
            onPositionChanged: mouse => picker.slideTo(mouse.x - 6)
        }
    }
}
