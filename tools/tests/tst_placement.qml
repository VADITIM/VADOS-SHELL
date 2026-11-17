import QtQuick
import QtTest
import "../../shell/utils/Placement.js" as Placement
import "../../shell/utils/Lock.js" as Lock

TestCase {
    name: "Placement"

    readonly property var catalogue: [
        { key: "wide", columns: 4, rows: 2 },
        { key: "small", columns: 2, rows: 2 },
        { key: "tall", columns: 2, rows: 4 }
    ]
    readonly property var grid: ({ columns: 8, rows: 4 })

    function test_gridCountsWholeCellsOnly() {
        compare(Placement.gridOf(1000, 450, 100), { columns: 10, rows: 4 })
        compare(Placement.gridOf(99, 99, 100), { columns: 0, rows: 0 })
        compare(Placement.gridOf(500, 500, 0), { columns: 0, rows: 0 })
    }

    function test_parseKeepsKnownKeysWithWholeCells() {
        compare(Placement.parse(["wide:1:0", "ghost:0:0", "small:x:1", "small:2:2"], catalogue), [
            { key: "wide", column: 1, row: 0, columns: 4, rows: 2 },
            { key: "small", column: 2, row: 2, columns: 2, rows: 2 }
        ])
        compare(Placement.parse(undefined, catalogue), [])
    }

    function test_fitsOnlyInsideAndClearOfOthers() {
        const entries = ["wide:0:0"]
        verify(Placement.fits(entries, catalogue, grid, "small", 4, 0))
        verify(!Placement.fits(entries, catalogue, grid, "small", 3, 0), "overlaps the wide one")
        verify(!Placement.fits(entries, catalogue, grid, "small", 7, 0), "runs past the right edge")
        verify(!Placement.fits(entries, catalogue, grid, "tall", 0, 1), "runs past the bottom")
        verify(Placement.fits(entries, catalogue, grid, "wide", 1, 0), "a key never collides with itself")
        verify(!Placement.fits(entries, catalogue, grid, "ghost", 4, 0))
    }

    function test_placeMovesOneKeyOrRefuses() {
        compare(Placement.place(["wide:0:0", "small:4:0"], catalogue, grid, "wide", 0, 2), ["small:4:0", "wide:0:2"])
        compare(Placement.place(["wide:0:0", "small:4:0"], catalogue, grid, "small", 2, 0), ["wide:0:0", "small:4:0"])
        compare(Placement.remove(["wide:0:0", "small:4:0"], catalogue, "wide"), ["small:4:0"])
        verify(Placement.isPlaced(["wide:0:0"], catalogue, "wide"))
        verify(!Placement.isPlaced(["wide:0:0"], catalogue, "small"))
    }

    function test_nearestFreeSpotIsTheClosestOneThatFits() {
        const placements = Placement.parse(["wide:0:0"], catalogue)
        compare(Placement.nearestFree(placements, grid, catalogue[1], 2, 0, ""), { column: 4, row: 0 })
        compare(Placement.nearestFree(placements, grid, catalogue[1], 1, 1, ""), { column: 1, row: 2 })
        compare(Placement.nearestFree(Placement.parse(["wide:0:0", "wide:4:0"], catalogue), { columns: 8, rows: 2 }, catalogue[1], 0, 0, ""), null)
    }

    function test_firstFreeSpotIsInReadingOrder() {
        compare(Placement.firstFree(Placement.parse(["wide:0:0"], catalogue), grid, catalogue[1]), { column: 4, row: 0 })
        compare(Placement.firstFree(Placement.parse(["wide:0:0", "wide:4:0"], catalogue), grid, catalogue[1]), { column: 0, row: 2 })
        compare(Placement.firstFree(Placement.parse(["wide:0:0", "wide:4:0"], catalogue), { columns: 8, rows: 2 }, catalogue[1]), null)
    }

    function test_settleKeepsWhatFitsAndMovesTheRestInside() {
        compare(Placement.settle(["wide:0:0", "small:4:0"], catalogue, grid), Placement.parse(["wide:0:0", "small:4:0"], catalogue))
        compare(Placement.settle(["wide:0:0", "small:9:5"], catalogue, grid), [
            { key: "wide", column: 0, row: 0, columns: 4, rows: 2 },
            { key: "small", column: 6, row: 2, columns: 2, rows: 2 }
        ])
        compare(Placement.settle(["wide:0:0", "small:2:0"], catalogue, grid)[1], { key: "small", column: 4, row: 0, columns: 2, rows: 2 }, "an overlapping placement moves off the one that was there")
        compare(Placement.settle(["wide:0:0", "wide:4:0"], catalogue, grid).length, 1, "a key is placed once")
        compare(Placement.settle(["wide:0:0", "tall:2:0"], catalogue, { columns: 4, rows: 2 }).length, 1, "a placement with no room left is left out")
    }

    function test_lockKeepsItsInterfaceOnThePlacementMaths() {
        compare(Lock.parse(["clock:5:1", "profile:6:4"]), [
            { key: "clock", column: 5, row: 1, columns: 6, rows: 3 },
            { key: "profile", column: 6, row: 4, columns: 4, rows: 4 }
        ])
        compare(Lock.format({ key: "clock", column: 1, row: 2 }), "clock:1:2")
        verify(Lock.isInside(Lock.moduleOf("clock"), 10, 13))
        verify(!Lock.isInside(Lock.moduleOf("clock"), 11, 13))
        verify(Lock.overlaps({ column: 0, row: 0, columns: 6, rows: 3 }, Lock.moduleOf("profile"), 5, 2))
        verify(Lock.fits(["clock:5:1"], "profile", 6, 4))
        verify(!Lock.fits(["clock:5:1"], "profile", 5, 2))
        compare(Lock.place(["clock:5:1", "profile:6:4"], "clock", 0, 0), ["profile:6:4", "clock:0:0"])
        compare(Lock.remove(["clock:5:1", "weather:0:0"], "clock"), ["clock:5:1", "weather:0:0"], "core modules stay")
        compare(Lock.remove(["clock:5:1", "weather:0:0"], "weather"), ["clock:5:1"])
        verify(Lock.isPlaced(["clock:5:1"], "clock"))
    }
}
