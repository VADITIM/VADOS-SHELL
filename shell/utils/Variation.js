.pragma library
.import "Geometry.js" as Geometry

function identity() {
    return { crest: 1, crestTop: 1, crestBottom: 1, crestLength: 1, trough: 1, troughLength: 1, jet: 1, jetReach: 1, push: 1, splash: 1, blobs: [] }
}

function seeded(seed) {
    let state = Math.floor(seed) >>> 0
    return () => {
        state = (state + 0x6D2B79F5) >>> 0
        let mixed = Math.imul(state ^ (state >>> 15), state | 1)
        mixed ^= mixed + Math.imul(mixed ^ (mixed >>> 7), mixed | 61)
        return ((mixed ^ (mixed >>> 14)) >>> 0) / 4294967296
    }
}

function around(random, spread) {
    return 1 + spread * (2 * random() - 1)
}

function between(random, low, high) {
    return low + (high - low) * random()
}

function roll(random, range) {
    const count = Math.floor(between(random, range.blobsLeast, range.blobsMost + 1))
    const blobs = []
    for (let index = 0; index < count; index++) {
        blobs.push({
            along: between(random, range.band, 1 - range.band),
            launch: between(random, 0, range.launch),
            flight: range.flight * around(random, range.spread),
            reach: range.reach * around(random, range.spread),
            size: range.size * around(random, range.sizeSpread),
            lift: range.lift * (2 * random() - 1)
        })
    }
    return {
        crest: around(random, range.spread),
        crestTop: around(random, range.sideSpread),
        crestBottom: around(random, range.sideSpread),
        crestLength: around(random, range.spread),
        trough: around(random, range.spread),
        troughLength: around(random, range.spread),
        jet: around(random, range.spread),
        jetReach: around(random, range.spread),
        push: around(random, range.spread),
        splash: around(random, range.spread),
        blobs: blobs
    }
}

function blobAt(blob, impact) {
    const flown = (impact - blob.launch) / Math.max(0.001, blob.flight)
    if (flown <= 0 || flown >= 1)
        return { out: 0, rise: 0, size: 0 }
    const arc = Math.sin(Math.PI * flown)
    return {
        out: blob.reach * arc,
        rise: blob.lift * Geometry.smooth(flown),
        size: blob.size * Math.sqrt(arc) * (1 - flown * flown)
    }
}
