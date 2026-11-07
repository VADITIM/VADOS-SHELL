import QtQuick
import QtTest
import "../../shell/utils/Log.js" as Log

TestCase {
    name: "Log"

    function test_oneFormat() {
        Log.clear()
        compare(Log.format("weather", "offline"), "vados: weather: offline")
        ignoreWarning("vados: format: one line")
        verify(Log.warn("format", "one line", 1000))
        const entry = Log.recent()[0]
        compare(entry.level, "warn")
        compare(entry.subsystem, "format")
        compare(entry.message, "one line")
        compare(entry.time, 1000)
    }

    function test_repeatsInsideTheWindowAreCounted() {
        Log.clear()
        ignoreWarning("vados: poll: failed")
        verify(Log.warn("poll", "failed", 0))
        verify(!Log.warn("poll", "failed", 1000), "a repeat is not printed")
        verify(!Log.warn("poll", "failed", Log.repeatWindow - 1))
        compare(Log.recent().length, 1)
        compare(Log.recent()[0].repeats, 2)
        compare(Log.recent()[0].last, Log.repeatWindow - 1)
    }

    function test_repeatAfterTheWindowIsPrintedWithItsCount() {
        Log.clear()
        ignoreWarning("vados: flood: failed")
        Log.warn("flood", "failed", 0)
        Log.warn("flood", "failed", 10)
        Log.warn("flood", "failed", 20)
        ignoreWarning("vados: flood: failed (repeated 2 more times)")
        verify(Log.warn("flood", "failed", Log.repeatWindow))
        compare(Log.recent().length, 2)
        compare(Log.recent()[1].repeats, 0)
    }

    function test_otherMessagesAreNotHeldBack() {
        Log.clear()
        ignoreWarning("vados: first: failed")
        ignoreWarning("vados: second: failed")
        verify(Log.warn("first", "failed", 0))
        verify(Log.warn("second", "failed", 0))
        verify(Log.info("first", "failed", 0), "another level is another message")
    }

    function test_ringKeepsOnlyTheMostRecent() {
        Log.clear()
        for (let index = 0; index < Log.capacity + 10; index++)
            Log.info("ring", "entry " + index, index)
        const entries = Log.recent()
        compare(entries.length, Log.capacity)
        compare(entries[0].message, "entry 10")
        compare(entries[entries.length - 1].message, "entry " + (Log.capacity + 9))
    }

    function test_recentIsCopied() {
        Log.clear()
        Log.info("copy", "kept", 0)
        Log.recent().length = 0
        compare(Log.recent().length, 1)
    }

    function test_repeatMemoryStaysBounded() {
        Log.clear()
        for (let index = 0; index < Log.capacity * 3; index++)
            Log.info("memory", "entry " + index, index * Log.repeatWindow)
        verify(Object.keys(Log.latest).length <= Log.capacity + 1)
    }
}
