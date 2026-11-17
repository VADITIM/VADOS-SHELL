import QtQuick
import qs.config
import "../utils/Liquid.js" as Liquid
import "../utils/Playing.js" as Playing

QtObject {
    id: gulp

    property string label: "gulp"
    property bool isLanded: true
    property var character: Motion.liquid.gulp
    property real amplitude: 0
    property int span: 0
    property real time: 0
    readonly property real swell: time > 0 && time < span ? amplitude * Liquid.ring(character, time / 1000) : 0
    readonly property string playing: ring.running ? label : ""

    readonly property NumberAnimation ring: NumberAnimation {
        paused: Motion.isHeld && running
        target: gulp
        property: "time"
        from: 0
        to: gulp.span
        duration: Motion.pace(gulp.span)
    }

    onIsLandedChanged: {
        if (isLanded) {
            ring.restart()
            return
        }
        ring.stop()
        time = 0
    }
    Component.onCompleted: Playing.enlist(gulp)
    Component.onDestruction: {
        ring.stop()
        Playing.delist(gulp)
    }
}
