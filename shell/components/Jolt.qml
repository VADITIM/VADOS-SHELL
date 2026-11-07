import QtQuick
import qs.config

QtObject {
    id: jolt

    property real amplitude: 0
    property var steps: []
    property real clock: 0
    readonly property real total: steps.reduce((sum, step) => sum + step[1], 0)
    readonly property real value: valueAt(clock)

    readonly property NumberAnimation motion: NumberAnimation {
        target: jolt
        property: "clock"
        from: 0
        to: jolt.total
        duration: Motion.pace(jolt.total)
    }

    function valueAt(time) {
        let start = 0
        let from = 0
        for (const step of steps) {
            if (time <= start + step[1]) {
                const share = step[1] > 0 ? (time - start) / step[1] : 1
                return amplitude * (from + (step[0] - from) * share)
            }
            start += step[1]
            from = step[0]
        }
        return amplitude * from
    }

    function kick() {
        motion.restart()
    }

    function settle() {
        motion.stop()
        clock = 0
    }
}
