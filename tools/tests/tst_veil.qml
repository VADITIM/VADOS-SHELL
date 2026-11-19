import QtQuick
import QtTest
import qs.config
import qs.components
import "../../shell/utils/Veil.js" as Veil

Item {
    id: scene

    width: 800
    height: 600

    Cut {
        id: slice
        anchors.fill: parent
        lean: 0.3
        enterSpan: 240
        leaveSpan: 200

        Rectangle {
            objectName: "picture"
            anchors.fill: parent
            color: "white"
        }
    }

    TestCase {
        name: "Veil"
        when: windowShown

        function cleanup() {
            Config.setReducedMotion(false)
            slice.isInstant = true
            slice.isShown = false
            tryCompare(slice, "isCleared", true, 2000)
            slice.isInstant = false
            slice.isMirrored = false
        }

        function corners() {
            return [[1, 1], [scene.width - 1, 1], [1, scene.height - 1], [scene.width - 1, scene.height - 1], [scene.width / 2, scene.height / 2]]
        }

        function test_cutStartsOffTheScreenAndEndsPastIt() {
            for (const isMirrored of [false, true]) {
                const coversLeft = !isMirrored
                const before = Veil.cutOf(0, scene.width, scene.height, 0.3, isMirrored)
                const after = Veil.cutOf(1, scene.width, scene.height, 0.3, isMirrored)
                for (const corner of corners()) {
                    verify(!Veil.isCoveredAt(before, scene.height, coversLeft, corner[0], corner[1]), "nothing is covered before the slice")
                    verify(Veil.isCoveredAt(after, scene.height, coversLeft, corner[0], corner[1]), "everything is covered after it")
                }
            }
        }

        function test_theCutLeansWithTheTopAhead() {
            const cut = Veil.cutOf(0.5, scene.width, scene.height, 0.3, false)
            fuzzyCompare(cut.top - cut.bottom, scene.height * 0.3, 0.001)
            const mirrored = Veil.cutOf(0.5, scene.width, scene.height, 0.3, true)
            fuzzyCompare(mirrored.bottom - mirrored.top, scene.height * 0.3, 0.001)
            fuzzyCompare(mirrored.top, scene.width - cut.top, 0.001)
        }

        function test_theContentStaysPutWhileTheBladeTurns() {
            slice.isInstant = true
            slice.isShown = true
            for (const position of [0.15, 0.5, 0.85]) {
                slice.position = position
                for (const corner of corners()) {
                    const mapped = slice.content.mapToItem(scene, corner[0], corner[1])
                    fuzzyCompare(mapped.x, corner[0], 0.01)
                    fuzzyCompare(mapped.y, corner[1], 0.01)
                }
            }
        }

        function test_theBladeCoversExactlyOneSideOfTheCut() {
            slice.isInstant = true
            slice.isShown = true
            const blade = findChild(slice, "blade")
            for (const position of [0.2, 0.6]) {
                slice.position = position
                for (let x = 20; x < scene.width; x += 95) {
                    for (let y = 15; y < scene.height; y += 85) {
                        if (Math.abs(x - (slice.line.top + (slice.line.bottom - slice.line.top) * y / scene.height)) < 1)
                            continue
                        const local = blade.mapFromItem(scene, x, y)
                        const isInside = local.x >= 0 && local.x <= blade.width && local.y >= 0 && local.y <= blade.height
                        compare(isInside, Veil.isCoveredAt(slice.line, scene.height, slice.coversLeft, x, y), "point " + x + ", " + y + " at " + position)
                    }
                }
            }
        }

        function test_theLeaveCarriesOnInsteadOfReversing() {
            slice.isShown = true
            tryCompare(slice, "isCovered", true, 2000)
            verify(slice.coversLeft)
            slice.isShown = false
            verify(slice.isLeaveSide, "the leave cuts from the same side again")
            verify(!slice.coversLeft, "what stays covered is the far side of the cut")
            compare(slice.coverage, 1, "the leave starts from full cover, nothing jumps")
            tryCompare(slice, "isCleared", true, 2000)
        }

        function test_theMirroredSliceComesFromTheRight() {
            slice.isMirrored = true
            slice.isShown = true
            verify(!slice.coversLeft)
            tryCompare(slice, "isCovered", true, 2000)
            slice.isShown = false
            verify(slice.coversLeft)
            tryCompare(slice, "isCleared", true, 2000)
        }

        function test_interruptionsContinueFromWhereTheCutIs() {
            slice.isShown = true
            tryVerify(() => slice.position > 0.2, 2000)
            slice.isShown = false
            verify(!slice.isLeaveSide, "a half enter folds back instead of jumping to the other side")
            const folding = slice.coverage
            verify(folding > 0 && folding < 1)
            tryCompare(slice, "isCleared", true, 2000)
            slice.isShown = true
            tryCompare(slice, "isCovered", true, 2000)
            slice.isShown = false
            tryVerify(() => slice.position > 0.2, 2000)
            const remaining = slice.coverage
            slice.isShown = true
            verify(slice.isLeaveSide, "a half leave covers again from where it is")
            compare(slice.coverage, remaining)
            tryCompare(slice, "isCovered", true, 2000)
        }

        function test_rapidTogglingEndsSettled() {
            for (let round = 0; round < 11; round++) {
                slice.isShown = !slice.isShown
                wait(round * 9)
            }
            verify(slice.isShown)
            tryCompare(slice, "isCovered", true, 2000)
            slice.isShown = false
            tryCompare(slice, "isCleared", true, 2000)
        }

        function test_reducedMotionSlicesAtOnce() {
            Config.setReducedMotion(true)
            slice.isShown = true
            tryCompare(slice, "isCovered", true, 100)
            slice.isShown = false
            tryCompare(slice, "isCleared", true, 100)
        }

        function test_pressFlattensAgainstTheWallAndKeepsTheArea() {
            const free = Veil.pressOf(100, 80, 0.4)
            compare(free.along, 100)
            compare(free.across, 100)
            compare(free.distance, 80)
            const pressed = Veil.pressOf(100, 30, 0.4)
            compare(pressed.along, 80)
            fuzzyCompare(pressed.along * pressed.across, 100 * 100, 0.01)
            compare(pressed.distance, 40, "the pressed blob rests against the wall")
            const crushed = Veil.pressOf(100, -50, 0.4)
            compare(crushed.along, 60, "the press never flattens it past its limit")
        }

        function test_bendPushesTheFlightSideways() {
            const from = Qt.point(0, 0)
            const to = Qt.point(100, 0)
            const straight = Veil.bendOf(from, to, 0)
            compare(straight.x, 50)
            compare(straight.y, 0)
            const bent = Veil.bendOf(from, to, 0.3)
            compare(bent.x, 50)
            compare(bent.y, 30)
            compare(Veil.bendOf(from, to, -0.3).y, -30)
        }

        function test_groupsKeepTheirOrderAndMirror() {
            const groups = {
                system: [Qt.rect(6, 500, 40, 40), Qt.rect(6, 550, 40, 40)],
                tasks: [Qt.rect(6, 20, 40, 200)],
                activity: []
            }
            const found = Veil.groupsOf(groups, 800, false)
            compare(found.map(group => group.kind), ["tasks", "system"], "an empty group shoots no pill")
            compare(found[1].anchor.x, 26)
            compare(found[1].anchor.y, 545)
            const mirrored = Veil.groupsOf(groups, 800, true)
            compare(mirrored[0].rects[0].x, 754)
            compare(mirrored[0].anchor.x, 774)
            compare(Veil.groupsOf(null, 800, false).length, 0)
        }

        function test_departureAveragesTheDroplets() {
            compare(Veil.departureOf([], 100), 0)
            compare(Veil.departureOf([-20, 50, 300], 100), 0.5)
        }
    }
}
