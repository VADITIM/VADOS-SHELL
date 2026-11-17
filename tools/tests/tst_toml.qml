import QtQuick
import QtTest
import "../../shell/utils/Toml.js" as Toml

TestCase {
    name: "Toml"

    readonly property string newline: "\n"

    readonly property string config: "mod_key = \"super\"\n\n[background]\ntype = \"shader\" # old\npath = \"/old.glsl\"\n\n[keybindings]\n\"mod+q\" = \"close-window\"\npath = \"kept\"\n"

    function test_replacesOnlyTheKeysOfItsTable() {
        const next = Toml.withTable(config, "background", { type: "wallpaper", path: "/new.png" })
        compare(next, "mod_key = \"super\"\n\n[background]\ntype = \"wallpaper\"\npath = \"/new.png\"\n\n[keybindings]\n\"mod+q\" = \"close-window\"\npath = \"kept\"\n")
    }

    function test_addsAMissingKeyUnderTheHeader() {
        const next = Toml.withTable("[background]\ntype = \"default\"\n\n[keybindings]\n", "background", { type: "wallpaper", path: "/new.png" })
        compare(next, "[background]\npath = \"/new.png\"\ntype = \"wallpaper\"\n\n[keybindings]\n")
    }

    function test_appendsAMissingTable() {
        compare(Toml.withTable("mod_key = \"super\"\n", "background", { type: "wallpaper", path: "/new.png" }), "mod_key = \"super\"\n\n[background]\ntype = \"wallpaper\"\npath = \"/new.png\"\n")
        compare(Toml.withTable("", "background", { type: "none" }), "[background]\ntype = \"none\"\n")
    }

    function test_writingTheSameValuesChangesNothing() {
        const once = Toml.withTable(config, "background", { type: "wallpaper", path: "/new.png" })
        compare(Toml.withTable(once, "background", { type: "wallpaper", path: "/new.png" }), once)
    }

    function test_quotesAndBackslashesAreEscaped() {
        compare(Toml.quoted("/a \"b\"\\c.png"), "\"/a \\\"b\\\"\\\\c.png\"")
    }

    function test_literalsKeepTheirType() {
        compare(Toml.literal(1.25), "1.25")
        compare(Toml.literal([0, -1080]), "[0, -1080]")
        compare(Toml.literal(true), "true")
        compare(Toml.literal("90"), "\"90\"")
    }

    function test_entryOfAnArrayIsFoundByItsKey() {
        const lines = ["[[outputs]]", "name = \"DP-1\"", "scale = 2.0", "", "[[outputs]]", "name = \"DP-2\"   # desk", "scale = 1.0", "", "[keybindings]", ""]
        const next = Toml.withEntry(lines.join(newline), "outputs", "name", "DP-2", { scale: 1.5, position: [1920, 0] })
        compare(next, ["[[outputs]]", "name = \"DP-1\"", "scale = 2.0", "", "[[outputs]]", "name = \"DP-2\"   # desk", "scale = 1.5", "position = [1920, 0]", "", "[keybindings]", ""].join(newline))
    }

    function test_missingEntryJoinsTheOthers() {
        const lines = ["[[outputs]]", "name = \"DP-1\"", "", "[outputs.hot_corners]", "top_left = \"none\"", "", "[keybindings]", ""]
        const next = Toml.withEntry(lines.join(newline), "outputs", "name", "DP-2", { scale: 1 })
        compare(next, ["[[outputs]]", "name = \"DP-1\"", "", "[outputs.hot_corners]", "top_left = \"none\"", "", "[[outputs]]", "name = \"DP-2\"", "scale = 1", "", "[keybindings]", ""].join(newline))
        compare(Toml.withEntry("", "outputs", "name", "DP-2", { scale: 1 }), ["[[outputs]]", "name = \"DP-2\"", "scale = 1", ""].join(newline))
    }

    function test_aNullValueRemovesTheKey() {
        const lines = ["[[outputs]]", "name = \"DP-1\"", "enabled = false", "scale = 2.0", "", "[keybindings]", ""]
        const next = Toml.withEntry(lines.join(newline), "outputs", "name", "DP-1", { enabled: null, scale: 1 })
        compare(next, ["[[outputs]]", "name = \"DP-1\"", "scale = 1", "", "[keybindings]", ""].join(newline))
        compare(Toml.withEntry(next, "outputs", "name", "DP-1", { enabled: null }), next, "a key that is not there stays away")
        compare(Toml.withEntry("", "outputs", "name", "DP-2", { enabled: null, scale: 1 }), ["[[outputs]]", "name = \"DP-2\"", "scale = 1", ""].join(newline))
    }

    function test_aCommentedTableIsNotTheTable() {
        const next = Toml.withTable("# [background]\n# type = \"default\"\n", "background", { type: "none" })
        compare(next, "# [background]\n# type = \"default\"\n\n[background]\ntype = \"none\"\n")
    }
}
