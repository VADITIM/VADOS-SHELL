import QtQuick
import QtTest
import "../../shell/utils/Schema.js" as Schema

TestCase {
    name: "Schema"

    function cloneOf(value) {
        return JSON.parse(JSON.stringify(value))
    }

    function test_everyDefaultValidatesClean() {
        for (const key in Schema.settings)
            compare(Schema.findProblem(key, Schema.settings[key].fallback), "", key)
        const defaults = Schema.createDefaults()
        const repaired = Schema.repair(cloneOf(defaults))
        compare(repaired.problems.length, 0)
        verify(!repaired.shouldWrite)
        compare(repaired.settings, defaults)
        compare(defaults.version, Schema.version)
    }

    function test_fractionAndTintRules() {
        verify(Schema.findProblem("pills.opacity", 1.5) !== "")
        verify(Schema.findProblem("pills.opacity", 0.5) === "")
        verify(Schema.findProblem("pills.color", "red") !== "")
        verify(Schema.findProblem("pills.color", "") === "")
    }

    function test_countRule() {
        verify(Schema.findProblem("notifications.history", 200) === "")
        verify(Schema.findProblem("notifications.history", 0) === "")
        verify(Schema.findProblem("notifications.history", -1) !== "")
        verify(Schema.findProblem("notifications.history", 2.5) !== "")
        verify(Schema.findProblem("notifications.history", "200") !== "")
        verify(Schema.findProblem("notifications.history", 5000) !== "")
    }

    function test_cleanSettingsAreIdempotent() {
        const settings = Schema.createDefaults()
        settings.taskbar.side = "right"
        settings.taskbar.style = "bare"
        settings.appearance.accent = "#80ff0000"
        settings.search.favorites = ["firefox.desktop", "kitty.desktop"]
        settings.rendering.quality = "lite"
        const first = Schema.repair(cloneOf(settings))
        compare(first.problems.length, 0)
        verify(!first.shouldWrite)
        compare(first.settings, settings)
        const second = Schema.repair(cloneOf(first.settings))
        compare(second.settings, first.settings)
        verify(!second.shouldWrite)
    }

    function test_wrongTypesFallBackWithAProblem() {
        const cases = [
            ["taskbar", "enabled", "yes", true],
            ["taskbar", "compact", 1, false],
            ["profile", "name", 42, ""],
            ["weather", "location", null, ""],
            ["search", "favorites", "firefox.desktop", []],
            ["search", "favorites", ["firefox.desktop", 7], []],
            ["motion", "reduced", "false", false]
        ]
        for (const entry of cases) {
            const settings = Schema.createDefaults()
            settings[entry[0]][entry[1]] = entry[2]
            const repaired = Schema.repair(settings)
            const key = entry[0] + "." + entry[1]
            compare(repaired.settings[entry[0]][entry[1]], entry[3], key)
            compare(repaired.problems.length, 1, key)
            verify(repaired.problems[0].startsWith(key + " is "), repaired.problems[0])
            verify(repaired.shouldWrite, key)
        }
    }

    function test_valuesOutsideTheirChoicesFallBack() {
        const cases = [
            ["taskbar", "side", "top", "left"],
            ["taskbar", "style", "glass", "floating"],
            ["desktop", "mode", "tiling", "canvas"],
            ["rendering", "quality", "ultra", "full"],
            ["appearance", "accent", "white", "#ffffff"],
            ["appearance", "accent", "#ggg", "#ffffff"]
        ]
        for (const entry of cases) {
            const settings = Schema.createDefaults()
            settings[entry[0]][entry[1]] = entry[2]
            const repaired = Schema.repair(settings)
            const key = entry[0] + "." + entry[1]
            compare(repaired.settings[entry[0]][entry[1]], entry[3], key)
            compare(repaired.problems.length, 1, key)
            verify(repaired.problems[0].indexOf("expected") > 0, repaired.problems[0])
            verify(repaired.shouldWrite, key)
        }
    }

    function test_aGroupThatIsNotAnObjectFallsBack() {
        const repaired = Schema.repair({ version: 1, taskbar: "left" })
        compare(repaired.settings.taskbar, Schema.createDefaults().taskbar)
        compare(repaired.problems.length, 1)
        verify(repaired.shouldWrite)
    }

    function test_unknownKeysAreReportedAndDroppedWithoutAWrite() {
        const repaired = Schema.repair({ version: 1, taskbar: { side: "right", colour: "red" }, wallpaper: { path: "/a" } })
        compare(repaired.settings.taskbar.side, "right")
        verify(!("colour" in repaired.settings.taskbar))
        verify(!("wallpaper" in repaired.settings))
        compare(repaired.problems.length, 2)
        verify(!repaired.shouldWrite)
    }

    function test_missingKeysTakeTheirDefaultsSilently() {
        const repaired = Schema.repair({ version: 1, taskbar: { side: "right" } })
        compare(repaired.settings.taskbar.side, "right")
        compare(repaired.settings.taskbar.style, "floating")
        compare(repaired.settings.rendering.quality, "full")
        compare(repaired.problems.length, 0)
        verify(!repaired.shouldWrite)
    }

    function test_anUnversionedFileMigratesByValidation() {
        const old = { taskbar: { side: "right", compact: true }, search: { favorites: ["kitty.desktop"] } }
        const migrated = Schema.migrate(cloneOf(old))
        compare(migrated.from, 0)
        compare(migrated.problems.length, 0)
        const repaired = Schema.repair(cloneOf(old))
        compare(repaired.problems.length, 0)
        verify(repaired.shouldWrite)
        compare(repaired.settings.version, Schema.version)
        compare(repaired.settings.taskbar.side, "right")
        compare(repaired.settings.taskbar.compact, true)
        compare(repaired.settings.search.favorites, ["kitty.desktop"])
        const again = Schema.repair(cloneOf(repaired.settings))
        verify(!again.shouldWrite)
        compare(again.settings, repaired.settings)
    }

    function test_aBrokenVersionIsReadAsUnversioned() {
        const repaired = Schema.repair({ version: "two", taskbar: { side: "right" } })
        compare(repaired.problems.length, 1)
        verify(repaired.problems[0].startsWith("version is"))
        verify(repaired.shouldWrite)
        compare(repaired.settings.taskbar.side, "right")
    }

    function test_aNewerFileIsReadButNeverWritten() {
        const repaired = Schema.repair({ version: Schema.version + 1, taskbar: { side: "top" } })
        compare(repaired.settings.taskbar.side, "left")
        compare(repaired.problems.length, 2)
        verify(!repaired.shouldWrite)
    }

    function test_somethingOtherThanAnObjectKeepsTheDefaults() {
        for (const raw of [null, 3, "text", []]) {
            const repaired = Schema.repair(raw)
            compare(repaired.settings, Schema.createDefaults())
            compare(repaired.problems.length, 1)
            verify(!repaired.shouldWrite)
        }
    }

    function test_settersAreCheckedByTheSameSchema() {
        compare(Schema.findProblem("taskbar.side", "right"), "")
        verify(Schema.findProblem("taskbar.side", "top") !== "")
        verify(Schema.findProblem("search.favorites", ["a", undefined]) !== "")
        verify(Schema.findProblem("taskbar.width", 3) !== "")
        compare(Schema.findProblem("appearance.accent", "#80112233"), "")
    }

    function test_defaultsAreFreshCopies() {
        const first = Schema.createDefaults()
        first.search.favorites.push("leak.desktop")
        compare(Schema.createDefaults().search.favorites, [])
        compare(Schema.settings["search.favorites"].fallback, [])
    }
}
