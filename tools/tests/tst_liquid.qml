import QtQuick
import QtTest
import qs.config
import "../../shell/utils/Liquid.js" as Liquid

TestCase {
    name: "Liquid"

    function worst(measure) {
        let largest = 0
        for (let step = 0; step <= 200; step++)
            largest = Math.max(largest, Math.abs(measure(step / 200)))
        return largest
    }

    function test_burstMatchesTheOldBounce() {
        const openTime = Motion.burst.spread * (1 - Motion.burst.impactShare) / 1000
        verify(worst(share => 1 - Math.exp(-5 * share) * Math.cos(2.5 * Math.PI * share) - Liquid.rise(Motion.liquid.burst, share * openTime)) < 0.001)
    }

    function test_crashAndLaunchMatchTheOldWobbles() {
        verify(worst(share => Math.exp(-4.5 * share) * Math.sin(3.5 * Math.PI * share) - Liquid.ring(Motion.liquid.crash, share)) < 0.001)
        const spreadTime = Motion.settings.pop * (1 - Motion.settings.impactShare) / 1000
        verify(worst(share => 0.06 * Math.exp(-4.5 * share) * Math.sin(4 * Math.PI * share) - Liquid.ring(Motion.liquid.launch, share * spreadTime)) < 0.001)
    }

    function test_everyCharacterIsUnderdamped() {
        for (const name of ["burst", "crash", "launch", "pill", "circle", "follow", "dock", "droplet"]) {
            const character = Motion.liquid[name]
            verify(character.damping > 0 && character.damping < 1, name)
            verify(character.response > 0, name)
            verify(isFinite(Liquid.rise(character, 0.1)), name)
        }
    }

    function test_pullSettlesOnTarget() {
        let state = { value: 0, velocity: 0 }
        for (let frame = 0; frame < 180; frame++)
            state = Liquid.pull(state.value, state.velocity, 100, Motion.liquid.dock, 1 / 60, Motion.liquid)
        verify(Math.abs(state.value - 100) < 0.01)
    }

    function test_neckHasHysteresis() {
        const neck = Motion.liquid.neck
        verify(Liquid.isMerged(false, neck.merge + 0.01, neck))
        verify(Liquid.isMerged(true, neck.separate + 0.01, neck))
        verify(!Liquid.isMerged(true, neck.separate - 0.01, neck))
        verify(Liquid.neckKick(true, neck) < 0 && Liquid.neckKick(false, neck) > 0)
    }
}
