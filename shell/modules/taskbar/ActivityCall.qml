import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: view

    required property Item host
    required property Item pill
    property bool isShown: false
    property real expansion: 0

    readonly property var look: Appearance.activity.call
    readonly property size bodySize: Qt.size(look.width, look.height)
    readonly property real headSize: look.head * Math.min(1.1, expansion) * pill.popScale
    readonly property real detailsLeft: look.height / 2 + look.avatar / 2 + Appearance.activity.expanded.detailGap
    readonly property string elapsed: {
        const minutes = Math.floor(Activities.callSeconds / 60)
        const seconds = Activities.callSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    width: look.width
    height: look.height

    LiquidShape {
        parent: view.host.liquidShapes
        visible: view.headSize > 0.5
        width: view.headSize
        height: view.headSize
        x: view.pill.x + view.pill.expandedLeft + view.pill.bodyHeight / 2 - width / 2
        y: view.pill.y - height / 2
    }

    Turn {
        x: view.look.height / 2 - width / 2
        y: view.look.height / 2 - height / 2
        width: view.look.avatar
        height: view.look.avatar
        isShown: view.isShown
        enterDuration: Motion.activity.faceEnter
        leaveDuration: Motion.activity.faceLeave
        leaveDelay: Motion.activity.leaveStagger * 3
        leaveWindow: 0

        Rectangle {
            width: view.look.avatar
            height: view.look.avatar
            radius: width / 2
            color: Appearance.color.wash
            border.width: Appearance.activity.media.ringStroke
            border.color: Appearance.color.hairline

            Glyph {
                anchors.centerIn: parent
                width: Appearance.activity.expanded.glyph * 1.6
                height: width
                name: "headset"
                color: Appearance.color.accent
                transform: Upright {
                    isMirrored: view.host.isMirrored
                    axis: Appearance.activity.expanded.glyph * 0.8
                }
            }
        }
    }

    Item {
        id: details
        x: view.detailsLeft
        y: view.look.padding
        width: view.look.width - view.detailsLeft - view.look.padding
        height: view.look.height - view.look.padding * 2
        transform: Upright {
            isMirrored: view.host.isMirrored
            axis: details.width / 2
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.activity.expanded.lineGap

            ScrambleText {
                label: "activity call source"
                target: Activities.callSource.toUpperCase()
                isShown: view.isShown
                color: Appearance.color.textMuted
                pixelSize: Appearance.activity.expanded.smallLabel
            }

            ScrambleText {
                label: "activity call status"
                target: Activities.isCalling ? "IN VOICE" : "NO CALL"
                isShown: view.isShown
                color: Appearance.color.text
                pixelSize: Appearance.activity.expanded.smallBody
                spacing: 0
            }

            ScrambleText {
                label: "activity call time"
                target: Activities.isCalling ? view.elapsed : ""
                isShown: view.isShown
                color: Appearance.color.accent
                pixelSize: Appearance.activity.expanded.smallBody
                isBold: false
                spacing: 0
            }
        }
    }

    ActivityBuds {
        host: view.host
        pill: view.pill
        x: -view.x
        y: -view.y
        side: -1
        label: "activity call controls"
        isShown: view.isShown
        items: [
            { key: "mic", glyph: Activities.isMicMuted ? "mic-off" : "mic", isOff: Activities.isMicMuted },
            { key: "deafen", glyph: Activities.isDeafened ? "deafened" : "headphones", isOff: Activities.isDeafened }
        ]
        onChosen: key => key === "mic" ? Activities.toggleMic() : Activities.toggleDeafen()
    }
}
