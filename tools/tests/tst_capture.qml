import QtQuick
import QtTest
import "../../shell/utils/Capture.js" as Shots
import "../../shell/utils/Ink.js" as Ink

TestCase {
    name: "Capture"

    readonly property var screen: ({ x: 0, y: 0, width: 1920, height: 1080 })

    function test_emptyFolderFallsBackToTheStandardOne() {
        compare(Shots.folderOf("", "/home/vadim", "/home/vadim/Pictures", Shots.stillFolder), "/home/vadim/Pictures/Screenshots")
        compare(Shots.folderOf("   ", "/home/vadim", "~/Videos", Shots.motionFolder), "/home/vadim/Videos/Recordings")
    }

    function test_chosenFolderWinsAndTildeIsHome() {
        compare(Shots.folderOf("~/Shots/", "/home/vadim", "/home/vadim/Pictures", Shots.stillFolder), "/home/vadim/Shots")
        compare(Shots.folderOf("/mnt/data/clips", "/home/vadim", "/home/vadim/Videos", Shots.motionFolder), "/mnt/data/clips")
        compare(Shots.folderOf("~", "/home/vadim", "/home/vadim/Pictures", Shots.stillFolder), "/home/vadim")
    }

    function test_namesCarryTheMoment() {
        const moment = new Date(2026, 10, 11, 9, 5, 7)
        compare(Shots.stillNameOf(moment), "Screenshot_2026-11-11_09-05-07.png")
        compare(Shots.motionNameOf(moment), "Recording_2026-11-11_09-05-07.mp4")
    }

    function test_theClockGrowsHoursOnlyWhenNeeded() {
        compare(Shots.clockOf(0), "0:00")
        compare(Shots.clockOf(75), "1:15")
        compare(Shots.clockOf(3725), "1:02:05")
        compare(Shots.clockOf(-4), "0:00")
    }

    function test_theRecorderThatCanPauseIsPreferred() {
        compare(Shots.pickRecorder(["wf-recorder", "gpu-screen-recorder"]).key, "gpu-screen-recorder")
        verify(Shots.pickRecorder(["gpu-screen-recorder"]).canPause)
        compare(Shots.pickRecorder(["wf-recorder", ""]).key, "wf-recorder")
        verify(!Shots.pickRecorder(["wf-recorder"]).canPause)
        compare(Shots.pickRecorder([""]), null)
    }

    function test_theRecorderGetsTheScreenAndTheFile() {
        const command = Shots.recordCommand(Shots.recorders[0], "DP-1", "/tmp/clip.mp4")
        compare(command[0], "gpu-screen-recorder")
        verify(command.indexOf("DP-1") > 0)
        compare(command[command.length - 1], "/tmp/clip.mp4")
        compare(Shots.recordCommand(Shots.recorders[1], "DP-1", "/tmp/clip.mp4"), ["wf-recorder", "-o", "DP-1", "-f", "/tmp/clip.mp4"])
    }

    function test_selectionIsTheSameWhicheverWayItIsDragged() {
        const forward = Ink.rectOf({ x: 10, y: 20 }, { x: 110, y: 70 })
        const backward = Ink.rectOf({ x: 110, y: 70 }, { x: 10, y: 20 })
        compare(forward, { x: 10, y: 20, width: 100, height: 50 })
        compare(backward, forward)
        verify(Ink.isUsable(forward, 6))
        verify(!Ink.isUsable(Ink.rectOf({ x: 4, y: 4 }, { x: 6, y: 90 }), 6), "a sliver is no selection")
        verify(!Ink.isUsable(null, 6))
    }

    function test_movedSelectionStaysOnTheScreen() {
        const box = { x: 100, y: 100, width: 200, height: 100 }
        compare(Ink.moved(box, 50, -20, screen), { x: 150, y: 80, width: 200, height: 100 })
        compare(Ink.moved(box, -500, -500, screen), { x: 0, y: 0, width: 200, height: 100 })
        compare(Ink.moved(box, 5000, 5000, screen), { x: 1720, y: 980, width: 200, height: 100 })
    }

    function test_paintKeepsEveryPointAndShapesKeepTheirEnds() {
        let paint = Ink.strokeOf("paint", "#ff0000", 4, { x: 0, y: 0 })
        paint = Ink.extended(Ink.extended(paint, { x: 5, y: 5 }), { x: 9, y: 2 })
        compare(paint.points.length, 4)
        let box = Ink.strokeOf("box", "#ff0000", 4, { x: 0, y: 0 })
        box = Ink.extended(Ink.extended(box, { x: 5, y: 5 }), { x: 40, y: 30 })
        compare(box.points, [{ x: 0, y: 0 }, { x: 40, y: 30 }])
    }

    function test_everyShapeDrawsClosedOrOpenAsItShould() {
        const from = { x: 10, y: 10 }
        const to = { x: 110, y: 60 }
        const box = Ink.linesOf({ kind: "box", width: 4, points: [from, to] })[0]
        compare(box.length, 5)
        compare(box[0], box[4], "a box closes on itself")
        const circle = Ink.linesOf({ kind: "circle", width: 4, points: [from, to] })[0]
        fuzzyCompare(circle[0].x, 110, 0.001)
        fuzzyCompare(circle[0].y, 35, 0.001)
        compare(Ink.linesOf({ kind: "arrow", width: 4, points: [from, to] }).length, 2, "an arrow has a shaft and a head")
        compare(Ink.linesOf({ kind: "line", width: 4, points: [from, to] }), [[from, to]])
    }

    function test_theEraserTakesOnlyWhatItTouches() {
        const line = { kind: "line", color: "#fff", width: 4, points: [{ x: 0, y: 0 }, { x: 100, y: 0 }] }
        const box = { kind: "box", color: "#fff", width: 4, points: [{ x: 200, y: 200 }, { x: 300, y: 300 }] }
        compare(Ink.erased([line, box], { x: 50, y: 8 }, 10), [box])
        compare(Ink.erased([line, box], { x: 250, y: 250 }, 10), [line, box], "the inside of a box is not its outline")
        compare(Ink.erased([line, box], { x: 300, y: 260 }, 10), [line])
    }

    function test_undoTakesTheLastStroke() {
        compare(Ink.undone([1, 2, 3]), [1, 2])
        compare(Ink.undone([]), [])
    }

    function test_toolsCycleAndEveryToolHasGlyph() {
        compare(Ink.tools.map(tool => tool.key), ["select", "color", "paint", "erase", "shape", "text"])
        for (const tool of Ink.tools)
            verify(tool.glyph.length > 0, tool.key)
        compare(Ink.nextOf(Ink.shapes, "arrow", 1), "box")
        compare(Ink.nextOf(Ink.shapes, "box", -1), "arrow")
        verify(Ink.isDrawing("paint") && Ink.isDrawing("shape") && !Ink.isDrawing("erase"))
    }

    function test_shapeCornersReshapeAroundTheOppositeCorner() {
        const box = Ink.strokeOf("box", "#ffffff", 4, { x: 10, y: 10 })
        const drawn = Ink.extended(box, { x: 50, y: 30 })
        const grab = Ink.grabOf([drawn], { x: 52, y: 31 }, 6)
        compare(grab.index, 0)
        compare(grab.corner, 2)
        const reshaped = Ink.reshaped(drawn, grab.corner, { x: 80, y: 70 })
        compare(Ink.rectOf(reshaped.points[0], reshaped.points[1]), { x: 10, y: 10, width: 70, height: 60 })
        const line = Ink.extended(Ink.strokeOf("arrow", "#ffffff", 4, { x: 0, y: 0 }), { x: 40, y: 0 })
        compare(Ink.reshaped(line, 0, { x: 5, y: 5 }).points, [{ x: 5, y: 5 }, { x: 40, y: 0 }])
        compare(Ink.grabOf([Ink.extended(Ink.strokeOf("paint", "#ffffff", 4, { x: 0, y: 0 }), { x: 9, y: 9 })], { x: 0, y: 0 }, 6), null, "paint has no corners")
    }

    function test_shapesMoveWholeAndHandlesCoverEveryShape() {
        const box = Ink.extended(Ink.strokeOf("box", "#ffffff", 4, { x: 0, y: 0 }), { x: 20, y: 20 })
        const line = Ink.extended(Ink.strokeOf("line", "#ffffff", 4, { x: 0, y: 50 }), { x: 30, y: 50 })
        compare(Ink.handlesOf([box, line]).length, 6)
        compare(Ink.shapeAt([box, line], { x: 15, y: 51 }, 4), 1)
        compare(Ink.shapeAt([box, line], { x: 10, y: 10 }, 4), -1, "a box is grabbed by its outline")
        compare(Ink.shifted(box, 5, -5).points[1], { x: 25, y: 15 })
        compare(Ink.replaced([box, line], 0, line)[0], line)
    }

    function test_selectionResizesAndRecentres() {
        const bounds = { x: 0, y: 0, width: 200, height: 100 }
        const area = { x: 20, y: 20, width: 40, height: 30 }
        compare(Ink.cornerAt(Ink.cornersOfRect(area), { x: 61, y: 49 }, 5), 2)
        compare(Ink.resized(area, 0, { x: -10, y: 5 }, bounds), { x: 0, y: 5, width: 60, height: 45 })
        compare(Ink.centeredAt(area, { x: 100, y: 50 }, bounds), { x: 80, y: 35, width: 40, height: 30 })
        compare(Ink.centeredAt(area, { x: 199, y: 99 }, bounds), { x: 160, y: 70, width: 40, height: 30 })
    }

    function test_pointsAreCopiedNotReferenced() {
        const source = Qt.point(3, 4)
        const copied = Ink.pointOf(source)
        compare(copied, { x: 3, y: 4 })
        verify(copied !== source)
    }

    function test_textIsHitInItsBoxMovesAndHasNoHandles() {
        const text = Ink.withText(Ink.textOf("#ffffff", 20, { x: 100, y: 100 }), "HELLO")
        const box = { kind: "box", color: "#ffffff", width: 4, points: [{ x: 300, y: 300 }, { x: 400, y: 400 }] }
        const strokes = [box, text]
        compare(Ink.textAt(strokes, { x: 130, y: 110 }, 4), 1)
        compare(Ink.textAt(strokes, { x: 350, y: 350 }, 4), -1)
        compare(Ink.shapeAt(strokes, { x: 130, y: 110 }, 4), 1)
        compare(Ink.shapeAt(strokes, { x: 300, y: 350 }, 4), 0)
        compare(Ink.shapeAt(strokes, { x: 350, y: 350 }, 4), -1)
        compare(Ink.handlesOf(strokes).length, 4)
        compare(Ink.shifted(text, 5, 5).text, "HELLO")
        compare(Ink.removed(strokes, 0), [text])
        compare(Ink.erased(strokes, { x: 110, y: 110 }, 4), [box])
    }
}
