import QtQuick
import QtTest
import qs.config
import qs.components
import "../../shell/utils/SliceText.js" as Slice

Item {
    id: scene

    readonly property var pace: ({ sweep: 400, scatter: 100, settle: 500, leaveSweep: 60, leave: 80, push: 120 })
    readonly property var look: ({ spin: 90, jitter: 0.3, fade: 2.5, pushReach: 50, pushDepth: 10 })

    SliceText {
        id: slice
        look: scene.look
        pace: scene.pace
        character: Motion.liquid.snap
        text: "ab c\n d"
    }

    TestCase {
        name: "SliceText"
        when: windowShown

        function test_glyphsSkipSpacesAndKeepTheirCell() {
            const glyphs = Slice.glyphsOf("ab c\n d", 0.3)
            compare(glyphs.map(glyph => glyph.glyph).join(""), "abcd")
            compare(glyphs[2].column, 3)
            compare(glyphs[3].row, 1)
            compare(Slice.columnsOf("ab c\n d"), 4)
            compare(Slice.rowsOf("ab c\n d"), 2)
        }

        function test_theSliceRunsFromTheTopLeftCorner() {
            const glyphs = Slice.glyphsOf("ab\ncd", 0)
            compare(glyphs[0].diagonal, 0)
            compare(glyphs[3].diagonal, 1)
            verify(glyphs[1].diagonal > 0 && glyphs[1].diagonal < 1)
        }

        function test_everyCharacterIsPulledOnItsOwn() {
            const glyphs = Slice.glyphsOf("#########", 0.3)
            const speeds = new Set(glyphs.map(glyph => glyph.speed.toFixed(4)))
            verify(speeds.size > 1, "the characters do not share one speed")
            verify(glyphs.every(glyph => glyph.speed >= 0.7 && glyph.speed <= 1.3))
        }

        function test_theLeaveFitsItsBudget() {
            const glyphs = Slice.glyphsOf("ab c\n d", 0.3)
            const total = scene.pace.leaveSweep + scene.pace.leave
            verify(glyphs.every(glyph => Slice.pullOf(glyph, total, scene.pace) === 1))
            verify(glyphs.every(glyph => Slice.pullOf(glyph, 0, scene.pace) === 0))
        }

        function test_theLeaveAccelerates() {
            const glyph = Slice.glyphsOf("a", 0)[0]
            const early = Slice.pullOf(glyph, 20, scene.pace)
            const late = Slice.pullOf(glyph, 60, scene.pace) - Slice.pullOf(glyph, 40, scene.pace)
            verify(late > early, "the pull gains speed")
        }

        function test_charactersComeFromAnywhereInTheField() {
            const glyphs = Slice.glyphsOf("abcdefgh", 0.3)
            const reach = Qt.rect(-500, -300, 1000, 600)
            const points = glyphs.map(glyph => Slice.pointIn(reach, glyph, 0.42, 10, 20))
            verify(points.every(point => point.x >= -500 && point.x <= 490 && point.y >= -300 && point.y <= 280), "every start lies inside the field")
            verify(new Set(points.map(point => Math.round(point.x))).size > 4, "the starts are spread out")
            const again = glyphs.map(glyph => Slice.pointIn(reach, glyph, 0.87, 10, 20))
            verify(again.some((point, index) => Math.abs(point.x - points[index].x) > 1), "another round draws other starts")
        }

        function test_theSweepScramblesColumnsFromLeftToRight() {
            const glyphs = Slice.glyphsOf("ab", 0)
            const timing = { stagger: 0, spin: 200, settle: 0.65, turns: 1, cycles: 4 }
            const at = time => glyphs.map(glyph => Slice.sweepOf(glyph, time, 50, timing, "#*"))
            compare(at(0).map(swept => swept.glyph).join(""), "ab", "nothing spins before the sweep")
            const early = at(30)
            verify(early[0].glyph !== "a" && early[1].glyph === "b", "the left column spins first")
            const late = at(120)
            verify(late[1].glyph !== "b" && late[1].rotation > 0, "the next column follows")
            const total = Slice.sweepTotal("ab", 50, 200)
            compare(at(total).map(swept => swept.glyph).join(""), "ab", "every character settles back")
            verify(at(total).every(swept => swept.rotation === 0))
        }

        function test_theSweepStretchesAlongTheMiddleRow() {
            const glyphs = Slice.glyphsOf("a\na\na", 0)
            const timing = { stagger: 0, spin: 200, stretch: 1, settle: 0.65, turns: 1, cycles: 4 }
            const at = time => glyphs.map(glyph => Slice.sweepOf(glyph, time, 50, timing, "#*"))
            const early = at(50)
            verify(early[1].rotation > 0 && early[0].rotation === 0 && early[2].rotation === 0, "the middle row leads")
            const late = at(350)
            verify(late[1].rotation > 0 && late[0].rotation === 0 && late[2].rotation === 0, "the middle row trails")
            const total = Slice.sweepTotal("a\na\na", 50, 200, 1)
            verify(at(total).every(swept => swept.rotation === 0), "every row settles within the total")
        }

        function test_theEnterSettlesEveryCharacter() {
            const glyphs = Slice.glyphsOf("ab c\n d", 0.3)
            const total = Slice.enterTotal(scene.pace, 0.3)
            verify(glyphs.every(glyph => Slice.enterClock(glyph, total, scene.pace) * 1000 >= scene.pace.settle * 0.99))
        }

        function test_thePointerPushesNearCharactersAway() {
            const near = Slice.pushOf(110, 100, 100, 100, 50, 10)
            verify(near.x > 0 && Math.abs(near.y) < 0.001, "a character right of the pointer moves right")
            verify(near.x <= 10, "the push never exceeds its depth")
            const nearer = Slice.pushOf(105, 100, 100, 100, 50, 10)
            verify(nearer.x > near.x, "closer characters are pushed further")
            const above = Slice.pushOf(100, 80, 100, 100, 50, 10)
            verify(above.y < 0 && Math.abs(above.x) < 0.001, "a character above moves up")
            const far = Slice.pushOf(200, 100, 100, 100, 50, 10)
            compare(far.x, 0)
            compare(far.y, 0)
            const off = Slice.pushOf(110, 100, 100, 100, 0, 10)
            compare(off.x, 0)
        }

        function test_showingAndHidingLandsInPlaceThenGoes() {
            slice.isShown = true
            tryVerify(() => slice.isSettled, 3000)
            compare(slice.playing, "")
            slice.isShown = false
            tryVerify(() => slice.isGone, 1000)
            compare(slice.playing, "")
        }
    }
}
