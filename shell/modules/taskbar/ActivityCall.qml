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
    readonly property real dropShare: Math.max(0, Math.min(1, (expansion - Motion.activity.dropStart) / (1 - Motion.activity.dropStart)))
    readonly property real detailsLeft: look.height / 2 + look.avatar / 2 + Appearance.activity.expanded.detailGap
    readonly property string elapsed: {
        const minutes = Math.floor(Activities.callSeconds / 60)
        const seconds = Activities.callSeconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    width: look.width
    height: look.height

    function dropCenterX(index) {
        return look.width - look.height / 2 - index * (look.drop + look.dropSpacing)
    }

    Repeater {
        parent: view.host.liquidShapes
        model: 2

        LiquidShape {
            required property int index
            readonly property real size: view.look.drop * view.dropShare * view.pill.popScale
            visible: size > 0.5
            width: size
            height: size
            x: view.pill.x + view.x + view.dropCenterX(index) - size / 2
            y: view.pill.y + view.pill.bodyHeight / 2 + (view.look.drop / 2 + view.look.dropGap) * view.dropShare - size / 2
        }
    }

    Turn {
        id: avatarTurn
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

            Glyph {
                anchors.centerIn: parent
                width: Appearance.activity.expanded.glyph * 1.4
                height: width
                name: "headset"
                color: Appearance.color.accent
                transform: Upright {
                    isMirrored: view.host.isMirrored
                    axis: Appearance.activity.expanded.glyph * 0.7
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

        TypedText {
            id: sourceLabel
            target: Activities.callSource.toUpperCase()
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.activity.expanded.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true
        }

        TypedText {
            id: statusLine
            y: sourceLabel.height + Appearance.activity.expanded.lineGap
            target: Activities.isCalling ? "IN VOICE" : "NO CALL"
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.activity.expanded.body
            font.bold: true
        }

        TypedText {
            y: statusLine.y + statusLine.height + Appearance.activity.expanded.lineGap
            target: Activities.isCalling ? view.elapsed : ""
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.accent
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.activity.expanded.body
        }
    }

    Repeater {
        model: ["mic", "deafen"]

        Turn {
            id: dropFace
            required property string modelData
            required property int index
            readonly property bool isMic: modelData === "mic"
            readonly property bool isOff: isMic ? Activities.isMicMuted : Activities.isDeafened
            x: view.dropCenterX(index) - width / 2
            y: view.look.height + view.look.dropGap + (view.look.drop - height) / 2
            width: Appearance.activity.expanded.glyph
            height: Appearance.activity.expanded.glyph
            isShown: view.isShown
            enterDelay: (index + 2) * Motion.activity.stagger
            enterDuration: Motion.activity.faceEnter
            leaveDuration: Motion.activity.faceLeave
            leaveDelay: index * Motion.activity.leaveStagger
            leaveWindow: 0

            Press {
                target: dropFace
                isPressed: dropArea.pressed
                depth: Motion.press.glyph
            }

            Glyph {
                anchors.fill: parent
                name: dropFace.isMic ? (dropFace.isOff ? "mic-off" : "mic") : (dropFace.isOff ? "deafened" : "headphones")
                color: dropFace.isOff ? Appearance.color.danger : dropArea.containsMouse ? Appearance.color.accent : Appearance.color.textBody
                transform: Upright {
                    isMirrored: view.host.isMirrored
                    axis: Appearance.activity.expanded.glyph / 2
                }
            }

            MouseArea {
                id: dropArea
                anchors.centerIn: parent
                width: view.look.drop
                height: view.look.drop
                enabled: view.isShown
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dropFace.isMic ? Activities.toggleMic() : Activities.toggleDeafen()
            }
        }
    }
}
