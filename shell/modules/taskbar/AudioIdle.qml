import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: audioIdle

    idleKey: "audio"
    isAvailable: Audio.isReady
    glyphName: Audio.isMuted ? "muted" : "speaker"
    glyphLevel: Audio.volume
    onScrolled: steps => Audio.setVolume(Audio.volume + steps * 0.05)
    onMiddleClicked: Audio.toggleMute()

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
                    duration: audioIdle.isUnfolded ? Motion.pill.slide : Motion.pill.leaveElement
                    easing.type: audioIdle.isUnfolded ? Easing.OutCubic : Easing.InCubic
                }
            }

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(height * slider.reveal, parent.width * slider.reveal)
                opacity: Math.min(1, slider.reveal * 3)
                height: 6
                radius: 3
                color: Appearance.color.hairline

                Rectangle {
                    width: Math.min(track.width, Math.max(height, slider.width * Math.min(1, Audio.volume)))
                    height: parent.height
                    radius: parent.radius
                    color: Audio.isMuted ? Appearance.color.textFaint : Appearance.color.accent
                }
            }

            MouseArea {
                property real startVolume: 0
                property real startX: 0

                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                onPressed: mouse => {
                    startVolume = Audio.volume
                    startX = mouse.x
                }
                onPositionChanged: mouse => Audio.setVolume(startVolume + (mouse.x - startX) / width)
                onWheel: wheel => Audio.setVolume(Audio.volume + wheel.angleDelta.y / 120 * 0.05)
            }
        }

        TypedText {
            width: 44
            anchors.verticalCenter: parent.verticalCenter
            target: Audio.isMuted ? "MUTE" : Math.round(Audio.volume * 100) + "%"
            isShown: audioIdle.isUnfolded
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Audio.isMuted ? Appearance.color.textMuted : Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing / 2
            font.bold: true

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: Audio.toggleMute()
            }
        }
    }
}
