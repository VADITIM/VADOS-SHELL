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
    readonly property bool isMedia: key === "media"
    readonly property bool isCounted: key === "notifications" || key === "tray"
    readonly property bool isLive: Activities.liveKeys.includes(key)
    readonly property var glyphs: ({ call: "headset", media: "music", notifications: "bell", tray: "dots" })
    readonly property int count: key === "notifications" ? Activities.unreadCount : key === "tray" ? Activities.trayItems.length : 0

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
        enterDelay: Motion.pill.sling
        isSlung: true
        leaveWindow: 0

        Glyph {
            width: Appearance.activity.glyph
            height: width
            name: glance.glyphs[glance.key] ?? "music"
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
        enterDelay: Motion.pill.sling + Motion.activity.stagger
        isSlung: true
        leaveWindow: 0

        ActivityBars {
            visible: glance.isMedia
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

        Text {
            visible: glance.isCounted
            width: Appearance.activity.glyph
            height: width
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: glance.count > Appearance.activity.countLimit ? Appearance.activity.countLimit + "+" : glance.count
            color: glance.isLive ? Appearance.color.accent : Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.bold: true
            transform: Upright {
                isMirrored: glance.isMirrored
                axis: Appearance.activity.glyph / 2
            }
        }
    }
}
