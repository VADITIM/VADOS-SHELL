import QtQuick
import QtTest
import "../../shell/utils/Keyboards.js" as Keyboards
import "../../shell/utils/Keymap.js" as Keymap

TestCase {
    name: "Keyboards"

    readonly property string rules: "! model\n  pc105           Generic 105-key PC\n\n! layout\n  us              English (US)\n  de              German\n\n! variant\n  dvorak          us: English (Dvorak)\n  nodeadkeys      de: German (no dead keys)\n\n! option\n  grp             Switching to another layout\n"
    readonly property string devices: "I: Bus=0019 Vendor=0000 Product=0001 Version=0000\nN: Name=\"Power Button\"\nH: Handlers=kbd event1 \nB: EV=3\n\nI: Bus=0011 Vendor=0001 Product=0001 Version=ab83\nN: Name=\"AT Translated Set 2 keyboard\"\nH: Handlers=sysrq kbd event3 leds \nB: EV=120013\n\nI: Bus=0003 Vendor=3434 Product=d030 Version=0111\nN: Name=\"Keychron Link\"\nH: Handlers=sysrq kbd event9 leds \nB: EV=120013\n"

    function test_parsesLayoutsWithTheirVariants() {
        const choices = Keyboards.parseRules(rules)
        compare(choices.map(Keyboards.keyOf), ["us", "us(dvorak)", "de", "de(nodeadkeys)"])
        compare(choices[3].description, "German (no dead keys)")
        verify(Keyboards.matches(choices[1], "DVOR"))
        verify(!Keyboards.matches(choices[2], "dvorak"))
    }

    function test_listsOnlyRepeatingKeyboardsBuiltInFirst() {
        const found = Keyboards.parseDevices(devices)
        compare(found.map(entry => entry.name), ["AT Translated Set 2 keyboard", "Keychron Link"])
        verify(found[0].isBuiltIn)
        verify(!found[1].isBuiltIn)
    }

    function test_overridesReplacePerDeviceAndClear() {
        let entries = Keyboards.withOverride([], { device: "*", layout: "de", variant: "nodeadkeys" })
        entries = Keyboards.withOverride(entries, { device: "Keychron Link", layout: "us", variant: "" })
        entries = Keyboards.withOverride(entries, { device: "*", layout: "fr", variant: "" })
        compare(entries, ["Keychron Link|us|", "*|fr|"])
        compare(Keyboards.withOverride(entries, { device: "*", layout: "", variant: "" }), ["Keychron Link|us|"])
        compare(Keyboards.overrideFor(entries, "Keychron Link").layout, "us")
    }

    function test_writesHyprlandBlocksAndRefusesUnsafeValues() {
        const text = Keyboards.hyprlandConfig(["*|de|nodeadkeys", "Keychron Link|us|", "Evil|us\nexec = rm|"])
        verify(text.includes("input {\n    kb_layout = de\n    kb_variant = nodeadkeys\n}"))
        verify(text.includes("name = keychron-link"))
        verify(!text.includes("exec"))
    }

    function test_setsAndRestoresTheDriftwmLayout() {
        const config = "[input.keyboard]\nlayout = \"de\"\noptions = \"numpad:mac\" # kept\n\n[input.mouse]\n"
        compare(Keyboards.driftwmLayout(config).layout, "de")
        const written = Keyboards.driftwmText(config, ["*|us|dvorak"], null)
        verify(written.includes("layout = \"us\""))
        verify(written.includes("variant = \"dvorak\""))
        verify(written.includes("options = \"numpad:mac\" # kept"))
        const restored = Keyboards.driftwmText(written, [], { layout: "de", variant: "" })
        verify(restored.includes("layout = \"de\""))
        compare(Keyboards.driftwmText(config, ["Keychron Link|us|"], null), config)
    }

    function test_parsesAKeyboardLayoutEditorDefinition() {
        const keys = Keymap.parseLayout([["0,0", { w: 2 }, "0,1", "0,2\n\n\n0,1", "0,3\n\n\n0,0"], [{ y: 0.5, x: 1 }, "1,0", { d: true }, "1,1"]])
        compare(keys.length, 4)
        compare(keys[1].width, 2)
        compare(keys[2].x, 4)
        compare(keys[3].y, 1.5)
        compare(keys[3].x, 1)
        compare(Keymap.extentOf(keys).width, 5)
    }

    function test_fallbackIsAnAnsiBoard() {
        const keys = Keymap.fallback()
        verify(keys.length > 60)
        compare(Keymap.extentOf(keys).width, 15)
    }

    function test_editsTrackOnlyChangedKeys() {
        let edits = Keymap.withEdit({}, 0, 1, 2, 0x04, 0x05)
        compare(Keymap.changesOf(edits), [{ layer: 0, row: 1, column: 2, code: 0x04 }])
        edits = Keymap.withEdit(edits, 0, 1, 2, 0x05, 0x05)
        compare(Keymap.changesOf(edits).length, 0)
        compare(Keymap.codeAt([[[4, 5, 6]]], 0, 0, 2), 6)
    }

    function test_layerKeysNeedTheModernProtocol() {
        verify(!Keymap.catalogue(9).some(entry => entry.group === "layers"))
        compare(Keymap.labelOf(0x5221, 12), "HOLD 1")
        compare(Keymap.labelOf(0x5221, 9), "0x5221")
        compare(Keymap.labelOf(0x04, 9), "A")
    }
}
