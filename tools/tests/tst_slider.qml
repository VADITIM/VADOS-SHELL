import QtQuick
import QtTest
import qs.components

Item {
    width: 400
    height: 100

    property var values: []

    Slider {
        id: slider
        x: 50
        width: 220
        value: 0.5
        look: ({ track: 4, grab: 24, step: 0.05 })
        pace: ({ settle: 180, thicken: 2 })
        onMoved: value => {
            values.push(value)
            slider.value = value
        }
    }

    TestCase {
        name: "Slider"
        when: windowShown

        function start(value) {
            values = []
            slider.value = value
        }

        function test_tapChangesNothing() {
            start(0.5)
            mouseClick(slider, 10, slider.height / 2)
            mouseClick(slider, 210, slider.height / 2)
            compare(values, [])
            compare(slider.value, 0.5)
        }

        function test_pressAloneGrowsWithoutChangingTheValue() {
            start(0.5)
            mousePress(slider, 100, slider.height / 2)
            verify(slider.isHeld)
            verify(!slider.isDragging)
            tryCompare(slider, "thickness", 8)
            const bar = slider.children[0]
            compare(bar.y + bar.height / 2, slider.height / 2)
            mouseRelease(slider, 100, slider.height / 2)
            tryCompare(slider, "thickness", 4)
            compare(values, [])
        }

        function test_verticalTravelChangesNothing() {
            start(0.5)
            mousePress(slider, 100, slider.height / 2)
            mouseMove(slider, 101, slider.height / 2 + 40)
            mouseRelease(slider, 101, slider.height / 2 + 40)
            compare(values, [])
        }

        function test_valueFollowsTravelNotThePressPoint() {
            start(0.5)
            const reach = slider.width
            mousePress(slider, 10, slider.height / 2)
            for (let step = 1; step <= 5; ++step)
                mouseMove(slider, 10 + step * reach / 10, slider.height / 2)
            verify(slider.isDragging)
            fuzzyCompare(slider.value, 1, 0.001)
            tryCompare(slider, "thickness", 8)
            mouseRelease(slider, 10 + reach / 2, slider.height / 2)
            verify(!slider.isDragging)
            tryCompare(slider, "thickness", 4)
            verify(values.every(value => value >= 0.5))
        }

        function test_wholeTrackIsTheWholeRange() {
            start(0)
            const reach = slider.width
            mousePress(slider, 100, slider.height / 2)
            mouseMove(slider, 110, slider.height / 2)
            mouseMove(slider, 100 + reach / 4, slider.height / 2)
            fuzzyCompare(slider.value, 0.25, 0.001)
            mouseRelease(slider, 100 + reach / 4, slider.height / 2)
        }

        function test_nudgeStepsOnTheGridAndClamps() {
            start(0.53)
            slider.nudge(1)
            fuzzyCompare(slider.value, 0.6, 0.0001)
            start(0.99)
            slider.nudge(1)
            compare(slider.value, 1)
            start(0.01)
            slider.nudge(-1)
            compare(slider.value, 0)
        }
    }
}
