import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    property date now
    readonly property var look: Appearance.widgets

    Binding on now {
        value: DateTime.now
        when: face.isLive
        restoreMode: Binding.RestoreNone
    }

    Roll {
        id: time
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -date.height / 2
        target: Qt.formatDateTime(face.now, "hh:mm")
        isShown: face.isShown
        holdsWidth: true
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        color: Appearance.color.text
        font.family: Appearance.font.mono
        font.pixelSize: face.look.clock
        font.bold: true
    }

    TypedText {
        id: date
        anchors.top: time.bottom
        target: Qt.formatDateTime(face.now, "dddd dd MMMM").toUpperCase()
        isShown: face.isShown
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        color: Appearance.color.textMuted
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
    }
}
