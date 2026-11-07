import QtQuick
import QtTest
import "../../shell/utils/Geometry.js" as Geometry
import "../../shell/utils/Platform.js" as Platform

TestCase {
    name: "Geometry"

    function test_clampAndSmooth() {
        compare(Geometry.clampUnit(-2), 0)
        compare(Geometry.clampUnit(3), 1)
        compare(Geometry.smooth(0), 0)
        compare(Geometry.smooth(1), 1)
        compare(Geometry.smooth(0.5), 0.5)
        compare(Geometry.mix(10, 20, 0.25), 12.5)
    }

    function test_splinePassesThroughItsPoints() {
        const points = [Qt.point(0, 0), Qt.point(10, 5), Qt.point(20, 0)]
        const outline = Geometry.traceSpline(points, 4)
        compare(outline.length, 9)
        compare(outline[4].x, 10)
        compare(outline[4].y, 5)
        compare(outline[8].x, 20)
        compare(Geometry.traceSpline([], 4).length, 0)
    }

    function test_capabilityLevels() {
        compare(Platform.levelOf(Platform.capabilitiesOf("driftwm")), "native")
        compare(Platform.levelOf(Platform.capabilitiesOf("hyprland")), "extended")
        compare(Platform.levelOf(Platform.capabilitiesOf("generic")), "core")
        compare(Platform.levelOf(Platform.capabilitiesOf("unknown")), "core")
        verify(Platform.capabilitiesOf("generic").layerShell)
    }
}
