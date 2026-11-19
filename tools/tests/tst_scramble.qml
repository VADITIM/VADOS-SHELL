import QtQuick
import QtTest
import qs.config
import qs.components
import "../../shell/utils/Scramble.js" as Scramble

Item {
    id: scene

    readonly property var timing: ({ stagger: 40, spin: 200, settle: 0.6, turns: 1, cycles: 4 })

    ScrambleText {
        id: typed
        target: "CONFIRM"
    }

    Flood {
        id: flood
        label: "test flood"
    }

    TestCase {
        name: "Scramble"
        when: windowShown

        function test_spanCoversEveryCharacter() {
            compare(Scramble.spanOf(0, 40, 200), 0)
            compare(Scramble.spanOf(7, 40, 200), 6 * 40 + 200)
        }

        function test_slotWaitsForItsTurn() {
            verify(!Scramble.phaseAt(2, 79, scene.timing).isVisible)
            verify(Scramble.phaseAt(2, 81, scene.timing).isVisible)
        }

        function test_symbolSpinsThenResolves() {
            const early = Scramble.phaseAt(0, 40, scene.timing)
            verify(!early.isResolved)
            verify(early.rotation > 0)
            const symbol = Scramble.characterAt("CONFIRM", "&$~|", 0, early)
            verify("&$~|".indexOf(symbol) >= 0)
            const late = Scramble.phaseAt(0, 150, scene.timing)
            verify(late.isResolved)
            compare(Scramble.characterAt("CONFIRM", "&$~|", 0, late), "C")
            const done = Scramble.phaseAt(0, 200, scene.timing)
            compare(done.rotation, 0)
        }

        function test_symbolMutatesWhileSpinning() {
            const first = Scramble.phaseAt(0, 10, scene.timing)
            const second = Scramble.phaseAt(0, 90, scene.timing)
            verify(Scramble.symbolAt("&$~|=+", 0, first.step) !== Scramble.symbolAt("&$~|=+", 0, second.step))
        }

        function test_spacesStayBlank() {
            compare(Scramble.characterAt("A B", "&$", 1, Scramble.phaseAt(1, 1000, scene.timing)), "")
        }

        function test_typesAndLeaves() {
            typed.isShown = true
            compare(typed.playing, "scramble")
            tryVerify(() => typed.isTyped, 3000)
            typed.isShown = false
            tryVerify(() => typed.presence === 0 && typed.playing === "", 2000)
        }

        function test_newTargetRetypes() {
            typed.isShown = true
            tryVerify(() => typed.isTyped, 3000)
            typed.target = "LOCK"
            verify(!typed.isTyped)
            compare(typed.playing, "scramble")
            tryVerify(() => typed.isTyped, 3000)
            typed.isShown = false
            tryVerify(() => typed.playing === "", 2000)
            typed.target = "CONFIRM"
        }

        function test_aLongerNameTypesToTheEnd() {
            typed.target = "LOCK"
            typed.isShown = true
            tryVerify(() => typed.isTyped, 3000)
            typed.target = "SHUT DOWN"
            tryVerify(() => typed.playing === "", 3000)
            verify(typed.isTyped)
            compare(typed.elapsed, typed.span)
            typed.isShown = false
            tryVerify(() => typed.playing === "", 2000)
            typed.target = "CONFIRM"
        }

        function test_onlyChangedCharactersRetype() {
            compare(Scramble.firstDifference("45%", "46%"), 1)
            compare(Scramble.firstDifference("45%", "45%"), 3)
            compare(Scramble.firstDifference("MUTE", "50%"), 0)
            const starts = Scramble.startsFor(Scramble.settle([0, 0, 0]), 3, 1, 0, scene.timing.stagger)
            verify(Scramble.phaseOf(starts[0], 0, scene.timing).isResolved)
            verify(!Scramble.phaseOf(starts[1], 0, scene.timing).isVisible)
            typed.target = "45%"
            typed.isShown = true
            tryVerify(() => typed.isTyped, 3000)
            typed.target = "46%"
            compare(typed.from, 1)
            verify(!typed.isTyped)
            tryVerify(() => typed.isTyped, 3000)
            typed.isShown = false
            tryVerify(() => typed.playing === "", 2000)
            typed.target = "CONFIRM"
        }

        function test_aKeyMidTypingSpinsOnlyTheNewCharacter() {
            const first = Scramble.startsFor([], 1, 0, 0, scene.timing.stagger)
            const second = Scramble.startsFor(first, 2, Scramble.firstDifference("\u2022", "\u2022\u2022"), 120, scene.timing.stagger)
            compare(second[0], first[0], "the character already spinning keeps its own start")
            compare(second[1], 120, "the new character starts now")
            compare(Scramble.endOf(second, scene.timing.spin), 120 + scene.timing.spin)
            typed.target = ""
            typed.isShown = true
            typed.target = "\u2022"
            wait(60)
            const startOfFirst = typed.starts[0]
            typed.target = "\u2022\u2022"
            compare(typed.starts[0], startOfFirst, "typing before the last character settled never replays it")
            compare(typed.from, 1)
            tryVerify(() => typed.isTyped, 3000)
            typed.isShown = false
            tryVerify(() => typed.playing === "", 2000)
            typed.target = "CONFIRM"
        }

        function test_floodCrossesAndFades() {
            flood.isShown = true
            tryVerify(() => flood.share === 1 && flood.presence === 1, 2000)
            flood.isShown = false
            tryVerify(() => flood.presence === 0, 2000)
            compare(flood.share, 1)
            flood.isShown = true
            tryVerify(() => flood.playing === "", 2000)
            compare(flood.presence, 1)
        }
    }
}
