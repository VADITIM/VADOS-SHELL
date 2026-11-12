import QtQuick
import QtTest
import "../../shell/utils/Variation.js" as Variation

TestCase {
    name: "Variation"

    readonly property var range: ({ spread: 0.3, shrink: 0.45, sideSpread: 0.25, blobsLeast: 2, blobsMost: 6, launch: 0.4, flight: 0.45, reach: 52, size: 22, sizeSpread: 0.45, drift: 18 })

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
                verify(blob.side === -1 || blob.side === 1)
                verify(blob.along >= 0 && blob.along <= 1)
                verify(blob.launch >= 0 && blob.launch <= range.launch)
                verify(blob.launch + blob.flight < 1, "every blob is back before the scatter ends")
                verify(Math.abs(blob.drift) <= range.drift)
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

    function test_blobsLeaveFromAllAroundTheOutline() {
        const places = []
        for (let seed = 1; seed <= 60; seed++)
            for (const blob of Variation.roll(Variation.seeded(seed), range).blobs)
                places.push(blob)
        verify(places.some(blob => blob.side < 0) && places.some(blob => blob.side > 0), "both halves of the outline")
        verify(places.some(blob => blob.along < 0.2) && places.some(blob => blob.along > 0.8), "near the root and near the far end")
    }

    function test_aBlobShootsOutAndFallsBack() {
        const blob = { side: 1, along: 0.5, launch: 0.2, flight: 0.4, reach: 52, size: 22, drift: 10, shrink: 0.45 }
        compare(Variation.blobAt(blob, 0.1).size, 0)
        compare(Variation.blobAt(blob, 0.61).size, 0)
        compare(Variation.blobAt(blob, 0.9).size, 0)
        const middle = Variation.blobAt(blob, 0.4)
        fuzzyCompare(middle.out, 52, 0.001)
        verify(middle.size > 0)
        verify(Variation.blobAt(blob, 0.205).out < 5, "it buds out of the outline")
        verify(Variation.blobAt(blob, 0.595).out < 5, "it falls back into the outline")
        verify(Variation.blobAt(blob, 0.595).size > blob.size / 2, "it stays a drop, never a speck, until it is back")
    }
}
