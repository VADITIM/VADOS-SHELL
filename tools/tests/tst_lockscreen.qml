import QtQuick
import QtTest
import qs.config
import qs.modules.lock

Item {
    id: scene

    width: 1600
    height: 900

    property int covers: 0
    property int landings: 0
    property var visitors: []

    LockScreen {
        id: lockScreen
        anchors.fill: parent
        visible: isPresent
        layout: []
        profileName: "Vadim"
    }

    Component {
        id: veilComponent

        LockVeil {
            anchors.fill: parent
            layout: []
            parts: [Qt.rect(6, 20, 40, 220), Qt.rect(6, 430, 40, 60), Qt.rect(6, 760, 40, 40), Qt.rect(6, 810, 40, 40)]
            groups: ({ tasks: [Qt.rect(6, 20, 40, 220)], activity: [Qt.rect(6, 430, 40, 60)], system: [Qt.rect(6, 760, 40, 40), Qt.rect(6, 810, 40, 40)] })
            onCovered: scene.covers += 1
            onLanded: scene.landings += 1
            onVisitorChanged: if (visitor) scene.visitors = scene.visitors.concat([visitor])
        }
    }

    TestCase {
        name: "LockScreen"
        when: windowShown

        function cleanup() {
            Config.setReducedMotion(false)
            lockScreen.isBlank = false
            lockScreen.isMain = true
            lockScreen.isLocked = false
            tryCompare(lockScreen, "phase", "idle", 3000)
            scene.covers = 0
            scene.landings = 0
            scene.visitors = []
        }

        function moduleItems() {
            const found = []
            const queue = [lockScreen]
            while (queue.length > 0) {
                const next = queue.shift()
                if (next.host !== undefined && next.isShown !== undefined && next !== lockScreen)
                    found.push(next)
                for (const child of next.children)
                    queue.push(child)
            }
            return found
        }

        function test_emptyLayoutStillOpensTheCoreModules() {
            lockScreen.isLocked = true
            tryCompare(lockScreen, "phase", "active", 3000)
            compare(lockScreen.placements.map(placement => placement.key).sort(), ["clock", "login", "profile"])
            const modules = moduleItems()
            compare(modules.length, 3, "every placement loads its catalogue file")
            verify(modules.every(module => module.host === lockScreen && module.isShown))
        }

        function test_rapidTogglingEndsInValidPhase() {
            for (let round = 0; round < 9; round++) {
                lockScreen.isLocked = !lockScreen.isLocked
                wait(round * 13)
            }
            verify(lockScreen.isLocked)
            tryCompare(lockScreen, "phase", "active", 3000)
            verify(lockScreen.isReady)
            lockScreen.isLocked = false
            lockScreen.isLocked = true
            lockScreen.isLocked = false
            tryCompare(lockScreen, "phase", "idle", 3000)
            verify(!lockScreen.isReady)
        }

        function test_reducedMotionShowsTheModulesAtOnce() {
            Config.setReducedMotion(true)
            lockScreen.isLocked = true
            tryCompare(lockScreen, "isReady", true, 200)
            tryCompare(lockScreen, "phase", "active", 200)
        }

        function test_otherScreensShowOnlyTheBackground() {
            lockScreen.isMain = false
            lockScreen.isLocked = true
            tryCompare(lockScreen, "phase", "active", 3000)
            compare(lockScreen.placements.length, 0)
            compare(moduleItems().length, 0)
            verify(lockScreen.isReady)
        }

        function test_blankCoversEverythingAndStopsTheLiquid() {
            lockScreen.isLocked = true
            tryCompare(lockScreen, "phase", "active", 3000)
            lockScreen.isBlank = true
            tryCompare(lockScreen, "isDark", true, 3000)
            const passes = findChild(lockScreen, "passes")
            verify(passes !== null)
            verify(!passes.parent.visible, "the liquid stops rendering behind a black screen")
            lockScreen.isBlank = false
            tryCompare(lockScreen, "isDark", false, 3000)
            verify(passes.parent.visible)
        }

        function test_theLockSurfaceStartsWithTheBodiesInPlace() {
            lockScreen.isLocked = true
            verify(lockScreen.isPresent)
            const passes = findChild(lockScreen, "passes")
            verify(passes !== null && passes.parent.visible, "the bodies draw from the first frame, as the veil left them")
            tryCompare(lockScreen, "isReady", true, 3000)
            tryCompare(lockScreen, "phase", "active", 3000)
        }

        function test_aHiddenVeilPlansNothing() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: false })
            compare(veil.enterPlan, veil.restingPlan)
            compare(veil.leavePlan, veil.restingPlan)
            veil.parts = [Qt.rect(6, 40, 40, 200), Qt.rect(6, 450, 40, 60)]
            compare(veil.enterPlan, veil.restingPlan)
            veil.isShown = true
            verify(veil.enterPlan !== veil.restingPlan)
            verify(veil.enterPlan.total > 0)
        }

        function test_theVeilCoversOnceThenHandsTheTaskbarBack() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true })
            verify(veil !== null)
            tryCompare(veil, "phase", "active", 5000)
            compare(scene.covers, 1, "the session lock is asked for once")
            compare(scene.landings, 0)
            veil.isShown = false
            tryVerify(() => veil.visitor !== null, 5000)
            verify(veil.visitor.isReleasing)
            verify(veil.visitor.release > 0)
            compare(veil.visitor.arrivals.length, 4, "every taskbar part waits for its pill")
            verify(veil.visitor.arrivals.every(part => part.arrival > 0 && part.arrival < 1))
            tryCompare(veil, "phase", "idle", 5000)
            compare(veil.visitor, null)
            wait(300)
            compare(veil.phase, "idle", "a landed veil never starts again by itself")
            compare(scene.landings, 1, "the leave lands exactly once")
            verify(scene.visitors.some(visitor => visitor.hasReleased), "the hand-off ends released")
        }

        function test_theVeilShowsTheModulesWhenCovered() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true })
            tryCompare(veil, "phase", "active", 5000)
            compare(veil.frames.length, 3)
            for (let index = 0; index < veil.frames.length; index++) {
                const form = veil.bodyOf(index)
                const frame = veil.frames[index]
                verify(form.isShown)
                compare(form.x, frame.x)
                compare(form.width, frame.width)
            }
        }

        function test_rapidVeilTogglingEndsInValidPhase() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true })
            for (let round = 0; round < 10; round++) {
                veil.isShown = !veil.isShown
                wait(round * 17)
            }
            verify(veil.isShown)
            tryCompare(veil, "phase", "active", 5000)
            veil.isShown = false
            tryCompare(veil, "phase", "idle", 5000)
            compare(scene.landings, 1)
        }

        function shownOf(forms) {
            return forms.filter(form => form.isShown).map(form => Math.round(form.x + form.width / 2) + "," + Math.round(form.y + form.height / 2))
        }

        function test_interruptionsThrowWhatIsOnScreen() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true })
            tryVerify(() => veil.stage.core.isShown && veil.stage.drops.some(form => form.isShown), 3000)
            const before = shownOf(veil.stage.drops.concat([veil.stage.core]))
            veil.isShown = false
            compare(veil.phase, "exiting")
            compare(veil.leaveSources.length, before.length, "the leave takes over every body the enter had out")
            compare(shownOf(veil.stage.drops).sort(), before.sort(), "and starts each one where it was")
            tryVerify(() => veil.stage.pills.some(form => form.isShown), 5000)
            const flying = shownOf(veil.stage.pills.concat([veil.stage.core]))
            veil.isShown = true
            compare(veil.enterSources.length, flying.length, "a lock during the leave gathers the pills still in flight")
            compare(shownOf(veil.stage.drops).sort(), flying.sort())
            tryCompare(veil, "phase", "active", 5000)
            for (let index = 0; index < veil.frames.length; index++)
                compare(veil.bodyOf(index).x, veil.frames[index].x)
            veil.isShown = false
            tryCompare(veil, "phase", "idle", 5000)
            compare(veil.enterSources.length, 0, "a landed veil forgets the bodies it threw")
        }

        function test_aCoveredTaskbarGetsNothingHandedBack() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true })
            tryCompare(veil, "phase", "active", 5000)
            veil.canHandOff = false
            veil.isShown = false
            verify(veil.isSmashing)
            verify(veil.leavePlan.isSmashing)
            tryCompare(veil, "phase", "idle", 5000)
            compare(scene.visitors.length, 0, "no pill is shot at a covered taskbar")
            compare(scene.landings, 1)
            veil.canHandOff = true
            veil.isShown = true
            tryCompare(veil, "phase", "active", 5000)
            veil.isShown = false
            verify(!veil.isSmashing, "the choice is made again on every leave")
        }

        function test_anInstantVeilIsCoveredAtOnce() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true, isInstant: true })
            tryCompare(veil, "phase", "active", 500)
            compare(scene.covers, 1)
        }

        function test_otherScreensVeilWithoutModules() {
            const veil = createTemporaryObject(veilComponent, scene, { isShown: true, isMain: false })
            compare(veil.frames.length, 0)
            tryCompare(veil, "phase", "active", 5000)
            veil.isShown = false
            tryCompare(veil, "phase", "idle", 5000)
            compare(scene.landings, 1)
        }
    }
}
