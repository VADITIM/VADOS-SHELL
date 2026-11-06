import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: networkIdle

    idleKey: "network"
    glyphName: "wifi"
    glyphLevel: Network.isWired ? 1 : Network.isEnabled && Network.isConnected ? Math.max(0.1, Network.strength) : 0

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 8

        TypedText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(fullWidth, 130)
            clip: true
            isShown: networkIdle.isUnfolded
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            target: Network.isWired ? "WIRED" : Network.isConnected ? Network.ssid.toUpperCase() : Network.isEnabled ? "NO NETWORK" : "WIFI OFF"
            color: nameArea.containsMouse ? Appearance.color.accent : Network.isConnected ? Appearance.color.text : Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true

            MouseArea {
                id: nameArea
                anchors.fill: parent
                enabled: networkIdle.isUnfolded && Network.isEnabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: networkIdle.host.extensionRequested("network", networkIdle.bodyRect())
            }
        }

        Turn {
            anchors.verticalCenter: parent.verticalCenter
            isShown: networkIdle.isUnfolded
            enterDelay: Motion.pill.elementStagger
            enterDuration: Motion.stateDuration
            enterEasing: Easing.OutBack
            leaveWindow: 0

            GlyphButton {
                label: Network.isEnabled ? "OFF" : "ON"
                onClicked: Network.toggle()
            }
        }
    }
}
