import QtQuick
import QtTest
import qs.config
import "../../shell/utils/Sling.js" as Sling
import "../../shell/utils/Geometry.js" as Geometry

TestCase {
    name: "Sling"

    readonly property var parts: [Qt.rect(6, 20, 40, 220), Qt.rect(6, 430, 40, 60), Qt.rect(6, 760, 40, 40), Qt.rect(6, 810, 40, 40), Qt.rect(6, 860, 40, 30)]
    readonly property var frames: [Qt.rect(500, 80, 600, 120), Qt.rect(620, 300, 360, 360), Qt.rect(560, 700, 480, 60), Qt.rect(1200, 120, 300, 200)]
    readonly property var groups: ({ tasks: [Qt.rect(6, 20, 40, 220)], activity: [Qt.rect(6, 430, 40, 60)], system: [Qt.rect(6, 760, 40, 40), Qt.rect(6, 810, 40, 40), Qt.rect(6, 860, 40, 30)] })

    function setupOf(extra) {
        return Object.assign({
            width: 1600,
            height: 900,
            isMirrored: false,
            frames: frames,
            groups: groups,
            sources: parts,
            gather: Qt.point(176, 450),
            look: Appearance.lock,
            pace: Motion.lock,
            knock: Motion.liquid.knock,
            snap: Motion.liquid.snap
        }, extra ?? {})
    }

    function centerOf(form) {
        return Qt.point(form.x + form.width / 2, form.y + form.height / 2)
    }

    function test_formsLeanIntoTheirMotion() {
        const sideways = Sling.directedOf(400, 100, 0.2, 180)
        verify(sideways.width > 400 && sideways.height < 100, "a body flying sideways stretches along its flight")
        compare(Math.round(sideways.width * sideways.height), 40000, "and keeps its area")
        const falling = Sling.directedOf(400, 100, 0.2, 90)
        verify(falling.width < 400 && falling.height > 100, "a body flying down stretches tall")
        const knocked = Sling.knockedOf(0, 0, 80, { x: 0, y: 20 }, Appearance.lock)
        verify(knocked.width > knocked.height, "a merge stretches the core along the hit")
        compare(Math.abs(knocked.rotation), 90, "turned to the hit")
    }

    function test_theSlingPullsBackThenFliesAndStillHitsHard() {
        const pull = 0.2
        compare(Sling.slungAt(0, 60, 200, pull, 0.45), 0)
        fuzzyCompare(Sling.slungAt(60, 60, 200, pull, 0.45), -pull, 0.0001)
        verify(Sling.slungAt(30, 60, 200, pull, 0.45) < 0, "the wind-up pulls away from the target")
        fuzzyCompare(Sling.slungAt(260, 60, 200, pull, 0.45), 1, 0.0001)
        compare(Sling.slungAt(900, 60, 200, pull, 0.45), 1)
        let previous = -pull
        for (let time = 60; time <= 260; time += 5) {
            const share = Sling.slungAt(time, 60, 200, pull, 0.45)
            verify(share >= previous, "the flight never turns back")
            previous = share
        }
        const launch = Sling.slungAt(65, 60, 200, pull, 0.45) - Sling.slungAt(60, 60, 200, pull, 0.45)
        const impact = Sling.slungAt(260, 60, 200, pull, 0.45) - Sling.slungAt(255, 60, 200, pull, 0.45)
        verify(launch > impact, "fastest off the sling")
        verify(impact > 0.2 * launch, "and still fast where it hits")
    }

    function test_flownAtFindsWhereTheFlightCrossesEachShare() {
        for (const share of [0.1, 0.5, 0.7, 0.95]) {
            const flown = Sling.flownAt(share, 0.15, 0.45)
            fuzzyCompare(Sling.slungAt(60 + flown * 200, 60, 200, 0.15, 0.45), share, 0.0001)
        }
    }

    function test_knocksPushAlongTheThrowAndDieDown() {
        const hits = [{ at: 100, x: 30, y: 0, swell: 0.3 }]
        compare(Sling.knockAt(hits, 100, Motion.liquid.knock).x, 0)
        verify(Sling.knockAt(hits, 150, Motion.liquid.knock).x > 5, "pushed the way the droplet flew")
        verify(Sling.knockAt(hits, 150, Motion.liquid.knock).swell > 0, "and swells as it takes the droplet in")
        verify(Math.abs(Sling.knockAt(hits, 1600, Motion.liquid.knock).x) < 0.5, "then settles")
        const both = Sling.knockAt(hits.concat([{ at: 100, x: -30, y: 0, swell: 0 }]), 150, Motion.liquid.knock)
        fuzzyCompare(both.x, 0, 0.0001, "opposite knocks cancel: the push is physical, not scripted")
    }

    function test_mergesArriveOneByOneAndGrowTheCore() {
        const plan = Sling.enterOf(setupOf(), 7)
        const hits = plan.converge.hits
        compare(hits.length, parts.length)
        for (let index = 1; index < hits.length; index++)
            verify(hits[index].at - hits[index - 1].at >= Motion.lock.mergeGap - 0.001, "each merge has its own moment")
        compare(hits[0].x, 0, "the first droplet is the core, nothing to push")
        verify(hits.slice(1).every(hit => Math.hypot(hit.x, hit.y) > 0), "every later droplet pushes it")
        fuzzyCompare(plan.size, Appearance.lock.drop * Math.sqrt(parts.length), 0.001, "the core keeps the droplets' area")
    }

    function test_neighboursBendAwayFromEachOther() {
        const plan = Sling.enterOf(setupOf(), 13)
        const flights = plan.converge.flights.slice().sort((first, second) => first.arrival - second.arrival)
        for (let index = 1; index < flights.length; index++) {
            const sideOf = flight => Math.sign((flight.to.x - flight.from.x) * (flight.control.y - flight.from.y) - (flight.to.y - flight.from.y) * (flight.control.x - flight.from.x))
            verify(sideOf(flights[index]) !== sideOf(flights[index - 1]), "droplets that follow each other curve to opposite sides")
        }
    }

    function test_theEnterIsProceduralButRepeatable() {
        const first = Sling.enterOf(setupOf(), 11)
        const again = Sling.enterOf(setupOf(), 11)
        const other = Sling.enterOf(setupOf(), 12)
        compare(JSON.stringify(first.core.control), JSON.stringify(again.core.control))
        verify(JSON.stringify(first.core.control) !== JSON.stringify(other.core.control), "a new seed throws a new path")
    }

    function test_theEnterHitsTheFarWallAndLandsEveryModule() {
        for (const isMirrored of [false, true]) {
            const setup = setupOf({ isMirrored: isMirrored, gather: Qt.point(isMirrored ? 1424 : 176, 450) })
            const plan = Sling.enterOf(setup, 3)
            const impact = Sling.enterAt(plan, plan.hitAt + Motion.lock.wallHold / 2 - 1, setup)
            verify(impact.core.isShown)
            if (isMirrored)
                fuzzyCompare(impact.core.x, 0, 0.5, "the mirrored core presses against the left wall")
            else
                fuzzyCompare(impact.core.x + impact.core.width, 1600, 0.5, "the core presses against the right wall")
            verify(impact.core.width < impact.core.height, "flattened against the wall")
            const before = Sling.enterAt(plan, plan.splitAt - 1, setup)
            verify(before.bodies.every(body => !body.isShown), "no module before the split")
            const settled = Sling.enterAt(plan, plan.total, setup)
            for (let index = 0; index < frames.length; index++) {
                compare(settled.bodies[index].x, frames[index].x)
                compare(settled.bodies[index].y, frames[index].y)
                compare(settled.bodies[index].width, frames[index].width)
            }
            verify(!settled.core.isShown)
            const popping = Sling.enterAt(plan, plan.splitAt + Motion.lock.pop * 0.2, setup).core
            verify(popping.isShown && popping.height > impact.core.height, "the core swells as it pops")
            for (let time = plan.splitAt + Motion.lock.pop; time < plan.total; time += 10)
                verify(!Sling.enterAt(plan, time, setup).core.isShown, "nothing is left at the wall once it has popped, at " + time)
        }
    }

    function test_theModulesSnapBackFromPastTheirPlace() {
        const setup = setupOf()
        const plan = Sling.enterOf(setup, 5)
        const path = plan.splits[1]
        const target = Geometry.centerOf(frames[1])
        let farthest = 0
        let squashed = 0
        for (let time = path.arrival; time < path.arrival + Motion.lock.settle; time += 4) {
            const form = Sling.enterAt(plan, time, setup).bodies[1]
            farthest = Math.max(farthest, Math.hypot(centerOf(form).x - target.x, centerOf(form).y - target.y))
            squashed = Math.max(squashed, Math.abs(form.width / form.height - frames[1].width / frames[1].height))
        }
        verify(farthest > 2, "the module overshoots, " + farthest)
        verify(squashed > 0.02, "and squashes along its landing, " + squashed)
        const end = Sling.enterAt(plan, path.arrival + Motion.lock.settle - 1, setup).bodies[1]
        verify(Math.hypot(centerOf(end).x - target.x, centerOf(end).y - target.y) < 1, "and is home before the settle ends")
    }

    function test_theWallSpraysBubblesThatPop() {
        const setup = setupOf()
        const plan = Sling.enterOf(setup, 9)
        verify(plan.bubbles.length >= Appearance.lock.bubblesLeast && plan.bubbles.length <= Appearance.lock.bubblesMost)
        verify(plan.bubbles.every(bubble => Math.cos(bubble.angle) < 0.5), "away from the right wall")
        const bubble = plan.bubbles[0]
        const late = Sling.bubbleAt(bubble, bubble.at + bubble.flight * 0.95, Appearance.lock)
        verify(late.width > bubble.size, "it swells as it pops")
        verify(!Sling.bubbleAt(bubble, bubble.at + bubble.flight, Appearance.lock).isShown, "then it is gone")
    }

    function test_theEnterAlwaysEndsBeforeTheLockEngages() {
        const many = []
        for (let index = 0; index < 14; index++)
            many.push(Qt.rect(6, 20 + index * 60, 40, 50))
        const crowded = []
        for (let index = 0; index < 12; index++)
            crowded.push(Qt.rect(100 + (index % 4) * 360, 80 + Math.floor(index / 4) * 260, 300, 200))
        let longest = 0
        for (let seed = 1; seed < 120; seed++) {
            longest = Math.max(longest, Sling.enterOf(setupOf({ sources: many, frames: crowded }), seed).total)
            longest = Math.max(longest, Sling.enterOf(setupOf(), seed).total)
        }
        verify(longest < Motion.lock.engageWait - 200, "the enter ends after " + Math.round(longest) + " ms, before the engage backstop")
        verify(longest < Motion.lifecycle.stuck, "and inside the watchdog")
    }

    function test_theLeaveSplitsAtSeventyPercentIntoThreePills() {
        const setup = setupOf({ sources: frames })
        const plan = Sling.leaveOf(setup, 4)
        compare(plan.shots.map(shot => shot.kind), ["tasks", "activity", "system"])
        const at = Geometry.arcAt(plan.core.from, plan.core.control, plan.core.to, Appearance.lock.splitAt)
        fuzzyCompare(plan.splitPoint.x, at.x, 0.001)
        const share = Sling.slungAt(plan.splitAt - plan.core.launch, plan.core.windup, plan.core.flight, plan.core.pull, Motion.lock.carry)
        fuzzyCompare(share, Appearance.lock.splitAt, 0.001, "the split happens at 70% of the travel")
        const scene = Sling.leaveAt(plan, plan.splitAt + 1, setup)
        compare(scene.pills.length, 5, "one pill per taskbar part, the system pill splitting into its parts")
        for (const pill of scene.pills) {
            verify(pill.isShown)
            verify(Math.hypot(centerOf(pill).x - plan.splitPoint.x, centerOf(pill).y - plan.splitPoint.y) < 8, "every pill bursts out of the core")
        }
        verify(plan.bubbles.length >= Appearance.lock.bubblesLeast, "with bubbles popping from it")
        verify(plan.arrivals.every(part => part.arrival > 0 && part.arrival < 1))
        const mutated = Sling.leaveAt(plan, plan.shots[2].arrival + Motion.lock.wall, setup)
        const rect = groups.system[1]
        fuzzyCompare(centerOf(mutated.pills[3]).y, rect.y + rect.height / 2, 0.5, "the system pill has split into each system pill")
        const gone = Sling.leaveAt(plan, plan.total, setup)
        verify(gone.pills.every(form => !form.isShown) && !gone.core.isShown)
    }

    function test_theLeaveWindsUpAwayFromTheTaskbar() {
        const setup = setupOf({ sources: frames })
        const plan = Sling.leaveOf(setup, 6)
        const resting = Sling.leaveAt(plan, plan.core.launch, setup).core
        const pulled = Sling.leaveAt(plan, plan.core.launch + plan.core.windup, setup).core
        verify(centerOf(pulled).x > centerOf(resting).x, "pulled right before it is slung to the left taskbar")
    }

    function test_aCoveredTaskbarTakesTheSmashOffTheScreen() {
        for (const isMirrored of [false, true]) {
            const setup = setupOf({ sources: frames, isMirrored: isMirrored, isSmashing: true })
            const plan = Sling.leaveOf(setup, 5)
            compare(plan.shots.length, 0, "no pill is shot at a taskbar a window covers")
            compare(plan.arrivals.length, 0)
            const wall = isMirrored ? 1600 : 0
            const hit = Sling.leaveAt(plan, plan.hitAt + 1, setup).core
            verify(hit.isShown)
            fuzzyCompare(isMirrored ? hit.x + hit.width : hit.x, wall, 1, "the core smashes into the taskbar's edge")
            const flattened = Sling.leaveAt(plan, plan.hitAt + Motion.lock.smash * Appearance.lock.smashSquash, setup).core
            verify(flattened.width < flattened.height, "flattened against it")
            const leaving = Sling.leaveAt(plan, plan.hitAt + Motion.lock.smash * 0.9, setup).core
            verify(isMirrored ? leaving.x > 1600 - leaving.width / 2 : leaving.x + leaving.width < leaving.width / 2, "and slides out past the edge")
            verify(!Sling.leaveAt(plan, plan.hitAt + Motion.lock.smash, setup).core.isShown)
            verify(plan.bubbles.length >= Appearance.lock.bubblesLeast, "the smash sprays bubbles back into the screen")
            verify(plan.bubbles.every(bubble => Math.cos(bubble.angle) * (isMirrored ? -1 : 1) > -0.5))
            const gone = Sling.leaveAt(plan, plan.total, setup)
            verify(!gone.core.isShown && gone.pills.length === 0)
        }
    }

    function test_snapshotsContinueWhereTheBodiesAre() {
        const setup = setupOf()
        const enter = Sling.enterOf(setup, 2)
        const midway = Sling.enterAt(enter, enter.converge.done - 40, setup)
        const forms = Sling.formsOf(midway)
        verify(forms.length > 0)
        const leave = Sling.leaveOf(setupOf({ sources: forms }), 8)
        const first = Sling.leaveAt(leave, 0, setup)
        compare(first.drops.filter(form => form.isShown).length, forms.length, "nothing vanishes when the leave interrupts the enter")
        for (let index = 0; index < forms.length; index++) {
            fuzzyCompare(centerOf(first.drops[index]).x, forms[index].x + forms[index].width / 2, 0.5)
            fuzzyCompare(centerOf(first.drops[index]).y, forms[index].y + forms[index].height / 2, 0.5)
        }
    }

    function test_emptyScreensStillThrowSomething() {
        const setup = setupOf({ sources: [], frames: [], groups: {} })
        const enter = Sling.enterOf(setup, 1)
        verify(enter.total > 0)
        verify(Sling.enterAt(enter, enter.hitAt, setup).core.isShown)
        verify(!Sling.enterAt(enter, enter.total, setup).core.isShown)
        const leave = Sling.leaveOf(setup, 1)
        compare(leave.shots.length, 0)
        verify(!Sling.leaveAt(leave, leave.total, setup).core.isShown)
    }
}
