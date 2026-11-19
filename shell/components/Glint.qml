import QtQuick
import qs.config
import "../utils/Playing.js" as Playing

Item {
    id: glint

    required property var look
    required property int pace
    property string label: "glint"
    property bool isShown: false
    property real share: 0
    readonly property string playing: across.running ? label : ""
    readonly property real bandWidth: width * look.band

    clip: true

    onIsShownChanged: {
        across.stop()
        share = 0
        if (isShown)
            across.start()
    }
    Component.onCompleted: {
        Playing.enlist(glint)
        if (isShown)
            across.start()
    }
    Component.onDestruction: {
        across.stop()
        Playing.delist(glint)
    }

    NumberAnimation {
        id: across
        paused: Motion.isHeld && running
        target: glint
        property: "share"
        from: 0
        to: 1
        duration: Motion.pace(glint.pace)
        easing.type: Easing.InOutQuad
    }

    Rectangle {
        visible: across.running
        width: glint.bandWidth
        height: glint.height * glint.look.reach
        x: -width + glint.share * (glint.width + width)
        y: (glint.height - height) / 2
        rotation: glint.look.tilt
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(Appearance.color.text, glint.look.strength) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
