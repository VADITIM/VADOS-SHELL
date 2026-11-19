import QtQuick
import QtTest
import "../../shell/utils/Figlet.js" as Figlet

TestCase {
    name: "Figlet"

    readonly property string sample: sampleFont()

    function sampleFont() {
        const lines = ["flf2a$ 3 2 4 0 1", "a comment line", "$$@", "$$@", "$$@@"]
        for (let code = 33; code <= 126; code++) {
            if (code === 65)
                lines.push("A @", "AA@", "A@@")
            else if (code === 66)
                lines.push(" B@", "BB@", " B@@")
            else
                lines.push("?@", "?@", "?@@")
        }
        return lines.join("\n")
    }

    function test_aBrokenFileGivesNoFont() {
        compare(Figlet.parse(""), null)
        compare(Figlet.parse("not a font"), null)
    }

    function test_glyphsLoseTheirEndMarks() {
        const font = Figlet.parse(sample)
        compare(font.height, 3)
        compare(font.glyphs[65], ["A ", "AA", "A"])
    }

    function test_charactersFitAgainstEachOther() {
        const font = Figlet.parse(sample)
        compare(Figlet.render(font, "AB"), "A  B\nAABB\nA  B")
    }

    function test_hardBlanksKeepTheirSpace() {
        const font = Figlet.parse(sample)
        compare(Figlet.render(font, "A A"), "A   A\nAA  AA\nA   A")
    }

    function test_unknownCharactersAreSkipped() {
        const font = Figlet.parse(sample)
        compare(Figlet.render(font, "A一"), "A\nAA\nA")
        compare(Figlet.render(null, "A"), "")
    }
}
