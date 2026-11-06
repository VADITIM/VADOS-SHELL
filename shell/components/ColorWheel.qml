import QtQuick
import QtQuick.Shapes
import qs.config

Column {
    id: picker

    property color color: "white"
    property real hue: 0
    property real saturation: 0
    property real value: 1
    readonly property color current: Qt.hsva(hue, saturation, value, 1)
    readonly property real diameter: Appearance.settings.wheel
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
        if (!hexInput.activeFocus)
            hexInput.text = hexOf(source)
    }

    function hexOf(source) {
        return source.toString().toUpperCase()
    }

    function emit() {
        if (!hexInput.activeFocus)
            hexInput.text = hexOf(current)
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
        value = Math.max(0, Math.min(1, pointX / slider.width))
        emit()
    }

    onColorChanged: adopt(color)
    Component.onCompleted: adopt(color)

    spacing: Appearance.settings.gap

    Item {
        width: picker.diameter
        height: picker.diameter

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
            width: Appearance.settings.knob
            height: Appearance.settings.knob
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
            onPressed: mouse => {
                hexInput.focus = false
                picker.pickAt(mouse.x, mouse.y)
            }
            onPositionChanged: mouse => picker.pickAt(mouse.x, mouse.y)
        }
    }

    Item {
        id: slider
        width: picker.diameter
        height: Appearance.settings.knob

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Appearance.settings.slider
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
            width: Appearance.settings.knob
            height: Appearance.settings.knob
            radius: width / 2
            color: picker.current
            border.width: 2
            border.color: "white"
        }

        MouseArea {
            id: sliderArea
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.SizeHorCursor
            onPressed: mouse => {
                hexInput.focus = false
                picker.slideTo(mouse.x - 6)
            }
            onPositionChanged: mouse => picker.slideTo(mouse.x - 6)
        }
    }

    Row {
        spacing: 10

        Rectangle {
            width: Appearance.settings.swatch
            height: Appearance.settings.swatch
            radius: Appearance.radius.medium
            color: picker.current
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
        }

        Rectangle {
            width: picker.diameter - Appearance.settings.swatch - 10
            height: Appearance.settings.field
            radius: Appearance.radius.medium
            color: Appearance.color.panel
            border.width: 1
            border.color: hexInput.activeFocus ? Appearance.color.accent : Appearance.color.hairline

            TextInput {
                id: hexInput
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                maximumLength: 7
                color: Appearance.color.text
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.settings.hexText
                font.capitalization: Font.AllUppercase
                onTextEdited: {
                    const candidate = (text.trim().startsWith("#") ? "" : "#") + text.trim()
                    if (!/^#[0-9a-fA-F]{6}$/.test(candidate))
                        return
                    const parsed = Qt.color(candidate)
                    if (parsed.hsvHue >= 0)
                        picker.hue = parsed.hsvHue
                    picker.saturation = parsed.hsvSaturation
                    picker.value = parsed.hsvValue
                    picker.picked(parsed)
                }
                onEditingFinished: text = picker.hexOf(picker.current)
            }
        }
    }
}
