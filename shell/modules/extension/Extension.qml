import QtQuick
import qs.config
import qs.components

Item {
    id: extension

    required property bool isMirrored
    required property real inset
    property string extensionKey: ""
    property string heldKey: ""
    property rect origin: Qt.rect(0, 0, 0, 0)
    property real growth: isOpen ? 1 : 0
    readonly property bool isOpen: extensionKey.length > 0
    readonly property bool isHolding: isOpen || growth > Motion.extension.handBack
    readonly property bool isContentShown: isOpen && growth > Motion.extension.contentShare
    readonly property real targetWidth: Math.max(origin.width, Appearance.extension.width)
    readonly property real targetHeight: height - Appearance.taskbar.margin * 2
    readonly property real bodyLeft: origin.x + (inset - origin.x) * growth
    readonly property real bodyTop: origin.y + (Appearance.taskbar.margin - origin.y) * growth
    readonly property real bodyWidth: origin.width + (targetWidth - origin.width) * growth
    readonly property real bodyHeight: origin.height + (targetHeight - origin.height) * growth
    readonly property real inputWidth: growth > 0.01 ? bodyLeft + bodyWidth + Appearance.taskbar.tipGap : 0

    signal closeRequested()

    transform: Upright {
        isMirrored: extension.isMirrored
        axis: extension.width / 2
    }

    onExtensionKeyChanged: {
        if (extensionKey.length > 0)
            heldKey = extensionKey
    }

    Behavior on growth {
        NumberAnimation {
            duration: Motion.pace(extension.isOpen ? Motion.extension.grow : Motion.extension.shrink)
            easing.type: Easing.InOutCubic
        }
    }

    Timer {
        interval: Motion.extension.linger
        running: extension.isOpen && !hover.hovered
        onTriggered: extension.closeRequested()
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: Appearance.extension.melt
        visible: extension.growth > 0.001

        LiquidShape {
            parent: liquid.shapes
            x: extension.bodyLeft
            y: extension.bodyTop
            width: extension.bodyWidth
            height: extension.bodyHeight
            radius: Math.min(Math.min(width, height) / 2, Appearance.extension.radius)
        }
    }

    Item {
        x: extension.bodyLeft
        y: extension.bodyTop
        width: extension.bodyWidth
        height: extension.bodyHeight
        visible: extension.growth > 0.001

        HoverHandler {
            id: hover
        }

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: page
            anchors.fill: parent
            anchors.margins: Appearance.extension.padding
            transform: Upright {
                isMirrored: extension.isMirrored
                axis: page.width / 2
            }

            Loader {
                id: loader
                anchors.fill: parent
                sourceComponent: extension.heldKey === "network" ? networkPage : null
                onLoaded: {
                    item.isOpen = Qt.binding(() => extension.isOpen)
                    item.isShown = Qt.binding(() => extension.isContentShown)
                }
            }

            Connections {
                target: loader.item
                ignoreUnknownSignals: true

                function onCloseRequested() {
                    extension.closeRequested()
                }
            }
        }
    }

    Component {
        id: networkPage

        NetworkPage {}
    }
}
