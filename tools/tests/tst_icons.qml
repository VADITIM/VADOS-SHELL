import QtQuick
import QtTest
import "../../shell/utils/Icons.js" as Icons

TestCase {
    name: "Icons"

    readonly property var allowed: "MLHVCSQTAZmlhvcsqtaz0123456789.-+eE "

    function test_everyIconDrawsSomething() {
        for (const name in Icons.paths) {
            const icon = Icons.paths[name]
            compare(Object.keys(icon).sort(), ["fill", "stroke"], name)
            verify(icon.stroke.length + icon.fill.length > 0, name)
        }
    }

    function test_pathsHoldOnlyPathCharacters() {
        for (const name in Icons.paths) {
            const text = Icons.paths[name].stroke + Icons.paths[name].fill
            for (const character of text)
                verify(allowed.indexOf(character) >= 0, name + " has " + character)
        }
    }

    function test_everyStepNamesAnIcon() {
        for (const name in Icons.steps) {
            const step = Icons.steps[name]
            verify(Icons.has(step.otherwise), name + " otherwise")
            if (step.charging)
                verify(Icons.has(step.charging), name + " charging")
            for (let index = 0; index < step.above.length; index++) {
                verify(Icons.has(step.above[index][1]), name + " " + step.above[index][1])
                if (index > 0)
                    verify(step.above[index][0] < step.above[index - 1][0], name + " thresholds fall")
            }
        }
    }

    function test_levelsPickTheirStep() {
        compare(Icons.pick("speaker", 0, false), "volume-0")
        compare(Icons.pick("speaker", 0.3, false), "volume-1")
        compare(Icons.pick("speaker", 0.9, false), "volume-2")
        compare(Icons.pick("wifi", 0, false), "wifi-off")
        compare(Icons.pick("wifi", 0.03, false), "wifi-1")
        compare(Icons.pick("wifi", 1, false), "wifi-4")
        compare(Icons.pick("battery", 0.05, false), "battery-critical")
        compare(Icons.pick("battery", 0.15, false), "battery-empty")
        compare(Icons.pick("battery", 0.5, false), "battery-mid")
        compare(Icons.pick("battery", 1, false), "battery-full")
        compare(Icons.pick("battery", 0.05, true), "battery-charging")
        compare(Icons.pick("speaker", 0.9, true), "volume-2", "only the battery has a charging icon")
    }

    function test_otherNamesPassThrough() {
        compare(Icons.pick("power", 1, false), "power")
        compare(Icons.pick("weather-rain", 0, false), "weather-rain")
        verify(!Icons.has("weather-rain"))
        compare(Icons.strokeOf("weather-rain"), "")
        compare(Icons.fillOf("weather-rain"), "")
    }

    function test_filledIconsHaveNoStroke() {
        for (const name of ["bolt", "brush", "user", "moon"]) {
            compare(Icons.strokeOf(name), "", name)
            verify(Icons.fillOf(name).length > 0, name)
        }
    }
}
