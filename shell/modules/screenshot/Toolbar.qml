import QtQuick
import qs.config
import qs.components
import "../../utils/Ink.js" as Ink
import "../../utils/Geometry.js" as Geometry

Item {
    id: toolbar

    property bool isShown: false
    property bool isMirrored: false
    property string tool: "select"
    property string shapeKind: "box"
    property color inkColor: Appearance.capture.ink
    property string menu: ""
    property size startSize: Qt.size(Appearance.activity.width, Appearance.activity.length)
    property string startGlyph: ""

    readonly property var look: Appearance.capture
    readonly property real margin: Appearance.taskbar.melt * 2
    readonly property real thickness: look.toolbarThickness
    readonly property real spineX: margin + thickness / 2
    readonly property real length: look.toolPadding * 2 + Ink.tools.length * look.tool + (Ink.tools.length - 1) * look.toolGap
    readonly property real sideX: margin + thickness + look.menuGap
    readonly property real panelWidth: look.wheel + look.wheelPadding * 2
    readonly property real panelHeight: look.wheel + look.gap + look.knob + look.wheelPadding * 2
    readonly property real shapesWidth: Ink.shapes.length * (look.swatch + look.swatchGap)
    readonly property real centerY: height / 2
    readonly property int colorIndex: Ink.tools.findIndex(entry => entry.key === "color")
    readonly property int shapeIndex: Ink.tools.findIndex(entry => entry.key === "shape")
    readonly property real panelY: Math.max(margin, Math.min(height - margin - panelHeight, toolCenterY(colorIndex) - panelHeight / 2))
    readonly property bool isRendering: isShown || !reshape.isArrived
    readonly property real growth: Geometry.clampUnit((reshape.height - startSize.height) / Math.max(1, length - startSize.height))
    property real wheelShare: isShown && menu === "color" ? 1 : 0

    signal toolPicked(string key)
    signal menuToggled(string key)
    signal colorPicked(color value)
    signal shapePicked(string key)

    width: Math.max(sideX + Math.max(panelWidth, shapesWidth), spineX - thickness / 2 + startSize.width) + margin
    height: margin * 2 + Math.max(length, panelHeight, startSize.height)
    transform: Scale {
        origin.x: toolbar.width / 2
        xScale: toolbar.isMirrored ? -1 : 1
    }

    Behavior on wheelShare {
        NumberAnimation {
            duration: Motion.pace(Motion.capture.wheel)
            easing.type: toolbar.wheelShare < 0.5 ? Easing.OutBack : Easing.InQuad
        }
    }

    function toolCenterY(index) {
        return centerY - length / 2 + look.toolPadding + look.tool / 2 + index * (look.tool + look.toolGap)
    }

    function glyphOf(key) {
        if (key === "shape")
            return Ink.shapeOf(shapeKind).glyph
        return Ink.toolOf(key).glyph
    }

    function isPicked(key) {
        return key === menu || (menu.length === 0 && key === tool)
    }

    onIsShownChanged: {
        if (!isShown || reshape.width > 0.5 && !reshape.isArrived)
            return
        reshape.motion.stop()
        reshape.width = startSize.width
        reshape.height = startSize.height
    }

    Reshape {
        id: reshape
        targetWidth: toolbar.isShown ? toolbar.thickness : toolbar.startSize.width
        targetHeight: toolbar.isShown ? toolbar.length : toolbar.startSize.height
        growDuration: Motion.pace(Motion.capture.grow)
        shrinkDuration: Motion.pace(Motion.capture.shrink)
        lag: Motion.pace(Motion.capture.lag)
        overshoot: Motion.capture.overshoot
        arriveShare: Motion.capture.arriveShare
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: toolbar.isRendering
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: Appearance.taskbar.melt

        LiquidShape {
            parent: liquid.shapes
            visible: toolbar.isRendering
            x: toolbar.spineX - Math.min(width, toolbar.thickness) / 2
            y: toolbar.centerY - height / 2
            width: Math.max(reshape.width, 0)
            height: Math.max(reshape.height, 0)
        }

        LiquidShape {
            readonly property real share: toolbar.wheelShare
            parent: liquid.shapes
            readonly property real centerX: Geometry.mix(toolbar.spineX, toolbar.sideX + toolbar.panelWidth / 2, share)
            readonly property real middleY: Geometry.mix(toolbar.toolCenterY(toolbar.colorIndex), toolbar.panelY + toolbar.panelHeight / 2, share)
            visible: share > 0.01
            width: Geometry.mix(toolbar.look.tool, toolbar.panelWidth, share)
            height: Geometry.mix(toolbar.look.tool, toolbar.panelHeight, share)
            x: centerX - width / 2
            y: middleY - height / 2
            radius: Geometry.mix(toolbar.look.tool / 2, toolbar.look.wheelRadius, Geometry.clampUnit(share))
        }
    }

    Glyph {
        x: toolbar.spineX - width / 2
        y: toolbar.centerY - height / 2
        width: Appearance.activity.glyph
        height: width
        visible: toolbar.startGlyph.length > 0 && opacity > 0.01
        opacity: toolbar.isShown ? 1 - Math.min(1, toolbar.growth * 2) : 0
        name: toolbar.startGlyph.length > 0 ? toolbar.startGlyph : "dots"
        color: Appearance.color.text
        transform: Upright {
            isMirrored: toolbar.isMirrored
            axis: Appearance.activity.glyph / 2
        }
    }

    MouseArea {
        x: toolbar.spineX - toolbar.thickness / 2
        y: toolbar.centerY - toolbar.length / 2
        width: toolbar.thickness
        height: toolbar.length
        enabled: toolbar.isShown
    }

    MouseArea {
        x: toolbar.sideX
        y: toolbar.panelY
        width: toolbar.panelWidth
        height: toolbar.panelHeight
        enabled: toolbar.isShown && toolbar.menu === "color"
    }

    ColorWheel {
        x: toolbar.sideX + toolbar.look.wheelPadding
        y: toolbar.panelY + toolbar.look.wheelPadding
        look: toolbar.look
        diameter: toolbar.look.wheel
        wheelShare: toolbar.wheelShare
        sliderShare: toolbar.wheelShare
        color: toolbar.inkColor
        visible: toolbar.wheelShare > 0.01
        enabled: toolbar.isShown && toolbar.menu === "color"
        transform: Upright {
            isMirrored: toolbar.isMirrored
            axis: toolbar.look.wheel / 2
        }
        onPicked: value => toolbar.colorPicked(value)
    }

    Repeater {
        model: Ink.tools

        Turn {
            id: toolFace
            required property var modelData
            required property int index
            x: toolbar.spineX - width / 2
            y: toolbar.toolCenterY(index) - height / 2
            width: toolbar.look.tool
            height: toolbar.look.tool
            isShown: toolbar.isShown
            enterDelay: Math.abs(index - (Ink.tools.length - 1) / 2) * Motion.capture.stagger
            enterDuration: Motion.capture.faceEnter
            leaveDuration: Motion.capture.faceLeave
            leaveWindow: 0

            Press {
                target: toolFace
                isPressed: toolArea.pressed
                depth: Motion.press.glyph
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Appearance.color.wash
                opacity: toolbar.isPicked(toolFace.modelData.key) || toolArea.containsMouse ? 1 : 0
            }

            Glyph {
                anchors.centerIn: parent
                width: toolbar.look.toolGlyph
                height: width
                name: toolbar.glyphOf(toolFace.modelData.key)
                color: toolFace.modelData.key === "color" ? toolbar.inkColor
                    : toolbar.isPicked(toolFace.modelData.key) ? Appearance.color.accent
                    : toolArea.containsMouse ? Appearance.color.text : Appearance.color.textBody
                transform: Upright {
                    isMirrored: toolbar.isMirrored
                    axis: toolbar.look.toolGlyph / 2
                }
            }

            MouseArea {
                id: toolArea
                anchors.fill: parent
                enabled: toolbar.isShown
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const key = toolFace.modelData.key
                    if (key === "color" || key === "shape")
                        toolbar.menuToggled(key)
                    else
                        toolbar.toolPicked(key)
                }
            }
        }
    }

    Repeater {
        model: Ink.shapes

        Turn {
            id: droplet
            required property var modelData
            required property int index
            readonly property real centerX: toolbar.sideX + toolbar.look.swatch / 2 + index * (toolbar.look.swatch + toolbar.look.swatchGap)
            readonly property real middleY: toolbar.toolCenterY(toolbar.shapeIndex)
            x: centerX - width / 2
            y: middleY - height / 2
            width: toolbar.look.swatch
            height: toolbar.look.swatch
            isShown: toolbar.isShown && toolbar.menu === "shape"
            isFlipping: false
            opacity: presence
            enterDelay: index * Motion.capture.stagger
            enterDuration: Motion.capture.menu
            leaveDuration: Motion.capture.faceLeave
            leaveWindow: 0

            LiquidShape {
                readonly property real size: toolbar.look.swatch * droplet.presence
                parent: liquid.shapes
                visible: size > 0.5
                width: size
                height: size
                x: droplet.centerX - size / 2
                y: droplet.middleY - size / 2
            }

            Glyph {
                anchors.centerIn: parent
                width: toolbar.look.swatchGlyph
                height: width
                name: droplet.modelData.glyph
                color: droplet.modelData.key === toolbar.shapeKind ? Appearance.color.accent : dropletArea.containsMouse ? Appearance.color.text : Appearance.color.textBody
                transform: Upright {
                    isMirrored: toolbar.isMirrored
                    axis: toolbar.look.swatchGlyph / 2
                }
            }

            MouseArea {
                id: dropletArea
                anchors.fill: parent
                enabled: droplet.isShown
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: toolbar.shapePicked(droplet.modelData.key)
            }
        }
    }
}
