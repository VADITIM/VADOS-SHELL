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

    readonly property var look: Appearance.capture.recording
    readonly property size bodySize: Qt.size(look.width, look.height)
    readonly property var controls: Capture.canPause ? ["pause", "stop"] : ["stop"]
    readonly property real detailsLeft: look.height / 2 + look.head / 2 + Appearance.activity.expanded.detailGap
    readonly property real controlsWidth: controls.length * look.control + (controls.length - 1) * look.controlGap

    width: look.width
    height: look.height

    function controlCenterX(index) {
        const fromRight = controls.length - 1 - index
        return look.width - look.padding - look.control / 2 - fromRight * (look.control + look.controlGap)
    }

    Turn {
        x: view.look.height / 2 - width / 2
        y: view.look.height / 2 - height / 2
        width: view.look.head
        height: view.look.head
        isShown: view.isShown
        enterDuration: Motion.activity.faceEnter
        leaveDuration: Motion.activity.faceLeave
        leaveDelay: Motion.activity.leaveStagger * 2
        leaveWindow: 0

        Rectangle {
            width: view.look.head
            height: view.look.head
            radius: width / 2
            color: Appearance.color.wash

            RecordDot {
                anchors.centerIn: parent
                size: view.look.dot
                isPaused: Capture.isPaused
                isPulsing: view.isShown
            }
        }
    }

    Item {
        id: details
        x: view.detailsLeft
        y: view.look.padding
        width: Math.max(0, view.look.width - view.detailsLeft - view.controlsWidth - view.look.padding * 2)
        height: view.look.height - view.look.padding * 2
        transform: Upright {
            isMirrored: view.host.isMirrored
            axis: details.width / 2
        }

        TypedText {
            id: stateLabel
            target: Capture.isPaused ? "PAUSED" : "RECORDING"
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Capture.isPaused ? Appearance.color.textMuted : Appearance.capture.tint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.activity.expanded.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true
        }

        TypedText {
            y: stateLabel.height + Appearance.activity.expanded.lineGap
            target: Capture.clock
            isShown: view.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.activity.expanded.body
            font.bold: true
        }
    }

    Repeater {
        model: view.controls

        Turn {
            id: control
            required property string modelData
            required property int index
            readonly property bool isPause: modelData === "pause"
            x: view.controlCenterX(index) - width / 2
            y: (view.look.height - height) / 2
            width: view.look.control
            height: view.look.control
            isShown: view.isShown
            enterDelay: (index + 1) * Motion.activity.stagger
            enterDuration: Motion.activity.faceEnter
            leaveDuration: Motion.activity.faceLeave
            leaveDelay: index * Motion.activity.leaveStagger
            leaveWindow: 0

            Press {
                target: control
                isPressed: controlArea.pressed
                depth: Motion.press.glyph
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: controlArea.containsMouse ? Appearance.color.wash : "transparent"
            }

            Glyph {
                anchors.centerIn: parent
                width: Appearance.activity.expanded.controlGlyph
                height: width
                name: control.isPause ? (Capture.isPaused ? "play" : "pause") : "stop"
                color: !control.isPause ? Appearance.capture.tint : controlArea.containsMouse ? Appearance.color.accent : Appearance.color.textBody
                transform: Upright {
                    isMirrored: view.host.isMirrored
                    axis: Appearance.activity.expanded.controlGlyph / 2
                }
            }

            MouseArea {
                id: controlArea
                anchors.fill: parent
                enabled: view.isShown
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: control.isPause ? Capture.togglePause() : Capture.stop()
            }
        }
    }
}
