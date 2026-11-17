import QtQuick
import qs.config
import "../utils/Playing.js" as Playing

QtObject {
    id: flight

    property string label: "throw"
    property bool isThrown: false
    property int span: 0
    property int easing: Easing.InOutQuad
    property real overshoot: 0
    property real share: 0
    readonly property bool isLanded: isThrown && share >= 1
    readonly property string playing: travel.running ? label : ""

    readonly property NumberAnimation travel: NumberAnimation {
        paused: Motion.isHeld && running
        target: flight
        property: "share"
        from: 0
        to: 1
        duration: Motion.pace(flight.span)
        easing.type: flight.easing
        easing.overshoot: flight.overshoot
    }

    onIsThrownChanged: {
        travel.stop()
        share = 0
        if (isThrown)
            travel.start()
    }
    Component.onCompleted: Playing.enlist(flight)
    Component.onDestruction: {
        travel.stop()
        Playing.delist(flight)
    }
}
