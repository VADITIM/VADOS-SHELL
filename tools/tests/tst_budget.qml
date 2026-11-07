import QtQuick
import QtTest
import VadosTest
import qs.config
import qs.modules.search

Item {
    width: 1600
    height: 900

    Search {
        id: search
        anchors.fill: parent
        parts: [0, 1, 2, 3, 4, 5, 6, 7].map(index => ({ x: 4, y: 80 + index * 90, width: 40, height: 40 }))
        canHandOff: true
    }

    TestCase {
        name: "Budget"
        when: windowShown

        readonly property int steps: 120
        readonly property int rounds: 3

        function burstIn(item) {
            if (item.lifecycle !== undefined && item.spread !== undefined)
                return item
            for (const child of item.children) {
                const found = burstIn(child)
                if (found)
                    return found
            }
            return null
        }

        function timeOf(work) {
            const start = Clock.now()
            work()
            return Clock.now() - start
        }

        function sweep(burst, step) {
            const samples = []
            for (let index = 0; index <= steps; index++) {
                const share = index / steps
                samples.push(timeOf(() => {
                    step(share)
                    burst.trace()
                }))
            }
            return samples
        }

        function percentile(samples, share) {
            const sorted = samples.slice().sort((first, second) => first - second)
            return sorted[Math.min(sorted.length - 1, Math.floor(share * sorted.length))]
        }

        function measure(burst) {
            search.isOpen = true
            tryCompare(burst, "phase", "active", 3000)
            burst.stopAll()
            const opening = sweep(burst, share => {
                burst.merge = 1
                burst.spread = share
                burst.impact = share
            })
            search.isOpen = false
            compare(burst.phase, "exiting")
            burst.stopAll()
            const leaving = sweep(burst, share => {
                burst.exit = share
            })
            burst.lifecycle.send("settle")
            compare(burst.phase, "idle")
            return opening.concat(leaving)
        }

        function test_searchBurstStaysInTheFrameBudget() {
            const burst = burstIn(search)
            verify(burst !== null)
            const typical = []
            let worst = 0
            for (let round = 0; round < rounds; round++) {
                const samples = measure(burst)
                typical.push(percentile(samples, Motion.budget.sampleShare))
                worst = Math.max(worst, ...samples)
            }
            const best = Math.min(...typical)
            console.info("vados: search burst script time per frame, " + Math.round(Motion.budget.sampleShare * 100) + "th percentile " + best.toFixed(2) + " ms, worst " + worst.toFixed(2) + " ms")
            verify(best < Motion.budget.frame, best.toFixed(2) + " ms per frame is over the " + Motion.budget.frame + " ms budget")
        }
    }
}
