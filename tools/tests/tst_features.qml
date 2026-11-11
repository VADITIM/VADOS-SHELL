import QtQuick
import QtTest
import VadosTest
import qs.config
import qs.components
import qs.state
import "../../shell/utils/Features.js" as Features
import "../../shell/utils/Platform.js" as Platform

Item {
    id: scene

    width: 1600
    height: 900

    property real burstOpenedAt: 0
    property real pillOpenedAt: 0
    property real alertOpenedAt: 0
    property real clipboardOpenedAt: 0

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
        canHandOff: true
        parts: [Qt.rect(6, 20, 40, 220), Qt.rect(6, 700, 40, 40), Qt.rect(6, 760, 40, 40)]
        onIsOpenedChanged: if (isOpened) scene.burstOpenedAt = Clock.now()
    }

    Mutate {
        id: pill
        onIsInnerShownChanged: if (isInnerShown) scene.pillOpenedAt = Clock.now()
    }

    Reshape {
        id: alertBody
        targetWidth: Appearance.activity.bead
        targetHeight: Appearance.activity.bead
        growDuration: Motion.alerts.grow
        shrinkDuration: Motion.alerts.shrink
        shrinkDelay: Motion.alerts.shrinkDelay
        lag: Motion.alerts.lag
        overshoot: Motion.alerts.overshoot
        arriveShare: Motion.alerts.arriveShare
        onIsArrivedChanged: if (isArrived && isGrowing) scene.alertOpenedAt = Clock.now()
    }

    Reshape {
        id: clipboardBody
        targetWidth: Appearance.activity.bead
        targetHeight: Appearance.activity.bead
        growDuration: Motion.clipboard.grow
        shrinkDuration: Motion.clipboard.shrink
        shrinkDelay: Motion.clipboard.shrinkDelay
        shrinkLag: Motion.clipboard.shrinkLag
        shrinkEasing: Easing.InBack
        windUp: Motion.activity.windUp
        shrinkArriveShare: 1
        lag: Motion.clipboard.lag
        overshoot: Motion.clipboard.overshoot
        arriveShare: Motion.clipboard.arriveShare
        onIsArrivedChanged: if (isArrived && isGrowing) scene.clipboardOpenedAt = Clock.now()
    }

    TestCase {
        name: "Features"
        when: windowShown

        readonly property var fields: ["key", "folder", "root", "surface", "origin", "impact", "needs", "isBuilt"]
        readonly property var taskbarBorn: ["mutation", "overlay", "lock"]
        readonly property var lowerName: new RegExp("^[a-z]+$")
        readonly property var typeName: new RegExp("^[A-Z][A-Za-z]+$")
        readonly property int rounds: 3

        function test_everyRowAnswersEveryField() {
            for (const feature of Features.features) {
                const expected = feature.surface === "overlay" ? fields.concat(["layer", "keepsTaskbar"]) : fields
                compare(Object.keys(feature).sort(), expected.slice().sort(), feature.key)
                verify(Features.surfaces.indexOf(feature.surface) >= 0, feature.key + " surface " + feature.surface)
                verify(Features.origins.indexOf(feature.origin) >= 0, feature.key + " origin " + feature.origin)
                verify(Features.impacts.indexOf(feature.impact) >= 0, feature.key + " impact " + feature.impact)
                verify(lowerName.test(feature.key), feature.key)
                verify(lowerName.test(feature.folder), feature.key + " folder " + feature.folder)
                verify(typeName.test(feature.root), feature.key + " root " + feature.root)
                verify(Array.isArray(feature.needs), feature.key + " needs")
                compare(typeof feature.isBuilt, "boolean", feature.key)
                if (feature.surface === "overlay")
                    verify(Number.isInteger(feature.layer) && feature.layer >= 1, feature.key + " layer")
                if (feature.surface === "overlay")
                    compare(typeof feature.keepsTaskbar, "boolean", feature.key + " keepsTaskbar")
            }
        }

        function test_keysAndRootsAreUnique() {
            const keys = Features.features.map(feature => feature.key)
            const roots = Features.features.map(feature => feature.root)
            compare(new Set(keys).size, keys.length)
            compare(new Set(roots).size, roots.length)
        }

        function test_needsAreCapabilities() {
            const capabilities = Object.keys(Platform.capabilitiesOf("generic"))
            for (const feature of Features.features) {
                for (const need of feature.needs)
                    verify(capabilities.indexOf(need) >= 0, feature.key + " needs " + need + ", which utils/Platform.js does not answer")
            }
        }

        function test_everySurfaceNamesWhereItIsBorn() {
            for (const feature of Features.features) {
                if (taskbarBorn.indexOf(feature.surface) >= 0)
                    verify(feature.origin !== "none" && feature.origin !== "edge", feature.key + " grows out of a taskbar part")
                else if (feature.surface === "bar")
                    compare(feature.origin, "edge", feature.key)
                else
                    compare(feature.origin, "none", feature.key)
            }
        }

        function test_everyImpactHasItsReadyBudget() {
            for (const impact of Features.impacts) {
                if (impact !== "ambient")
                    verify(Motion.budget.ready[impact] > 0, impact)
            }
            verify(Motion.budget.ready.glance <= Motion.budget.ready.focus)
            verify(Motion.budget.ready.focus <= Motion.budget.ready.takeover)
        }

        function test_overlaysAreTheBuiltOverlayRows() {
            const built = Features.features.filter(feature => feature.isBuilt && feature.surface === "overlay")
            compare(Object.keys(Overlays.kinds).sort(), built.map(feature => feature.key).sort())
            for (const feature of built)
                compare(Overlays.kinds[feature.key].layer, feature.layer, feature.key)
            for (const feature of built)
                compare(Overlays.kinds[feature.key].keepsTaskbar, feature.keepsTaskbar, feature.key)
        }

        function test_plannedOverlaysCannotOpen() {
            const planned = Features.features.find(feature => !feature.isBuilt && feature.surface === "overlay")
            if (!planned)
                skip("every overlay in the registry is built")
            Overlays.open(planned.key, "A")
            verify(!Overlays.isOpen(planned.key, "A"))
            verify(!Overlays.isTaskbarAway("A"), "no surface without its window takes the taskbar")
        }

        function test_burstsAreReadyInsideTheFocusBudget() {
            let best = Infinity
            for (let round = 0; round < rounds; round++) {
                const start = Clock.now()
                burst.isShown = true
                tryCompare(burst, "isOpened", true, 3000)
                best = Math.min(best, scene.burstOpenedAt - start)
                tryCompare(burst, "phase", "active", 3000)
                burst.isShown = false
                tryCompare(burst, "isActive", false, 3000)
            }
            console.info("vados: burst ready after " + Math.round(best) + " ms")
            verify(best <= Motion.budget.ready.focus, Math.round(best) + " ms is over the " + Motion.budget.ready.focus + " ms focus budget")
        }

        function test_pillsAreReadyInsideTheGlanceBudget() {
            let best = Infinity
            for (let round = 0; round < rounds; round++) {
                const start = Clock.now()
                pill.isShown = true
                tryCompare(pill, "isInnerShown", true, 3000)
                best = Math.min(best, scene.pillOpenedAt - start)
                tryVerify(() => !pill.spreadEnter.running, 3000)
                pill.isShown = false
                tryVerify(() => !pill.leave.running && !pill.popLeave.running, 3000)
            }
            console.info("vados: pill ready after " + Math.round(best) + " ms")
            verify(best <= Motion.budget.ready.glance, Math.round(best) + " ms is over the " + Motion.budget.ready.glance + " ms glance budget")
        }

        function test_alertsAreReadyInsideTheGlanceBudget() {
            let best = Infinity
            for (let round = 0; round < rounds; round++) {
                const start = Clock.now()
                alertBody.targetWidth = Appearance.alerts.width
                alertBody.targetHeight = Appearance.alerts.height
                tryVerify(() => !alertBody.isArrived, 1000)
                tryVerify(() => alertBody.isArrived, 3000)
                best = Math.min(best, scene.alertOpenedAt - start)
                tryVerify(() => !alertBody.motion.running, 3000)
                alertBody.targetWidth = Appearance.activity.bead
                alertBody.targetHeight = Appearance.activity.bead
                tryVerify(() => !alertBody.isArrived, 1000)
                tryVerify(() => alertBody.isArrived && !alertBody.motion.running, 3000)
            }
            console.info("vados: alert ready after " + Math.round(best) + " ms")
            verify(best <= Motion.budget.ready.glance, Math.round(best) + " ms is over the " + Motion.budget.ready.glance + " ms glance budget")
        }

        function test_clipboardIsReadyInsideTheFocusBudget() {
            let best = Infinity
            for (let round = 0; round < rounds; round++) {
                const start = Clock.now()
                clipboardBody.targetWidth = Appearance.clipboard.width
                clipboardBody.targetHeight = Appearance.clipboard.height
                tryVerify(() => !clipboardBody.isArrived, 1000)
                tryVerify(() => clipboardBody.isArrived, 3000)
                best = Math.min(best, scene.clipboardOpenedAt - start)
                tryVerify(() => !clipboardBody.motion.running, 3000)
                clipboardBody.targetWidth = Appearance.activity.bead
                clipboardBody.targetHeight = Appearance.activity.bead
                tryVerify(() => !clipboardBody.isArrived, 1000)
                tryVerify(() => clipboardBody.isArrived && !clipboardBody.motion.running, 3000)
            }
            console.info("vados: clipboard ready after " + Math.round(best) + " ms")
            verify(best <= Motion.budget.ready.focus, Math.round(best) + " ms is over the " + Motion.budget.ready.focus + " ms focus budget")
        }
    }
}
