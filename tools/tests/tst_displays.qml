import QtQuick
import QtTest
import qs.config
import qs.modules.settings
import "../../shell/utils/Displays.js" as Displays

TestCase {
    id: test

    name: "Displays"
    when: windowShown
    width: 1400
    height: 900

    property var requested: []
    property int kept: 0
    property int reverted: 0
    property var trial: Displays.idle()

    readonly property var heads: ({
            supported: true,
            heads: [
                {
                    name: "eDP-1",
                    description: "Panel (eDP-1)",
                    make: "AU",
                    model: "B39E",
                    enabled: true,
                    x: 0,
                    y: 0,
                    transform: 0,
                    scale: 1.25,
                    current: 0,
                    modes: [
                        { width: 1920, height: 1080, refresh: 143998, preferred: true },
                        { width: 1920, height: 1080, refresh: 144000, preferred: false },
                        { width: 1920, height: 1080, refresh: 60000, preferred: false },
                        { width: 1280, height: 720, refresh: 144000, preferred: false }
                    ]
                },
                {
                    name: "DP-2",
                    description: "",
                    make: "",
                    model: "",
                    enabled: true,
                    x: 1536,
                    y: 0,
                    transform: 1,
                    scale: 1,
                    current: 1,
                    modes: [
                        { width: 2560, height: 1440, refresh: 59951, preferred: true },
                        { width: 1920, height: 1080, refresh: 60000, preferred: false }
                    ]
                },
                {
                    name: "HDMI-A-1",
                    enabled: false,
                    modes: []
                }
            ]
        })
    readonly property var pair: Displays.fromHeads(heads)
    readonly property int reach: Appearance.settings.displays.snap
    readonly property string newline: "\n"

    Page {
        id: page
        width: test.width
        height: test.height
        pageKey: "displays"
        shownKey: ""
        isContentShown: true

        DisplayEditor {
            id: editor
            areaWidth: page.width
            areaHeight: page.height
            outputs: [test.output("eDP-1", 0, 0, 1920, 1080), test.output("DP-2", 1920, 0, 1920, 1080)]
            trial: test.trial
            trialLeft: 12000
            onApplyRequested: layout => test.requested = test.requested.concat([layout])
            onKeepRequested: test.kept++
            onRevertRequested: test.reverted++
        }
    }

    function pieces() {
        const found = []
        page.gather(page, found)
        return found
    }

    function prepare() {
        failOnWarning(/.*/)
        requested = []
        kept = 0
        reverted = 0
        trial = Displays.idle()
        editor.reset()
    }

    function test_editorPiecesEnterAndLeaveWithinThePageSwap() {
        prepare()
        const found = pieces()
        verify(found.length >= 10, "every element of the tab is a piece, found " + found.length)
        page.shownKey = "displays"
        tryVerify(() => found.every(piece => !piece.isWanted || piece.presence >= 1), 3000, "every wanted piece enters")
        const start = Date.now()
        page.shownKey = ""
        tryVerify(() => found.every(piece => piece.presence <= 0), Motion.settings.pageSwap + 200, "every piece leaves")
        verify(Date.now() - start <= Motion.settings.pageSwap + 100, "the leave fits the page swap, took " + (Date.now() - start) + " ms")
    }

    function test_draggedMonitorDocksAndApplies() {
        prepare()
        verify(!editor.isEdited)
        verify(!editor.canApply)
        const rect = editor.rectOnCanvas(editor.draft[1])
        verify(rect.width > 0 && rect.height > 0, "the monitor has a body on the canvas")
        compare(editor.nameAt(rect.x + 2, rect.y + 2), "DP-2")
        editor.pickUp("DP-2", 0, 0)
        compare(editor.picked, "DP-2")
        editor.follow(-rect.x - rect.width / 2, rect.height)
        editor.drop(0, 0)
        compare(editor.carried, "")
        const moved = editor.draft.find(output => output.name === "DP-2")
        compare(moved.y, 1080, "dropped below, it docks under the panel")
        compare(editor.problem, "")
        verify(editor.isEdited)
        verify(editor.canApply)
        editor.confirm()
        compare(requested.length, 1, "enter applies")
        compare(requested[0].find(output => output.name === "DP-2").y, 1080)
        verify(!editor.isEdited, "an applied layout is the new base")
    }

    function test_changesSettleAndBadLayoutsCannotApply() {
        prepare()
        editor.picked = "eDP-1"
        editor.change({ scale: 0.5 })
        compare(editor.problem, "", "a monitor that grows moves out of its neighbour")
        editor.reset()
        editor.draft = Displays.withOutput(editor.draft, "DP-2", { x: 2500 })
        compare(editor.problem, "gap")
        verify(!editor.canApply)
        editor.apply()
        compare(requested.length, 0, "a layout with a gap is never sent")
        editor.reset()
        editor.picked = "DP-2"
        editor.change({ transform: "90" })
        compare(Displays.sizeOf(editor.pickedOutput), { width: 1080, height: 1920 })
        compare(editor.problem, "")
    }

    function test_trialOffersKeepAndRevert() {
        prepare()
        trial = Displays.begun(Displays.idle(), editor.outputs, editor.outputs, Date.now(), Motion.displays.keep, "", "")
        verify(editor.isTrying)
        editor.confirm()
        compare(kept, 1, "enter keeps a layout on trial")
        editor.revertRequested()
        compare(reverted, 1)
    }

    function output(name, x, y, width, height) {
        return { name: name, x: x, y: y, scale: 1, transform: "normal", mode: { width: width, height: height, refresh: 60000 }, modes: [{ width: width, height: height, refresh: 60000, isPreferred: true }] }
    }

    function test_headsBecomeOutputs() {
        compare(pair.length, 3, "a disabled head is listed so it can be turned back on")
        verify(pair[0].isEnabled && pair[1].isEnabled)
        verify(!pair[2].isEnabled)
        const panel = pair[0]
        compare(panel.name, "eDP-1")
        compare(panel.scale, 1.25)
        compare(panel.transform, "normal")
        compare(panel.mode, { width: 1920, height: 1080, refresh: 144000 })
        compare(panel.modes.length, 3, "modes that round to the same hertz are one")
        verify(panel.modes[0].isPreferred)
        compare(pair[1].transform, "90")
        compare(pair[1].mode, { width: 1920, height: 1080, refresh: 60000 })
        compare(Displays.fromHeads(null), [])
        compare(Displays.fromHeads({ supported: false, heads: [] }), [])
    }

    function test_hyprlandMonitorsBecomeOutputs() {
        const outputs = Displays.fromHyprland([
            { name: "DP-1", description: "Dell", make: "Dell", model: "U27", x: 0, y: 0, width: 2560, height: 1440, refreshRate: 143.98, scale: 1.5, transform: 3, disabled: false, availableModes: ["2560x1440@143.98Hz", "2560x1440@59.95Hz", "broken"] },
            { name: "HDMI-A-1", disabled: true }
        ])
        compare(outputs.length, 2)
        verify(outputs[0].isEnabled)
        verify(!outputs[1].isEnabled, "a disabled monitor is listed off")
        compare(outputs[0].transform, "270")
        compare(outputs[0].mode, { width: 2560, height: 1440, refresh: 144000 })
        compare(outputs[0].modes.map(mode => mode.refresh), [144000, 60000])
        compare(Displays.fromHyprland("nonsense"), [])
    }

    function test_logicalSizeFollowsScaleAndRotation() {
        compare(Displays.sizeOf(pair[0]), { width: 1536, height: 864 })
        compare(Displays.sizeOf(pair[1]), { width: 1080, height: 1920 }, "a turned monitor swaps its sides")
    }

    function test_validationCatchesOverlapsGapsAndBadValues() {
        compare(Displays.problemOf(pair), "")
        compare(Displays.problemOf([]), "empty")
        compare(Displays.problemOf([output("A", 0, 0, 1920, 1080), output("B", 1900, 0, 1920, 1080)]), "overlap")
        compare(Displays.problemOf([output("A", 0, 0, 1920, 1080), output("B", 2000, 0, 1920, 1080)]), "gap")
        compare(Displays.problemOf([output("A", 0, 0, 1920, 1080), output("B", 1920, 1080, 1920, 1080)]), "gap", "touching at a corner only is a gap")
        compare(Displays.problemOf([output("A", 0, 0, 1920, 1080), output("A", 1920, 0, 1920, 1080)]), "duplicate")
        compare(Displays.problemOf([Object.assign(output("A", 0, 0, 1920, 1080), { scale: 0 })]), "scale")
        compare(Displays.problemOf([Object.assign(output("A", 0, 0, 1920, 1080), { transform: "sideways" })]), "transform")
        compare(Displays.problemOf([output("A", 0.5, 0, 1920, 1080)]), "position")
        compare(Displays.problemOf([output("A", 0, 0, 0, 1080)]), "mode")
        compare(Displays.problemOf([output("A", 0, 0, 1920, 1080), output("B", 1920, 500, 1280, 1024), output("C", 640, 1080, 1280, 720)]), "", "a chain of touching monitors is connected")
    }

    function test_droppedMonitorSnapsEdgeToEdge() {
        const layout = [output("A", 0, 0, 1920, 1080), output("B", 1920, 0, 1920, 1080)]
        const right = Displays.snapped(layout, "B", 2100, 30, reach)
        compare(right[1].x, 1920, "it docks against the right edge")
        compare(right[1].y, 0, "it aligns with the top edge inside the reach")
        const lower = Displays.snapped(layout, "B", 2100, 400, reach)
        compare(lower[1].x, 1920)
        compare(lower[1].y, 400, "outside the reach it keeps where it was dropped along the edge")
        const below = Displays.snapped(layout, "B", 200, 1300, reach)
        compare(below[1].y, 1080, "it docks below")
        compare(below[1].x, 200)
        const left = Displays.snapped(layout, "B", -2500, 10, reach)
        compare(left[1].x, -1920)
        compare(left[1].y, 0)
        const far = Displays.snapped(layout, "B", 1500, 5000, reach)
        compare(far[1].y, 1080, "a drop far away still lands touching")
        compare(far[1].x, 1500)
        for (const result of [right, lower, below, left, far])
            compare(Displays.problemOf(result), "", "every snap is a valid layout")
        compare(Displays.snapped([output("A", 300, 200, 1920, 1080)], "A", 900, 900, reach)[0].x, 0, "a single monitor sits at the origin")
        compare(Displays.snapped(layout, "Z", 0, 0, reach), layout, "an unknown monitor changes nothing")
    }

    function test_snappingNeverOverlapsThirdMonitor() {
        const layout = [output("A", 0, 0, 1920, 1080), output("B", 1920, 0, 1920, 1080), output("C", 0, 1080, 1920, 1080)]
        const moved = Displays.snapped(layout, "C", 1000, 1090, reach)
        compare(Displays.problemOf(moved), "")
        const rects = moved.map(Displays.rectOf)
        verify(Displays.overlapOf(rects[2], rects[0]) === 0 && Displays.overlapOf(rects[2], rects[1]) === 0)
    }

    function test_sizeChangeSettlesAgainstItsNeighbour() {
        const layout = [output("A", 0, 0, 1920, 1080), output("B", 1920, 0, 1920, 1080)]
        const grown = Displays.withOutput(layout, "A", { scale: 0.5 })
        compare(Displays.problemOf(grown), "overlap")
        const settled = Displays.settled(grown, "A", reach)
        compare(Displays.problemOf(settled), "")
    }

    function test_normalizedLayoutsKeepTheirPlace() {
        const layout = Displays.normalized([output("A", -1920, 0, 1920, 1080), output("B", 0, 200, 1920, 1080)])
        compare(layout[0].x, -1920)
        compare(layout[1].y, 200)
        verify(layout[0].modes === undefined, "only what the compositor needs is sent")
        verify(Displays.isSameLayout(layout, Displays.normalized(layout)))
        verify(!Displays.isSameLayout(layout, Displays.withOutput(layout, "A", { scale: 2 })))
    }

    function test_appliedLayoutsStayWhereTheOldOneWas() {
        const before = [output("eDP-1", 0, 2158, 1920, 1080)]
        const alone = Displays.anchored(Displays.snapped(Displays.withOutput(before, "eDP-1", { scale: 2 }), "eDP-1", 400, 300, 48), before)
        compare(alone[0].x, 0)
        compare(alone[0].y, 2158, "a lone monitor keeps the place the config gives it beside unplugged ones")
        const moved = Displays.anchored([output("A", 500, 500, 1920, 1080), output("B", 2420, 700, 1920, 1080)], [output("A", 0, 100, 1920, 1080), output("B", 1920, 100, 1920, 1080)])
        compare(moved[0].x, 0)
        compare(moved[0].y, 100)
        compare(moved[1].x, 1920)
        compare(moved[1].y, 300)
    }

    function test_layoutsThatCrossASignalAreStillRead() {
        const layout = [output("A", 0, 0, 1920, 1080), output("B", 1920, 0, 1920, 1080)]
        const listLike = { length: 2, 0: layout[0], 1: layout[1], map: mapper => layout.map(mapper) }
        compare(Displays.problemOf(listLike), "", "a layout handed over as a list that is not a script array is not empty")
        compare(Displays.problemOf([]), "empty")
        compare(Displays.problemOf(null), "empty")
    }

    function test_modesListAndPick() {
        compare(Displays.resolutionsOf(pair[0]), [{ width: 1920, height: 1080 }, { width: 1280, height: 720 }])
        compare(Displays.refreshesOf(pair[0], 1920, 1080), [144, 60])
        compare(Displays.modeFor(pair[0], 1920, 1080, 60), { width: 1920, height: 1080, refresh: 60000 })
        compare(Displays.modeFor(pair[0], 1280, 720, 60), { width: 1280, height: 720, refresh: 144000 }, "a missing rate takes the highest at that size")
        compare(Displays.modeFor(pair[0], 640, 480, 60), pair[0].mode, "an unknown size keeps the mode")
    }

    function test_driftwmConfigTextChangesOnlyItsOutputs() {
        const config = ["mod_key = \"super\"", "", "[[outputs]]", "name = \"eDP-1\" # panel", "scale = 1.0", "focus_placement = \"right\"", "", "[outputs.hot_corners]", "top_left = \"zoom-to-fit\"", "", "[output.outline]", "thickness = 0", ""].join(newline)
        const layout = [Object.assign(output("eDP-1", 0, 0, 1920, 1080), { scale: 1.25 }), Object.assign(output("DP-2", 1536, 0, 2560, 1440), { transform: "90" })]
        const written = Displays.driftwmText(config, layout)
        compare(written, ["mod_key = \"super\"", "", "[[outputs]]", "name = \"eDP-1\" # panel", "scale = 1.25", "focus_placement = \"right\"", "transform = \"normal\"", "position = [0, 0]", "mode = \"1920x1080@60\"", "", "[outputs.hot_corners]", "top_left = \"zoom-to-fit\"", "", "[[outputs]]", "name = \"DP-2\"", "scale = 1", "transform = \"90\"", "position = [1536, 0]", "mode = \"2560x1440@60\"", "", "[output.outline]", "thickness = 0", ""].join(newline))
        compare(Displays.driftwmText(written, layout), written, "writing the same layout twice changes nothing")
        compare(Displays.modeText({ width: 2560, height: 1440, refresh: 143998 }), "2560x1440@144", "driftwm takes whole hertz")
        compare(Displays.driftwmText("", [output("A", 0, 0, 800, 600)]), "[[outputs]]\nname = \"A\"\nscale = 1\ntransform = \"normal\"\nposition = [0, 0]\nmode = \"800x600@60\"\n")
    }

    function test_hyprlandRulesNameEveryField() {
        const turned = Object.assign(output("DP-1", 1920, 0, 2560, 1440), { scale: 1.5, transform: "270", mode: { width: 2560, height: 1440, refresh: 143980 } })
        compare(Displays.hyprlandRule(turned), "DP-1,2560x1440@143.98,1920x0,1.5,transform,3")
        compare(Displays.hyprlandBatch([turned, output("eDP-1", 0, 0, 1920, 1080)]), "keyword monitor DP-1,2560x1440@143.98,1920x0,1.5,transform,3 ; keyword monitor eDP-1,1920x1080@60.00,0x0,1,transform,0")
        compare(Displays.hyprlandConfig([turned]), "monitor = DP-1,2560x1440@143.98,1920x0,1.5,transform,3\n")
    }

    function test_monitorTurnedOffLeavesTheLayout() {
        const row = [output("A", 0, 0, 1920, 1080), output("B", 1920, 0, 1920, 1080), output("C", 3840, 0, 1920, 1080)]
        const dark = Displays.switched(row, "C", false, reach)
        verify(!dark.find(entry => entry.name === "C").isEnabled)
        compare(Displays.problemOf(dark), "")
        compare(Displays.boundsOf(dark), { x: 0, y: 0, width: 3840, height: 1080 }, "an output that is off takes no room")
        compare(Displays.problemOf(Displays.switched(row, "B", false, reach)), "gap", "the monitors left on still have to touch")
        const none = Displays.switched(Displays.switched(dark, "B", false, reach), "A", false, reach)
        compare(Displays.problemOf(none), "dark", "one monitor always stays on")
        const back = Displays.switched(dark, "C", true, reach)
        const lit = back.find(entry => entry.name === "C")
        verify(lit.isEnabled)
        compare([lit.x, lit.y], [3840, 0], "a monitor turned back on docks at the right of the others")
        compare(Displays.problemOf(back), "")
        verify(!Displays.isSameLayout(Displays.normalized(dark), Displays.normalized(row)))
        verify(Displays.isSameLayout(Displays.normalized(dark), Displays.normalized(Displays.withOutput(dark, "C", { x: 99 }))), "where an output that is off sits does not matter")
        compare(Displays.snapped(dark, "C", 0, 0, reach), dark, "an output that is off is never moved")
    }

    function test_monitorTurnedOffIsWrittenOff() {
        const config = ["[[outputs]]", "name = \"C\"", "scale = 1", "transform = \"normal\"", "position = [3840, 0]", "mode = \"1920x1080@60\"", ""].join(newline)
        const off = Displays.driftwmText(config, [Object.assign(output("C", 0, 0, 1920, 1080), { isEnabled: false })])
        compare(off, ["[[outputs]]", "name = \"C\"", "scale = 1", "transform = \"normal\"", "position = [3840, 0]", "mode = \"1920x1080@60\"", "enabled = false", ""].join(newline), "it keeps its place for when it comes back")
        compare(Displays.driftwmText(off, [output("C", 3840, 0, 1920, 1080)]), config, "turning it on again drops the key")
        compare(Displays.hyprlandRule(Object.assign(output("C", 0, 0, 1920, 1080), { isEnabled: false })), "C,disable")
    }

    function test_editorTurnsAMonitorOff() {
        prepare()
        editor.picked = "DP-2"
        editor.power(false)
        verify(!editor.isPickedLit)
        const rect = editor.rectOnCanvas(editor.pickedOutput)
        verify(editor.nameAt(rect.x + rect.width / 2, rect.y + rect.height / 2) !== "DP-2", "an output that is off cannot be grabbed")
        verify(editor.canApply)
        editor.apply()
        compare(requested.length, 1)
        verify(!requested[0].find(entry => entry.name === "DP-2").isEnabled)
        editor.picked = "eDP-1"
        editor.power(false)
        compare(editor.problem, "dark")
        verify(!editor.canApply)
    }

    function test_trialRevertsUnlessKept() {
        const previous = [output("A", 0, 0, 1920, 1080)]
        const next = [output("A", 0, 0, 1280, 720)]
        const trial = Displays.begun(Displays.idle(), previous, next, 1000, 15000, "before", "after")
        compare(trial.phase, "trying")
        compare(Displays.remaining(trial, 4000), 12000)
        verify(!Displays.isExpired(trial, 15999))
        verify(Displays.isExpired(trial, 16000))
        compare(Displays.remaining(Displays.idle(), 4000), 0)
        verify(!Displays.isExpired(Displays.idle(), 1e12), "an idle trial never reverts")
        const again = Displays.begun(trial, next, [output("A", 0, 0, 800, 600)], 5000, 15000, "after", "third")
        compare(again.previous, previous, "applying again during a trial still goes back to the layout before the first")
        compare(again.before, "before")
        compare(again.deadline, 20000, "and the countdown starts over")
    }

    function test_revertPutsTheOldTextBack() {
        const trial = Displays.begun(Displays.idle(), [output("A", 0, 0, 1920, 1080)], [], 0, 15000, "old text\n", "new text\n")
        compare(Displays.revertText("new text\n", trial), "old text\n", "an untouched file gets its old text back")
        const edited = Displays.revertText("[[outputs]]\nname = \"A\"\nmode = \"800x600@60\"\n# edited since\n", trial)
        compare(edited, "[[outputs]]\nname = \"A\"\nmode = \"1920x1080@60\"\n# edited since\nscale = 1\ntransform = \"normal\"\nposition = [0, 0]\n","a file edited since keeps the edit and gets the old outputs")
    }

    function test_storedTrialRecovers() {
        const trial = Displays.begun(Displays.idle(), [], [], 1000, 15000, "first", "second")
        compare(Displays.recovery(trial, 2000), "resume")
        compare(Displays.recovery(trial, 16000), "revert")
        compare(Displays.recovery(Displays.idle(), 2000), "none")
        compare(Displays.recovery({ phase: "trying" }, 2000), "none", "a broken record is ignored")
        compare(Displays.recovery(null, 2000), "none")
    }
}
