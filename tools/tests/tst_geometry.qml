import QtQuick
import QtTest
import "../../shell/utils/Geometry.js" as Geometry

TestCase {
    name: "Geometry"

    function test_clampAndSmooth() {
        compare(Geometry.clampUnit(-2), 0)
        compare(Geometry.clampUnit(3), 1)
        compare(Geometry.smooth(0), 0)
        compare(Geometry.smooth(1), 1)
        compare(Geometry.smooth(0.5), 0.5)
        compare(Geometry.rebound(0, 1.6), 0)
        compare(Geometry.rebound(1, 1.6), 1)
        let peak = 0
        for (let step = 0; step <= 100; step++)
            peak = Math.max(peak, Geometry.rebound(step / 100, 1.6))
        verify(peak > 1.02 && peak < 1.15, "a small bounce past the end, peak " + peak)
        compare(Geometry.mix(10, 20, 0.25), 12.5)
    }

    function test_superellipseTouchesItsSides() {
        const outline = Geometry.superellipse(100, 60, 4, 96)
        compare(outline.length, 96)
        fuzzyCompare(outline[0].x, 100, 0.001)
        fuzzyCompare(outline[0].y, 30, 0.001)
        fuzzyCompare(outline[24].x, 50, 0.001)
        fuzzyCompare(outline[24].y, 60, 0.001)
        fuzzyCompare(outline[48].x, 0, 0.001)
    }

    function test_splinePassesThroughItsPoints() {
        const points = [Qt.point(0, 0), Qt.point(30, 40), Qt.point(60, 0)]
        const outline = Geometry.traceSpline(points, 10, 1)
        compare(outline.length, 11)
        compare(outline[5].x, 30)
        compare(outline[5].y, 40)
        compare(outline[10].x, 60)
        compare(Geometry.traceSpline([], 10, 1).length, 0)
    }

    function test_splineSamplesByDistance() {
        compare(Geometry.samplesFor(50, 10), 5)
        compare(Geometry.samplesFor(1, 10), 2)
    }

    function test_roundingCutsASharpCornerIntoAnArc() {
        const corner = [Qt.point(0, 0), Qt.point(100, 0), Qt.point(100, 100)]
        const rounded = Geometry.roundCorners(corner, 40, 8, 0.6)
        verify(rounded.length > 3)
        for (const point of rounded)
            verify(!(point.x === 100 && point.y === 0), "the sharp vertex is gone")
        compare(rounded[0].x, 0)
        compare(rounded[rounded.length - 1].y, 100)
        const middle = rounded[Math.floor(rounded.length / 2)]
        verify(middle.x < 100 && middle.y > 0, "the arc cuts inside the corner")
        compare(Geometry.roundCorners(corner, 0, 8, 0.6).length, 3)
        const smooth = [Qt.point(0, 0), Qt.point(10, 1), Qt.point(20, 3)]
        compare(Geometry.roundCorners(smooth, 40, 8, 0.6).length, 3)
    }

    function test_halfOutlinesMeetAtTheFarCorner() {
        const clockwise = Geometry.halfOutline(100, 50, 0, true, 8)
        const counter = Geometry.halfOutline(100, 50, 0, false, 8)
        fuzzyCompare(clockwise[0].x, counter[0].x, 0.001)
        fuzzyCompare(clockwise[clockwise.length - 1].x, 100, 0.001)
        fuzzyCompare(clockwise[clockwise.length - 1].y, 50, 0.001)
        fuzzyCompare(counter[counter.length - 1].x, 100, 0.001)
        fuzzyCompare(counter[counter.length - 1].y, 50, 0.001)
        const half = Geometry.cutAlong(clockwise, 100 / 150)
        fuzzyCompare(half[half.length - 1].x, 100, 0.001)
        fuzzyCompare(half[half.length - 1].y, 0, 0.001)
        compare(Geometry.cutAlong(clockwise, 0).length, 2)
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
}
