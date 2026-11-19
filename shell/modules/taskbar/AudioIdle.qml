import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: audioIdle

    idleKey: "audio"
    extensionKey: "audio"
    isAvailable: Audio.isReady
    property string nudge: ""

    glyphName: Audio.isMuted ? "muted" : nudge.length > 0 ? nudge : "speaker"
    glyphLevel: Audio.volume
    hasWheel: true
    onScrolled: steps => nudgeVolume(steps * Appearance.taskbar.volumeStep)
    onMiddleClicked: Audio.toggleMute()

    function nudgeVolume(change) {
        Audio.setVolume(Audio.volume + change)
        nudge = change > 0 ? "volume-up" : "volume-down"
        nudgeTimer.restart()
    }

    Timer {
        id: nudgeTimer
        interval: Motion.reveal.nudge
        onTriggered: audioIdle.nudge = ""
    }

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 10

        Item {
            id: slider

            property real reveal: audioIdle.isUnfolded ? 1 : 0

            width: 112
            height: parent.height

            Behavior on reveal {
                NumberAnimation {
                    duration: Motion.pace(audioIdle.isUnfolded ? Motion.pill.slide : Motion.pill.leaveElement)
                    easing.type: audioIdle.isUnfolded ? Easing.OutCubic : Easing.InCubic
                }
            }

            Slider {
                height: parent.height
                width: Math.max(Appearance.taskbar.volumeTrack * slider.reveal, parent.width * slider.reveal)
                opacity: Math.min(1, slider.reveal * 3)
                value: Audio.volume
                isMuted: Audio.isMuted
                canScroll: true
                look: ({
                    track: Appearance.taskbar.volumeTrack,
                    grab: Appearance.taskbar.idleSize,
                    step: Appearance.taskbar.volumeStep
                })
                pace: ({
                    settle: Motion.extension.slide,
                    thicken: Motion.extension.trackHeld
                })
                onMoved: value => Audio.setVolume(value)
                onScrolled: steps => audioIdle.nudgeVolume(steps * Appearance.taskbar.volumeStep)
            }
        }

        ScrambleText {
            width: 44
            anchors.verticalCenter: parent.verticalCenter
            label: "volume"
            target: Audio.isMuted ? "MUTE" : Math.round(Audio.volume * 100) + "%"
            isShown: audioIdle.isUnfolded
            color: Audio.isMuted ? Appearance.color.textMuted : Appearance.color.text

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.stateDuration)
                    easing.type: Easing.OutQuad
                }
            }
            spacing: Appearance.font.labelSpacing / 2

            MouseArea {
                property string hoverName: Audio.isMuted ? "UNMUTE" : "MUTE"
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute()
            }
        }
    }
}
