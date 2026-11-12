import QtQuick
import QtTest
import qs.config
import qs.components
import "../../shell/utils/Variation.js" as Variation

Item {
    width: 1600
    height: 900

    SignalSpy {
        id: landings
        target: burst
        signalName: "landed"
    }

    Burst {
        id: burst
        rootX: 0
        seedX: 30
        seedY: 450
        formWidth: 600
        formHeight: 900
        leftCorner: 40
        rightCorner: 40
        screenHeight: 900
    }

    SignalSpy {
        id: releaseLandings
        target: releasing
        signalName: "landed"
    }

    Burst {
        id: releasing
        rootX: 0
        seedX: 30
        seedY: 450
        formWidth: 600
        formHeight: 900
        leftCorner: 40
        rightCorner: 40
        screenHeight: 900
        canHandOff: true
        parts: [Qt.rect(6, 20, 40, 220), Qt.rect(6, 700, 40, 40), Qt.rect(6, 760, 40, 40)]
    }

    Burst {
        id: splitting
        rootX: 0
        seedX: 30
        seedY: 450
        formWidth: 400
        formHeight: 900
        leftCorner: 40
        rightCorner: 40
        screenHeight: 900
        hasSteps: false
        splitAt: 0.65
        splitGap: 30
        wall: [Qt.point(0, 0), Qt.point(0, 0.5), Qt.point(-160, 0.65), Qt.point(0, 0.8), Qt.point(0, 1)]
    }

    TestCase {
        name: "Split"
        when: windowShown

        function cleanup() {
            splitting.isShown = false
            tryCompare(splitting, "isActive", false, 3000)
        }

        function test_theBodySplitsInTwoOnceItHasOpened() {
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            verify(splitting.isSplit)
            tryCompare(splitting.bodyPieces, "length", 2, 1000)
            fuzzyCompare(splitting.splitBottom - splitting.splitTop, 30, 0.5)
            fuzzyCompare(splitting.splitCenter, 900 * 0.65, 0.5)
            const upper = splitting.bodyPieces[0]
            const lower = splitting.bodyPieces[1]
            verify(Math.max(...upper.map(point => point.y)) <= splitting.splitTop + 0.5, "the upper body stops at the gap")
            verify(Math.min(...lower.map(point => point.y)) >= splitting.splitBottom - 0.5, "the lower body starts after it")
        }

        function test_itIsOneBodyWhileItOpens() {
            splitting.isShown = true
            tryVerify(() => splitting.isOpened, 3000)
            verify(splitting.splitShare < 1, "the split comes after the body has opened")
            tryCompare(splitting, "phase", "active", 3000)
        }

        function test_theGapClosesBeforeTheBodyCollapses() {
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            splitting.isShown = false
            splitting.stopAll()
            splitting.exit = Motion.burst.splitClose
            compare(splitting.splitShare, 0)
            verify(!splitting.isSplit)
            splitting.lifecycle.send("settle")
        }

        function gapAt(cut, x) {
            const index = cut.upper.reduce((best, point, at) => Math.abs(point.x - x) < Math.abs(cut.upper[best].x - x) ? at : best, 0)
            return cut.lower[index].y - cut.upper[index].y
        }

        function test_theWaveRunsAlongTheGap() {
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            splitting.stopAll()
            splitting.split = 1
            splitting.impact = 0.1
            let spread = 0.1
            while (spread < 1 && Math.abs(splitting.waveHead(1) - 0.3) > 0.03) {
                spread += 0.005
                splitting.spread = spread
            }
            splitting.trace()
            const cut = splitting.cutLines()
            const right = cut.upper[cut.upper.length - 1].x
            const head = splitting.cutHead(cut.upper[0].x, right, splitting.traceContext())
            verify(head > cut.upper[0].x && head < right, "the crest is on the gap")
            verify(gapAt(cut, head) < 30 * (1 - Appearance.burst.cutReach / 2), "the crest narrows the gap")
            verify(gapAt(cut, head) > 1, "without pinching it shut")
            const trough = head + Appearance.burst.crestLength / 2 + Appearance.burst.troughLength / 2
            if (trough < right)
                verify(gapAt(cut, trough) > 30 + 4, "the trough widens the gap ahead of the crest")
            splitting.spread = 1
            splitting.impact = 1
            splitting.trace()
            fuzzyCompare(gapAt(splitting.cutLines(), head), 30, 0.5)
            splitting.lifecycle.send("settle")
        }

        function test_theGapWaveSweepsTheWholeGapWithTheOuterWave() {
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            splitting.stopAll()
            splitting.split = 1
            splitting.impact = 0.1
            const context = splitting.traceContext()
            const margin = Appearance.burst.crestLength / 2 + Appearance.burst.troughLength
            let previous = -Infinity
            for (const spread of [0.3, 0.5, 0.7, 0.9, 1]) {
                splitting.spread = spread
                splitting.trace()
                const left = splitting.form.x - splitting.form.width / 2
                const right = Math.max(left + 1, splitting.wallXAt(splitting.splitCenter))
                const head = splitting.cutHead(left, right, context)
                verify(head > previous, "the crest keeps moving along the gap")
                previous = head
            }
            verify(previous > splitting.form.x, "the crest has swept past the gap's far end when the outer wave is done")
            splitting.lifecycle.send("settle")
        }

        function test_theGapOpensAsTheWaveStarts() {
            splitting.isShown = true
            while (splitting.split <= 0 && splitting.phase !== "active")
                wait(5)
            splitting.trace()
            const cut = splitting.cutLines()
            const left = cut.upper[0].x
            const right = cut.upper[cut.upper.length - 1].x
            verify(splitting.cutHead(left, right, splitting.traceContext()) < left + (right - left) / 2, "the wave has not crossed the gap before it opened")
            tryCompare(splitting, "phase", "active", 3000)
        }

        function test_closingGapMeetsInTheMiddleFirst() {
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            splitting.stopAll()
            splitting.split = 0.3
            const cut = splitting.cutLines()
            const middle = cut.upper[Math.floor(cut.upper.length / 2)]
            fuzzyCompare(gapAt(cut, middle.x), 0, 0.5)
            verify(gapAt(cut, cut.upper[0].x) > 4, "the ends are still apart")
            verify(gapAt(cut, cut.upper[cut.upper.length - 1].x) > 4)
            splitting.split = 1
            fuzzyCompare(gapAt(splitting.cutLines(), middle.x), 30, 0.5)
            splitting.lifecycle.send("settle")
        }

        function test_reopeningMidLeaveSplitsAgain() {
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            splitting.isShown = false
            wait(40)
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            fuzzyCompare(splitting.splitShare, 1, 0.001)
        }

        function test_noSplitWithoutAWall() {
            splitting.wall = []
            splitting.isShown = true
            tryCompare(splitting, "phase", "active", 3000)
            verify(!splitting.isSplit, "a body with no wall stays whole")
            splitting.wall = [Qt.point(0, 0), Qt.point(0, 0.5), Qt.point(-160, 0.65), Qt.point(0, 0.8), Qt.point(0, 1)]
        }
    }

    TestCase {
        name: "Release"
        when: windowShown

        function cleanup() {
            releasing.isShown = false
            tryCompare(releasing, "isActive", false, 3000)
            releasing.shouldStream = true
            releaseLandings.clear()
        }

        function test_withoutStreamsTheCircleGrowsAloneAndGivesNothingBack() {
            releasing.shouldStream = false
            releasing.isShown = true
            releasing.stopAll()
            releasing.merge = Motion.burst.handShare + (1 - Motion.burst.handShare - Motion.burst.settleShare) / 2
            compare(releasing.gulp, 0)
            fuzzyCompare(releasing.arrived, 0.5, 0.01)
            fuzzyCompare(releasing.form.x, releasing.seedX, 0.01)
            verify(releasing.form.width > 0 && releasing.form.width < Appearance.burst.ball, "the circle grows at the seed on its own")
            releasing.merge = 0
            releasing.isShown = false
            tryCompare(releasing, "isActive", false, 3000)
            verify(Motion.burst.grow < Motion.burst.converge, "the burst starts sooner than after a merge")
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            tryCompare(releasing, "isLeaving", true, 1000)
            verify(!releasing.isReleasing, "no part streams back to the taskbar")
            verify(!releasing.shouldHandOff)
            tryCompare(releaseLandings, "count", 1, 3000)
            verify(!releasing.isHandedOff && !releasing.isReleasing)
        }

        function test_partsStreamBackToTheTaskbarBeforeItReturns() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releaseLandings.clear()
            releasing.isShown = false
            verify(releasing.isReleasing, "a burst with parts gives them back")
            let isVisitorReleasedAtLanding = false
            let shapesAtLanding = []
            releaseLandings.target = null
            releasing.landed.connect(() => {
                isVisitorReleasedAtLanding = releasing.visitor !== null && releasing.visitor.hasReleased
                shapesAtLanding = releasing.flights.map(flight => releasing.releaseForm(flight))
            })
            tryVerify(() => {
                verify(!releasing.isHandedOff, "the taskbar never draws the leaving body while parts are released")
                return releasing.phase === "idle"
            }, 3000)
            verify(isVisitorReleasedAtLanding, "the taskbar sees the release finished when it returns")
            compare(shapesAtLanding.length, 3)
            for (let index = 0; index < 3; index++) {
                const part = releasing.parts[index]
                fuzzyCompare(shapesAtLanding[index].x, part.x + part.width / 2, 0.5)
                fuzzyCompare(shapesAtLanding[index].y, part.y + part.height / 2, 0.5)
                fuzzyCompare(shapesAtLanding[index].width, part.width, 0.5)
                fuzzyCompare(shapesAtLanding[index].height, part.height, 0.5)
            }
            releaseLandings.target = releasing
        }

        function test_aPartTravelsAsACircleThenExtends() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            releasing.stopAll()
            releasing.exit = Motion.burst.leaveShrink
            const pill = releasing.flights[0]
            releasing.release = 0.2
            let shape = releasing.releaseForm(pill)
            fuzzyCompare(shape.width, shape.height, 0.01)
            verify(Math.abs(shape.y - pill.y) > 10, "still on its way")
            releasing.release = 1
            shape = releasing.releaseForm(pill)
            fuzzyCompare(shape.height, pill.height, 0.01)
            fuzzyCompare(releasing.form.width, 0, 0.01)
            releasing.lifecycle.send("settle")
        }

        function test_everyPartShootsOutTogetherAndStopsAtItsPlace() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            releasing.stopAll()
            releasing.exit = Motion.burst.leaveShrink
            releasing.release = 0.02
            for (const flight of releasing.flights) {
                const shape = releasing.releaseForm(flight)
                verify(Math.hypot(shape.x - releasing.seedX, shape.y - releasing.seedY) > 0.1, "a part had not started with the others")
            }
            let furthest = 0
            const pill = releasing.flights[0]
            for (let step = 1; step <= 100; step++) {
                releasing.release = Motion.burst.releaseTravel * step / 100
                const shape = releasing.releaseForm(pill)
                furthest = Math.max(furthest, Math.abs(shape.y - releasing.seedY) / Math.abs(pill.y - releasing.seedY))
            }
            verify(furthest <= 1.0001, "a part went past its place, furthest " + furthest)
            releasing.lifecycle.send("settle")
        }

        function test_partsLeaveTheCentreGraduallyNotAtOnce() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            releasing.stopAll()
            releasing.exit = Motion.burst.leaveShrink
            const pill = releasing.flights[0]
            releasing.release = 1000 / 60 / Motion.burst.release
            const shape = releasing.releaseForm(pill)
            const share = Math.abs(shape.y - releasing.seedY) / Math.abs(pill.y - releasing.seedY)
            verify(share < 0.25, "a part jumped " + share + " of its way in one frame")
            releasing.lifecycle.send("settle")
        }

        function test_leavingBodyHasNoWave() {
            releasing.isShown = true
            releasing.impact = 0.1
            releasing.isShown = false
            verify(releasing.isLeaving)
            compare(releasing.crestHeight(), 0)
            releasing.lifecycle.send("settle")
        }

        function test_stepsAreGoneOnceTheBodyHasCollapsed() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.stopAll()
            releasing.isShown = false
            releasing.stopAll()
            releasing.exit = Motion.burst.stepRetract
            compare(releasing.topStep.rise, 0)
            compare(releasing.bottomStep.rise, 0)
            releasing.lifecycle.send("settle")
        }

        function test_handingOverKeepsTheCircleForTheNextOverlay() {
            releasing.isHandingOver = true
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            verify(releasing.isSwapped)
            verify(!releasing.isReleasing, "no part is given back to the taskbar")
            compare(releasing.visitor, null)
            releasing.stopAll()
            releasing.exit = Motion.burst.leaveShrink
            verify(releasing.isHandedOff)
            fuzzyCompare(releasing.form.width, releasing.look.ball, 0.5)
            fuzzyCompare(releasing.form.x, releasing.seedX, 0.5)
            releasing.lifecycle.send("settle")
            releasing.isHandingOver = false
        }

        function test_aBurstThatFollowsAnotherStartsFromItsCircle() {
            releasing.hasCircle = true
            releasing.isShown = true
            compare(releasing.merge, 1)
            tryCompare(releasing, "phase", "active", 3000)
            releasing.hasCircle = false
        }

        function test_longerPartsArriveLater() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            const longest = releasing.arrivalOf(releasing.flights[0])
            const circle = releasing.arrivalOf(releasing.flights[1])
            fuzzyCompare(circle, Motion.burst.releaseTravel, 0.001)
            fuzzyCompare(longest, 1, 0.001)
        }

        function test_theExtensionBouncesPastItsLengthAndIsDoneWhenTheEntriesArrive() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.stopAll()
            const pill = releasing.flights[0]
            const arrival = releasing.arrivalOf(pill)
            let longest = 0
            for (let step = 0; step <= 200; step++) {
                releasing.release = arrival * step / 200
                longest = Math.max(longest, releasing.releaseForm(pill).height)
            }
            verify(longest > pill.height * 1.02, "a small bounce past the end, longest " + longest)
            verify(longest < pill.height * 1.15, "only a small bounce, longest " + longest)
            releasing.release = arrival
            fuzzyCompare(releasing.releaseForm(pill).height, pill.height, 0.01)
            const slow = Motion.burst.releaseTravel - Motion.burst.releaseExtendLead
            releasing.release = slow + (arrival - slow) * 0.6
            const form = releasing.releaseForm(pill)
            verify(form.height > pill.height * 0.9, "the extension is further along than a linear one at 60% of its old span, " + form.height)
            releasing.lifecycle.send("settle")
        }

        function test_partsShrinkToCirclesBeforeTheyMove() {
            releasing.isShown = true
            releasing.stopAll()
            const pill = releasing.flights[0]
            const lag = Motion.burst.convergeLag * (pill.distance - releasing.nearest) / (releasing.farthest - releasing.nearest)
            const shrink = Motion.burst.shrinkShare
            const mergeAt = share => Motion.burst.handShare + (1 - Motion.burst.handShare - Motion.burst.settleShare) * share
            releasing.merge = 0
            let shape = releasing.streamForm(pill)
            fuzzyCompare(shape.height, pill.height, 0.01)
            releasing.merge = mergeAt(lag + (1 - Motion.burst.convergeLag) * shrink / 2)
            shape = releasing.streamForm(pill)
            verify(shape.height < pill.height && shape.height > pill.width, "shrinking")
            fuzzyCompare(shape.y, pill.y, 0.01)
            releasing.merge = mergeAt(lag + (1 - Motion.burst.convergeLag) * shrink)
            shape = releasing.streamForm(pill)
            fuzzyCompare(shape.width, shape.height, 0.5)
            fuzzyCompare(shape.y, pill.y, 0.01)
            releasing.merge = mergeAt(0.05)
            const nearest = releasing.flights.reduce((closest, flight) => flight.distance < closest.distance ? flight : closest)
            verify(Math.abs(releasing.streamForm(nearest).y - nearest.y) > 1, "the nearest part has started by frame one")
            fuzzyCompare(releasing.streamForm(pill).height, pill.height, 0.01)
            releasing.merge = 1
            shape = releasing.streamForm(pill)
            fuzzyCompare(shape.width, 0, 0.01)
            fuzzyCompare(shape.x, releasing.seedX, 0.01)
            releasing.merge = 0
        }

        function test_theTaskbarKeepsItsPartsUntilTheBurstCarriesThem() {
            releasing.isShown = true
            releasing.stopAll()
            releasing.merge = Motion.burst.handShare / 2
            verify(!releasing.isCarrying, "the taskbar still draws its parts while their elements leave")
            for (const flight of releasing.flights) {
                const shape = releasing.streamForm(flight)
                fuzzyCompare(shape.y, flight.y, 0.01)
                fuzzyCompare(shape.height, flight.height, 0.01)
            }
            compare(releasing.form.width, 0)
            releasing.merge = Motion.burst.handShare
            verify(releasing.isCarrying)
            releasing.merge = 0
        }

        function test_theMergedCircleBouncesWithEveryPartAndRestsBeforeItMoves() {
            releasing.isShown = true
            releasing.stopAll()
            let strongest = 0
            let bounces = 0
            let wasBouncing = false
            for (let step = 0; step <= 400; step++) {
                releasing.merge = step / 400
                const lean = Math.abs(releasing.form.width - releasing.form.height) / Math.max(1, releasing.look.ball)
                strongest = Math.max(strongest, lean)
                const isBouncing = lean > 0.02
                if (isBouncing && !wasBouncing)
                    bounces++
                wasBouncing = isBouncing
                if (releasing.merge < releasing.contactOf(releasing.flights.reduce((first, flight) => releasing.contactOf(flight) < releasing.contactOf(first) ? flight : first)))
                    fuzzyCompare(releasing.form.width, releasing.form.height, 0.01)
            }
            verify(strongest > 0.05, "the circle visibly reacts, strongest " + strongest)
            verify(bounces >= 2, "it reacts to more than one arrival, bounces " + bounces)
            releasing.merge = 1
            fuzzyCompare(releasing.form.width, releasing.look.ball, 0.01)
            fuzzyCompare(releasing.form.height, releasing.look.ball, 0.01)
            releasing.merge = 0
        }

        function test_theCircleRecoilsAsThePartsShootOut() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            releasing.stopAll()
            releasing.exit = Motion.burst.leaveShrink
            releasing.release = 0
            fuzzyCompare(releasing.form.width, releasing.form.height, 0.01)
            let strongest = 0
            for (let step = 1; step <= 100; step++) {
                releasing.release = Motion.burst.releaseTravel * step / 100
                strongest = Math.max(strongest, Math.abs(releasing.form.height - releasing.form.width))
            }
            verify(strongest > 2, "the circle stretches as its parts leave, strongest " + strongest)
            releasing.lifecycle.send("settle")
        }

        function test_reopeningMidReleaseEndsValid() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.isShown = false
            tryVerify(() => releasing.release > 0.3, 3000)
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 4000)
            verify(!releasing.isReleasing)
            compare(releasing.release, 0)
        }

        function test_coveredTaskbarGetsNothingBackAndTheCircleShrinksAway() {
            releasing.isShown = true
            tryCompare(releasing, "phase", "active", 3000)
            releasing.canHandOff = false
            releasing.isShown = false
            verify(!releasing.isReleasing, "no part streams back to a taskbar a window covers")
            let landedAt = -1
            releaseLandings.target = null
            releasing.landed.connect(() => landedAt = releasing.exit)
            tryVerify(() => {
                verify(!releasing.isHandedOff, "the taskbar never takes the circle while it stays covered")
                verify(releasing.visitor === null || !releasing.visitor.isHandedOff)
                return releasing.phase === "idle"
            }, 3000)
            verify(landedAt >= 0 && landedAt < 1, "the taskbar is given back while the circle still shrinks into the edge")
            releaseLandings.target = releasing
            releasing.canHandOff = true
        }

        function test_theHandOffIsDecidedWhenTheLeaveStarts() {
            burst.canHandOff = true
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            burst.isShown = false
            burst.canHandOff = false
            tryVerify(() => burst.isHandedOff, 3000, "a window covering the taskbar mid-leave does not take the circle back from it")
            tryCompare(burst, "phase", "idle", 3000)
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            burst.isShown = false
            burst.canHandOff = true
            tryVerify(() => {
                verify(!burst.isHandedOff, "uncovering mid-leave does not hand the circle over either")
                return burst.phase === "idle"
            }, 3000)
            burst.canHandOff = false
        }
    }

    TestCase {
        name: "Burst"
        when: windowShown

        function cleanup() {
            burst.isShown = false
            tryCompare(burst, "isActive", false, 3000)
            Config.setReducedMotion(false)
            Config.setBurstStyle("static")
            burst.lifecycle.watchdog.interval = Motion.lifecycle.stuck
            burst.seedY = 450
            burst.formHeight = 900
            burst.hasSteps = true
            landings.clear()
        }

        function test_reopenDuringLeaveRewinds() {
            burst.isShown = true
            tryCompare(burst, "isOpened", true, 3000)
            tryCompare(burst, "spread", 1, 3000)
            burst.isShown = false
            tryVerify(() => burst.exit > 0.05, 1000)
            verify(burst.canRewind)
            burst.isShown = true
            verify(burst.merge === 1, "does not converge from the taskbar again")
            tryCompare(burst, "isLeaving", false, 1000)
            verify(burst.spread > 0.99, "continues from the open form, not from an empty ball")
            verify(burst.isOpened)
        }

        function test_rapidTogglingEndsInAValidState() {
            for (let step = 0; step < 9; step++) {
                burst.isShown = !burst.isShown
                wait(step * 23)
            }
            verify(burst.isShown)
            tryCompare(burst, "phase", "active", 3000)
            verify(burst.isOpened)
            compare(burst.exit, 0)
            burst.isShown = false
            tryCompare(burst, "phase", "idle", 3000)
            verify(!burst.isActive, "no orphaned surface after the leave")
        }

        function test_stuckBurstSettles() {
            burst.lifecycle.watchdog.interval = 40
            burst.isShown = true
            ignoreWarning(new RegExp("vados: lifecycle: burst stuck in"))
            tryCompare(burst, "phase", "active", 1000)
            compare(burst.spread, 1)
            burst.lifecycle.watchdog.interval = Motion.lifecycle.stuck
        }

        function test_everyLeaveLandsOnce() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            landings.clear()
            burst.isShown = false
            tryCompare(burst, "phase", "idle", 3000)
            compare(landings.count, 1)
        }

        function test_stuckLeaveStillLands() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            landings.clear()
            burst.lifecycle.watchdog.interval = 20
            ignoreWarning(new RegExp("vados: lifecycle: burst stuck in exiting"))
            burst.isShown = false
            tryCompare(burst, "phase", "idle", 1000)
            compare(landings.count, 1, "a settled leave hands the taskbar back")
            wait(Motion.burst.leaveHold * 2)
            compare(landings.count, 1, "and only once")
        }

        function test_leaveFollowsScreenChanges() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            burst.isShown = false
            verify(burst.isLeaving)
            const before = burst.leaveFrom.height
            burst.seedY = 300
            burst.formHeight = 600
            fuzzyCompare(burst.leaveFrom.height, before * 600 / 900, 0.01)
            fuzzyCompare(burst.leaveFrom.y, 300, 0.01)
            tryCompare(burst, "phase", "idle", 3000)
        }

        function test_taskbarReturnsOnlyOnceTheBodyHasShrunk() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            landings.clear()
            burst.isShown = false
            let earliest = -1
            tryVerify(() => {
                if (earliest < 0 && landings.count > 0)
                    earliest = burst.exit
                if (landings.count === 0)
                    verify(burst.exit < Motion.burst.leaveShrink + 0.05, "still leaving at exit " + burst.exit + " with no taskbar")
                return burst.phase === "idle"
            }, 3000)
            compare(landings.count, 1)
            verify(earliest >= Motion.burst.leaveShrink - 0.01, "the taskbar came back at exit " + earliest + ", while the body was still out")
        }

        function test_waveSkipsTheScreenEdges() {
            burst.hasSteps = false
            burst.isShown = true
            let isCrestSeen = false
            let worst = 0
            tryVerify(() => {
                burst.trace()
                const top = burst.form.y - burst.form.height / 2
                worst = 0
                for (const point of burst.crests[0]) {
                    if (point.x < Appearance.burst.rootSpan * 1.5 || point.x > 480)
                        continue
                    isCrestSeen = true
                    worst = Math.max(worst, top - point.y)
                }
                return burst.spread >= 1 && burst.phase === "active"
            }, 3000)
            verify(isCrestSeen, "the crest ran along the top edge")
            verify(worst < 1, "the crest rose " + worst + " px off an edge on the screen edge")
        }

        function test_fullHeightBodyTouchesTheScreenEdgesOnceItsHeightIsReached() {
            burst.hasSteps = false
            burst.isShown = true
            let worst = 0
            let isReached = false
            tryVerify(() => {
                burst.trace()
                if (burst.heightShare >= 1) {
                    isReached = true
                    const top = burst.form.y - burst.form.height / 2
                    worst = Math.max(worst, top, burst.screenHeight - (burst.form.y + burst.form.height / 2))
                }
                return burst.spread >= 1 && burst.phase === "active"
            }, 3000)
            verify(isReached)
            verify(worst < 0.5, "an edge floated " + worst + " px off the screen edge")
        }

        function test_waveRunsWhereTheBodyIsFree() {
            burst.hasSteps = false
            burst.formHeight = 600
            burst.isShown = true
            let worst = 0
            tryVerify(() => {
                burst.trace()
                const top = burst.form.y - burst.form.height / 2
                for (const point of burst.crests[0]) {
                    if (point.x > Appearance.burst.rootSpan * 1.5 && point.x < 480)
                        worst = Math.max(worst, top - point.y)
                }
                return burst.spread >= 1
            }, 3000)
            verify(worst > Appearance.burst.crest / 2, "the crest rose only " + worst + " px off a free edge")
        }

        function test_aStaticBurstIsTheSameEveryTime() {
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            compare(JSON.stringify(burst.variation), JSON.stringify(Variation.identity()))
        }

        function test_aProceduralBurstRollsItsOwnWaveEachTime() {
            Config.setBurstStyle("procedural")
            verify(burst.isProcedural, "the setting reaches the burst")
            const rolls = []
            for (let attempt = 0; attempt < 3; attempt++) {
                burst.isShown = true
                tryCompare(burst, "phase", "active", 3000)
                rolls.push(JSON.stringify(burst.variation))
                verify(burst.variation.blobs.length >= Motion.burst.blobsLeast && burst.variation.blobs.length <= Motion.burst.blobsMost)
                burst.isShown = false
                tryCompare(burst, "isActive", false, 3000)
            }
            verify(rolls[0] !== rolls[1] || rolls[1] !== rolls[2], "every burst is its own")
        }

        function test_blobsShootOutOfTheOutlineAndFallBack() {
            Config.setBurstStyle("procedural")
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            burst.stopAll()
            const blobs = burst.variation.blobs
            burst.scatter = blobs[0].launch + blobs[0].flight / 2
            burst.trace()
            const spot = burst.blobSpots[0]
            verify(spot.size > 0.5, "the blob is out mid flight")
            const form = burst.form
            const outside = spot.x > form.x + form.width / 2 || spot.y < form.y - form.height / 2 || spot.y > form.y + form.height / 2
            verify(outside, "it flew off the outline: " + JSON.stringify(spot))
            burst.scatter = 1
            burst.trace()
            verify(burst.blobSpots.every(place => place.size === 0), "every blob is back once the scatter ends")
            burst.lifecycle.send("settle")
        }

        function test_blobsKeepOffTheScreenEdges() {
            Config.setBurstStyle("procedural")
            burst.isShown = true
            tryCompare(burst, "phase", "active", 3000)
            burst.stopAll()
            const context = burst.traceContext()
            for (let step = 0; step <= 40; step++) {
                burst.scatter = step / 40
                burst.trace()
                for (const spot of burst.blobSpots)
                    if (spot.size > 0.5)
                        verify(spot.y - spot.size / 2 > 0 && spot.y + spot.size / 2 < burst.screenHeight && spot.x - spot.size / 2 > 0, "a blob crossed a screen edge: " + JSON.stringify(spot))
            }
            burst.lifecycle.send("settle")
        }

        function test_reducedMotionOpensAtOnce() {
            Config.setReducedMotion(true)
            burst.isShown = true
            tryCompare(burst, "isOpened", true, 200)
            verify(!burst.isSplashing, "no splashes or crests under reduced motion")
            burst.isShown = false
            tryCompare(burst, "isActive", false, 200)
        }
    }
}
