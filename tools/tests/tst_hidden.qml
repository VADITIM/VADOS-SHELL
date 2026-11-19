import QtQuick
import QtTest
import qs.config
import qs.modules.dashboard
import qs.modules.taskbar

Item {
    id: scene

    width: 800
    height: 600

    Throughput {
        id: graph
        width: 400
        height: 200
        isShown: false
    }

    RecordDot {
        id: dot
        visible: false
        isPulsing: true
    }

    TestCase {
        name: "Hidden"
        when: windowShown

        function test_aHiddenGraphDoesNotSlide() {
            graph.downloads = [1000, 2000]
            graph.samples = 5
            compare(graph.flow, 5)
            compare(graph.lag, 0)
        }

        function test_aShownGraphSlidesBetweenSamples() {
            graph.isShown = true
            tryVerify(() => graph.isPresent, 2000)
            graph.samples += 1
            verify(graph.lag > 0)
            tryCompare(graph, "lag", 0, 3000)
            graph.isShown = false
            tryVerify(() => !graph.isPresent, 2000)
        }

        function test_anInvisibleRecordDotDoesNotPulse() {
            wait(Motion.capture.pulse / 2)
            compare(dot.pulse, 1)
        }
    }
}
