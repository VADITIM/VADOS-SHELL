import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: glance

    required property string key
    required property bool isMirrored
    property bool isShown: false
    property bool isPressed: false
    readonly property bool isCall: key === "call"
    readonly property bool isLive: Activities.liveKeys.includes(key)

    width: Appearance.activity.glyph
    height: Appearance.activity.length - Appearance.activity.padding * 2

    Press {
        target: glance
        isPressed: glance.isPressed
        depth: Motion.press.glyph
    }

    Turn {
        width: Appearance.activity.glyph
        height: width
        isShown: glance.isShown
        enterDuration: Motion.activity.faceEnter
        enterDelay: Motion.activity.faceLeave
        leaveDuration: Motion.activity.faceLeave
        leaveWindow: 0

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
    }

    Turn {
        y: glance.height - height
        width: Appearance.activity.glyph
        height: width
        isShown: glance.isShown
        enterDuration: Motion.activity.faceEnter
        enterDelay: Motion.activity.faceLeave + Motion.activity.stagger
        leaveDuration: Motion.activity.faceLeave
        leaveWindow: 0

        ActivityBars {
            visible: !glance.isCall
            x: (Appearance.activity.glyph - width) / 2
            y: (Appearance.activity.glyph - height) / 2
            width: implicitWidth
            height: implicitHeight
            isRunning: Activities.isPlaying
            color: Activities.isPlaying ? Appearance.color.accent : Appearance.color.textFaint
        }

        Glyph {
            visible: glance.isCall
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
}
