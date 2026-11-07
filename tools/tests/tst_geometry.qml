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

    function test_refitFollowsTheFrame() {
        const shape = { x: 110, y: 450, width: 400, height: 900, left: 40, right: 20, tag: "kept" }
        const fitted = Geometry.refit(shape, { x: 10, y: 450, width: 600, height: 900 }, { x: 10, y: 300, width: 300, height: 600 })
        compare(fitted.x, 60)
        compare(fitted.y, 300)
        compare(fitted.width, 200)
        compare(fitted.height, 600)
        compare(fitted.left, 20)
        compare(fitted.right, 10)
        compare(fitted.tag, "kept")
        const same = Geometry.refit(shape, { x: 0, y: 0, width: 0, height: 0 }, { x: 5, y: 5, width: 0, height: 0 })
        compare(same.width, 400)
        compare(same.x, 115)
    }

    function test_capabilityLevels() {
        compare(Platform.levelOf(Platform.capabilitiesOf("driftwm")), "native")
        compare(Platform.levelOf(Platform.capabilitiesOf("hyprland")), "extended")
        compare(Platform.levelOf(Platform.capabilitiesOf("generic")), "core")
        compare(Platform.levelOf(Platform.capabilitiesOf("unknown")), "core")
        verify(Platform.capabilitiesOf("generic").layerShell)
    }
}
