import QtQuick
import QtTest
import "../../shell/utils/Variation.js" as Variation

TestCase {
    name: "Variation"

    readonly property var range: ({ spread: 0.3, sideSpread: 0.25, blobsLeast: 2, blobsMost: 6, launch: 0.4, flight: 0.4, band: 0.18, reach: 72, size: 16, sizeSpread: 0.45, lift: 40 })

    function test_identityChangesNothing() {
        const still = Variation.identity()
        for (const key of ["crest", "crestTop", "crestBottom", "crestLength", "trough", "troughLength", "jet", "jetReach", "push", "splash"])
            compare(still[key], 1, key)
        compare(still.blobs.length, 0)
    }

    function test_theSameSeedRollsTheSameBurst() {
        compare(JSON.stringify(Variation.roll(Variation.seeded(7), range)), JSON.stringify(Variation.roll(Variation.seeded(7), range)))
        verify(JSON.stringify(Variation.roll(Variation.seeded(7), range)) !== JSON.stringify(Variation.roll(Variation.seeded(8), range)), "another seed rolls another burst")
    }

    function test_rollsStayInsideTheirRanges() {
        for (let seed = 1; seed <= 200; seed++) {
            const rolled = Variation.roll(Variation.seeded(seed), range)
            verify(rolled.blobs.length >= range.blobsLeast && rolled.blobs.length <= range.blobsMost, "blob count " + rolled.blobs.length)
            for (const key of ["crest", "crestLength", "trough", "troughLength", "jet", "jetReach", "push", "splash"])
                verify(rolled[key] >= 1 - range.spread && rolled[key] <= 1 + range.spread, key + " " + rolled[key])
            verify(Math.abs(rolled.crestTop - 1) <= range.sideSpread && Math.abs(rolled.crestBottom - 1) <= range.sideSpread)
            for (const blob of rolled.blobs) {
                verify(blob.along >= range.band && blob.along <= 1 - range.band, "blobs keep off the screen edges")
                verify(blob.launch >= 0 && blob.launch <= range.launch)
                verify(blob.launch + blob.flight < 1, "every blob is back before the impact ends")
                verify(Math.abs(blob.lift) <= range.lift)
            }
        }
    }

    function test_everyCountIsReached() {
        const counts = {}
        for (let seed = 1; seed <= 400; seed++)
            counts[Variation.roll(Variation.seeded(seed), range).blobs.length] = true
        for (let count = range.blobsLeast; count <= range.blobsMost; count++)
            verify(counts[count], "a burst with " + count + " blobs")
    }

    function test_aBlobShootsOutAndFallsBack() {
        const blob = { along: 0.5, launch: 0.2, flight: 0.4, reach: 72, size: 16, lift: 20 }
        compare(Variation.blobAt(blob, 0.1).size, 0)
        compare(Variation.blobAt(blob, 0.6).size, 0)
        compare(Variation.blobAt(blob, 0.9).size, 0)
        const middle = Variation.blobAt(blob, 0.4)
        fuzzyCompare(middle.out, 72, 0.001)
        verify(middle.size > 0)
        verify(Variation.blobAt(blob, 0.205).out < 5, "it buds out of the wall")
        verify(Variation.blobAt(blob, 0.595).out < 5, "it falls back into the wall")
        verify(Variation.blobAt(blob, 0.59).size < Variation.blobAt(blob, 0.4).size, "it shrinks as it falls back")
    }
}
