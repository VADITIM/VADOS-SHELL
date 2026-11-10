import QtQuick
import QtTest
import "../../shell/utils/Alerts.js" as Alerts

TestCase {
    name: "Alerts"

    readonly property var fields: ["key", "label", "glyph", "tint", "ids"]
    readonly property var colour: new RegExp("^#[0-9a-f]{6}$")

    function test_everySourceAnswersEveryField() {
        for (const source of Alerts.sources) {
            compare(Object.keys(source).sort(), fields.slice().sort(), source.key)
            verify(source.label.length > 0, source.key + " label")
            verify(Alerts.glyphs.indexOf(source.glyph) >= 0, source.key + " glyph " + source.glyph)
            verify(colour.test(source.tint), source.key + " tint " + source.tint)
            verify(source.ids.length > 0, source.key + " ids")
        }
        compare(Object.keys(Alerts.generic).sort(), fields.slice().sort(), "generic")
        verify(Alerts.glyphs.indexOf(Alerts.generic.glyph) >= 0, "generic glyph")
    }

    function test_keysAndIdsAreUniqueAndNormalized() {
        const keys = Alerts.sources.map(source => source.key)
        compare(new Set(keys).size, keys.length, "keys")
        const ids = []
        for (const source of Alerts.sources) {
            for (const identifier of source.ids) {
                compare(identifier, Alerts.normalize(identifier), source.key + " id " + identifier)
                ids.push(identifier)
            }
        }
        compare(new Set(ids).size, ids.length, "an id belongs to one source")
    }

    function test_recognisesByDesktopEntry() {
        compare(Alerts.identify("", "org.telegram.desktop").key, "telegram")
        compare(Alerts.identify("Vesktop", "dev.vencord.Vesktop.desktop").key, "discord")
        compare(Alerts.identify("ZapZap", "com.rtosta.zapzap").key, "whatsapp")
        compare(Alerts.identify("", "org.telegram.desktop.desktop").key, "telegram")
        compare(Alerts.identify("", "signal-desktop.desktop").key, "signal")
    }

    function test_recognisesByAppName() {
        compare(Alerts.identify("discord", "").key, "discord")
        compare(Alerts.identify("Signal", undefined).key, "signal")
        compare(Alerts.identify("WhatsApp Web", "chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default").key, "whatsapp")
        compare(Alerts.identify("Telegram Desktop", "").key, "telegram")
    }

    function test_desktopEntryWinsOverAppName() {
        compare(Alerts.identify("Spotify", "org.mozilla.thunderbird").key, "thunderbird")
    }

    function test_unknownSourcesAreGenericWithTheirName() {
        const source = Alerts.identify("  NetworkManager ", "nm-applet")
        compare(source.key, "generic")
        compare(source.label, "NetworkManager")
        compare(source.glyph, "bell")
        compare(source.tint, "")
        compare(Alerts.identify(null, null).label, "")
        compare(Alerts.generic.label, "", "identify never changes the generic row")
    }

    function test_wordsDoNotMatchInsideOtherWords() {
        compare(Alerts.identify("Slacker Radio", "").key, "generic")
        compare(Alerts.identify("Signalling Tool", "").key, "generic")
    }

    function test_plainTextDropsMarkupAndEntities() {
        compare(Alerts.plainOf("<b>Hello</b> &amp; welcome"), "Hello & welcome")
        compare(Alerts.plainOf("one<br/>two\n\nthree\t four"), "one two three four")
        compare(Alerts.plainOf("&amp;lt;tag&amp;gt;"), "&lt;tag&gt;")
        compare(Alerts.plainOf("a &lt; b"), "a < b")
        compare(Alerts.plainOf("<b>Mum</b>: hi"), "Mum: hi", "inline tags leave no gap")
        compare(Alerts.plainOf("one<p>two</p>three"), "one two three", "block tags keep words apart")
        compare(Alerts.plainOf(undefined), "")
    }

    function test_clipCutsAtTheLimit() {
        compare(Alerts.clip("short", 10), "short")
        compare(Alerts.clip("exactly ten", 11), "exactly ten")
        const clipped = Alerts.clip("a long message that runs on", 10)
        compare(clipped.length, 10)
        verify(clipped.endsWith("…"), clipped)
        compare(Alerts.clip("word      gap here", 6), "word…")
    }

    function test_leadIsTheNewest() {
        compare(Alerts.leadOf([]), null)
        compare(Alerts.leadOf(null), null)
        compare(Alerts.leadOf([{ id: 1 }, { id: 2 }]).id, 2)
    }
}
