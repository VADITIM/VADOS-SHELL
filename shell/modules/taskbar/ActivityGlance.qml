import QtQuick
import qs.config
import qs.services
import qs.components

Turn {
    id: glance

    required property string key
    required property bool isMirrored
    property bool isPressed: false
    readonly property bool isCall: key === "call"
    readonly property bool isLive: Activities.liveKeys.includes(key)

    width: Appearance.activity.glyph
    height: Appearance.activity.length - Appearance.activity.padding * 2
    enterDuration: Motion.activity.faceEnter
    enterDelay: Motion.activity.faceLeave
    leaveDuration: Motion.activity.faceLeave
    leaveWindow: 0

    Press {
        target: glance
        isPressed: glance.isPressed
        depth: Motion.press.glyph
    }

    Glyph {
        width: Appearance.activity.glyph
        height: width
        name: glance.isCall ? "headset" : "music"
        color: glance.isLive ? Appearance.color.textBody : Appearance.color.textMuted
        transform: Upright {
            isMirrored: glance.isMirrored
            axis: Appearance.activity.glyph / 2
        }
    }

    ActivityBars {
        visible: !glance.isCall
        x: (glance.width - width) / 2
        y: glance.height - height - (Appearance.activity.glyph - height) / 2
        width: implicitWidth
        height: implicitHeight
        isRunning: Activities.isPlaying
        color: Activities.isPlaying ? Appearance.color.accent : Appearance.color.textFaint
    }

    Glyph {
        visible: glance.isCall
        y: glance.height - height
        width: Appearance.activity.glyph
        height: width
        name: Activities.isMicMuted ? "mic-off" : "mic"
        color: Activities.isMicMuted ? Appearance.color.danger : Appearance.color.accent
        transform: Upright {
            isMirrored: glance.isMirrored
            axis: Appearance.activity.glyph / 2
        }
    }
}
