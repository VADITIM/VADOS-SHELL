import QtQuick
import qs.config
import qs.components

Item {
    id: extension

    required property bool isMirrored
    property string extensionKey: ""
    property string heldKey: ""
    property rect body: Qt.rect(0, 0, 0, 0)
    property real lift: 0
    property bool isBatteryProtected: false
    readonly property bool isOpen: extensionKey.length > 0
    readonly property bool isHeld: lift > 0.001
    readonly property bool isContentShown: isOpen && lift > Motion.extension.contentShare
    readonly property real safeX: Appearance.extension.safeReach
    readonly property real safeY: Appearance.extension.safeReach
    readonly property real inputWidth: isHeld ? body.x + body.width + safeX : 0
    readonly property real inputTop: Math.max(0, body.y - safeY)
    readonly property real inputHeight: Math.min(height, body.y + body.height + safeY) - inputTop
    property bool hasEntered: false
    readonly property bool isTyping: isOpen && loader.item !== null && loader.item.isTyping === true

    signal closeRequested()
    signal batteryProtectRequested(bool isProtected)

    transform: Upright {
        isMirrored: extension.isMirrored
        axis: extension.width / 2
    }

    onExtensionKeyChanged: {
        if (extensionKey.length > 0)
            heldKey = extensionKey
        hasEntered = false
    }

    Timer {
        interval: extension.hasEntered ? Motion.extension.linger : Motion.extension.grace
        running: extension.isOpen && !hover.hovered && !bodyHover.hovered && !extension.isTyping
        onTriggered: extension.closeRequested()
    }

    Item {
        y: extension.body.y - extension.safeY
        width: extension.body.x + extension.body.width + extension.safeX
        height: extension.body.height + extension.safeY * 2
        visible: extension.isHeld

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered)
                    extension.hasEntered = true
            }
        }
    }

    Item {
        x: extension.body.x
        y: extension.body.y
        width: extension.body.width
        height: extension.body.height
        visible: extension.isHeld
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        HoverHandler {
            id: bodyHover
            onHoveredChanged: {
                if (hovered)
                    extension.hasEntered = true
            }
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
                sourceComponent: !extension.isOpen && !extension.isHeld ? null : extension.heldKey === "network" ? networkPage : extension.heldKey === "audio" ? audioPage : extension.heldKey === "power" ? powerPage : null
                onLoaded: {
                    item.isOpen = Qt.binding(() => extension.isOpen)
                    item.isShown = Qt.binding(() => extension.isContentShown)
                }
            }
        }
    }

    Component {
        id: networkPage

        NetworkPage {}
    }

    Component {
        id: audioPage

        AudioPage {}
    }

    Component {
        id: powerPage

        PowerPage {
            isProtected: extension.isBatteryProtected
            onProtectRequested: isProtected => extension.batteryProtectRequested(isProtected)
        }
    }
}
