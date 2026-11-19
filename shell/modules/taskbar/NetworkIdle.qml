import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: networkIdle

    idleKey: "network"
    extensionKey: "network"
    glyphName: Network.isWired || Network.isConnected ? "wifi" : Network.isEnabled ? "wifi-error" : "wifi-off"
    glyphLevel: Network.isWired ? 1 : Network.isEnabled && Network.isConnected ? Math.max(0.1, Network.strength) : 0

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 8

        ScrambleText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 130)
            clip: true
            label: "network name"
            isShown: networkIdle.isUnfolded
            target: Network.isWired ? "WIRED" : Network.isConnected ? Network.ssid.toUpperCase() : Network.isEnabled ? "NO NETWORK" : "WIFI OFF"
            color: nameArea.containsMouse ? Appearance.color.accent : Network.isConnected ? Appearance.color.text : Appearance.color.textMuted

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.stateDuration)
                    easing.type: Easing.OutQuad
                }
            }

            MouseArea {
                id: nameArea
                property string hoverName: "NETWORKS"
                anchors.fill: parent
                enabled: networkIdle.isUnfolded && Network.isEnabled
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: networkIdle.extend()
            }
        }
    }
}
