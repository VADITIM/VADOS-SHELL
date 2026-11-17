import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    property var reading: ({ isPresent: false, level: 0, isCharging: false })
    readonly property var look: Appearance.widgets

    Binding on reading {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: ({ isPresent: Battery.isPresent, level: Battery.level, isCharging: Battery.isCharging })
    }

    Column {
        anchors.centerIn: parent
        spacing: face.look.captionGap

        Dial {
            anchors.horizontalCenter: parent.horizontalCenter
            width: face.height - Appearance.font.label - face.look.captionGap
            height: width
            value: face.reading.isPresent ? face.reading.level : 0
            tint: Appearance.chargeColor(face.reading.level, face.reading.isCharging)
            glyph: "battery"
            level: face.reading.level
            isCharging: face.reading.isCharging
            isShown: face.isShown
        }

        Roll {
            anchors.horizontalCenter: parent.horizontalCenter
            target: face.reading.isPresent ? String(Math.round(face.reading.level * 100)).padStart(3, " ") + "%" : "AC"
            isShown: face.isShown
            holdsWidth: true
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
        }
    }
}
