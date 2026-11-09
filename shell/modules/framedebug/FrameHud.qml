import QtQuick
import qs.config

Item {
    id: hud

    property string counter: ""
    property string label: ""
    property bool isActive: false
    property bool isReplay: false
    property var replayShots: []
    property var snapshotShots: []

    readonly property int margin: Appearance.unit.extraLarge
    readonly property string idleLabel: "NO ANIMATION"
    readonly property string hint: "UP RIGHT NEXT FRAME   DOWN LEFT PREVIOUS   PLUS COPY   ESC RESUME"

    signal stepRequested()
    signal backRequested()
    signal shotRequested()
    signal closeRequested()

    function capture(callback) {
        return snapshot.grabToImage(callback, Qt.size(Math.round(snapshot.width * Screen.devicePixelRatio), Math.round(snapshot.height * Screen.devicePixelRatio)))
    }

    focus: true
    Keys.onPressed: event => {
        event.accepted = true
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Right)
            stepRequested()
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Left)
            backRequested()
        else if (event.key === Qt.Key_Plus)
            shotRequested()
        else if (event.key === Qt.Key_Escape)
            closeRequested()
        else
            event.accepted = false
    }

    FrameStage {
        anchors.fill: parent
        visible: hud.isReplay
        shots: hud.replayShots
    }

    FrameStage {
        id: snapshot
        x: -2 * width
        width: hud.width
        height: hud.height
        shots: hud.snapshotShots
    }

    Rectangle {
        visible: hud.isActive
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: hud.margin
        width: column.implicitWidth + 2 * Appearance.unit.large
        height: column.implicitHeight + 2 * Appearance.unit.medium
        radius: Appearance.radius.medium
        color: Qt.alpha(Appearance.color.panel, Appearance.color.panelAlpha)

        Column {
            id: column
            anchors.centerIn: parent
            spacing: Appearance.unit.small

            Text {
                anchors.right: parent.right
                text: hud.counter
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.clock
            }

            Text {
                anchors.right: parent.right
                text: hud.label.length > 0 ? hud.label : hud.idleLabel
                color: Appearance.color.accent
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
                font.capitalization: Font.AllUppercase
            }

            Text {
                anchors.right: parent.right
                text: hud.hint
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.chip
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }
}
