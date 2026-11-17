import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    property var disk: null
    readonly property var look: Appearance.widgets
    readonly property real share: disk && disk.total > 0 ? disk.used / disk.total : 0

    function gigabytes(bytes) {
        return Math.round(bytes / 1073741824)
    }

    Binding on disk {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: Hardware.disks.length > 0 ? Hardware.disks[0] : null
    }

    Column {
        anchors.centerIn: parent
        spacing: face.look.captionGap

        Dial {
            anchors.horizontalCenter: parent.horizontalCenter
            width: face.height - Appearance.font.label - face.look.captionGap
            height: width
            value: face.share
            tint: Appearance.bandColor(face.share, face.look.usageBands)
            glyph: "disk"
            isShown: face.isShown
        }

        Roll {
            anchors.horizontalCenter: parent.horizontalCenter
            target: face.disk ? face.gigabytes(face.disk.used) + "/" + face.gigabytes(face.disk.total) + "GB" : "--"
            isShown: face.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
        }
    }
}
