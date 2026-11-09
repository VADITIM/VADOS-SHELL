import QtQuick
import QtTest
import qs.config
import qs.components

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

    TestCase {
        name: "Release"
        when: windowShown

        function cleanup() {
            releasing.isShown = false
            tryCompare(releasing, "isActive", false, 3000)
            releaseLandings.clear()
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
            releasing.merge = 0
            let shape = releasing.streamForm(pill)
            fuzzyCompare(shape.height, pill.height, 0.01)
            releasing.merge = lag + (1 - Motion.burst.convergeLag) * shrink / 2
            shape = releasing.streamForm(pill)
            verify(shape.height < pill.height && shape.height > pill.width, "shrinking")
            fuzzyCompare(shape.y, pill.y, 0.01)
            releasing.merge = lag + (1 - Motion.burst.convergeLag) * shrink
            shape = releasing.streamForm(pill)
            fuzzyCompare(shape.width, shape.height, 0.5)
            fuzzyCompare(shape.y, pill.y, 0.01)
            releasing.merge = 0.05
            const nearest = releasing.flights.reduce((closest, flight) => flight.distance < closest.distance ? flight : closest)
            verify(Math.abs(releasing.streamForm(nearest).y - nearest.y) > 1, "the nearest part has started by frame one")
            fuzzyCompare(releasing.streamForm(pill).height, pill.height, 0.01)
            releasing.merge = 1
            shape = releasing.streamForm(pill)
            fuzzyCompare(shape.width, 0, 0.01)
            fuzzyCompare(shape.x, releasing.seedX, 0.01)
            releasing.merge = 0
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
    }

    TestCase {
        name: "Burst"
        when: windowShown

        function cleanup() {
            burst.isShown = false
            tryCompare(burst, "isActive", false, 3000)
            Config.setReducedMotion(false)
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
