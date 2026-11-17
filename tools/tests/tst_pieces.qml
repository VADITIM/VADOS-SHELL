import QtQuick
import QtTest
import qs.config
import qs.modules.settings

TestCase {
    id: suite
    name: "Pieces"
    when: windowShown
    width: 600
    height: 400

    property int extraCount: 0

    Page {
        id: page
        width: 600
        height: 400
        pageKey: "here"
        shownKey: "here"

        Piece {
            id: surface
            role: "surface"
            width: 200
            height: 100

            Piece {
                id: nested
                width: 40
                height: 40
            }
        }

        Section {
            id: section
            y: 120
            title: "TITLE"

            OptionGroup {
                id: group
                label: "LABEL"
                options: ["one", "two"]
                current: "one"
            }

            Repeater {
                model: suite.extraCount

                Piece {
                    width: 10
                    height: 10
                }
            }
        }

        Piece {
            id: optional
            y: 300
            width: 10
            height: 10
            isWanted: false
        }
    }

    function pieces() {
        const found = []
        page.gather(page, found)
        return found
    }

    function hasRotation(piece) {
        for (let index = 0; index < piece.transform.length; index++) {
            if (piece.transform[index].angle !== undefined)
                return true
        }
        return false
    }

    function init() {
        page.isContentShown = false
        extraCount = 0
        wait(Motion.settings.pageSwap + Motion.settings.stagger + 50)
    }

    function test_aPieceNeverPlaysTheFlipOfItsTurn() {
        compare(surface.shape, 1, "the turn underneath keeps its own flip and scale still")
        page.isContentShown = true
        tryVerify(() => nested.presence > 0 && nested.presence < 1, 2000)
        const scales = []
        for (let index = 0; index < nested.transform.length; index++) {
            const part = nested.transform[index]
            if (part.angle !== undefined)
                compare(part.angle, 0, "a rotation still turns the piece")
            if (part.xScale !== undefined)
                scales.push(part.xScale)
        }
        verify(scales.every(scale => scale >= Appearance.settings.piece.pop - 0.01), "a control only pops from " + Appearance.settings.piece.pop + ", it read " + scales)
    }

    function test_piecesInsideAPieceAreArrangedToo() {
        verify(pieces().includes(nested))
        page.isContentShown = true
        tryVerify(() => nested.presence >= 1, 3000)
    }

    function test_everyOptionIsItsOwnPiece() {
        const found = []
        page.gather(group, found)
        verify(found.length >= 4, "label, marker and two options, found " + found.length)
    }

    function test_enterDelaysStayInsideTheSpread() {
        extraCount = 40
        tryVerify(() => pieces().length > 40)
        wait(50)
        const longest = Math.max(...pieces().map(piece => piece.enterDelay))
        verify(longest <= Motion.settings.cardStagger + Motion.settings.cardLead + Motion.settings.spread, "the last piece waits " + longest + " ms")
        const delays = pieces().filter(piece => piece.role !== "card").map(piece => piece.enterDelay)
        verify(new Set(delays).size > delays.length / 2, "pieces enter one after another, not together")
    }

    function test_piecesCreatedLaterStillEnter() {
        page.isContentShown = true
        tryVerify(() => page.isSettled, 3000)
        extraCount = 2
        tryVerify(() => pieces().every(piece => piece === optional || piece.presence >= 1), 3000, "a piece made after the page still comes in")
        compare(pieces().filter(piece => piece !== optional && piece.enterDelay !== 0).length, 0, "and without the page's stagger once the page has settled")
    }

    function test_anUnwantedPieceStaysAwayUntilWanted() {
        page.isContentShown = true
        tryVerify(() => nested.presence >= 1, 3000)
        compare(optional.presence, 0)
        optional.isWanted = true
        tryVerify(() => optional.presence >= 1, 3000)
        optional.isWanted = false
        tryVerify(() => optional.presence <= 0, 3000)
    }

    function test_everyPieceLeavesWithinThePageSwap() {
        page.isContentShown = true
        tryVerify(() => pieces().every(piece => piece === optional || piece.presence >= 1), 3000)
        page.isContentShown = false
        tryVerify(() => pieces().every(piece => piece.presence <= 0), Motion.settings.pageSwap + 150)
    }
}
