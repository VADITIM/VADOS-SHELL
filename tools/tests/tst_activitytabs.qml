import QtQuick
import QtTest
import "../../shell/utils/ActivityTabs.js" as Tabs

TestCase {
    name: "ActivityTabs"

    readonly property var tabs: ["notifications", "media", "call"]

    function test_slotsSitAboveAndBelowTheLead() {
        compare(Tabs.slotOf(tabs, "media", "notifications"), -1)
        compare(Tabs.slotOf(tabs, "media", "media"), 0)
        compare(Tabs.slotOf(tabs, "media", "call"), 1)
        compare(Tabs.slotOf(tabs, "recording", "notifications"), 1, "a lead outside the tabs puts every dot below")
    }

    function test_distanceMergesIntoThePill() {
        compare(Tabs.distanceOf(0, 20, 16), 0)
        compare(Tabs.distanceOf(0.5, 20, 16), 10)
        compare(Tabs.distanceOf(1, 20, 16), 20)
        compare(Tabs.distanceOf(-2, 20, 16), -36)
    }

    function test_stepStopsAtTheEndsAndEntersFromOutside() {
        compare(Tabs.stepFrom(tabs, "notifications", 1), "media")
        compare(Tabs.stepFrom(tabs, "call", 1), "call")
        compare(Tabs.stepFrom(tabs, "notifications", -1), "notifications")
        compare(Tabs.stepFrom(tabs, "recording", 1), "notifications")
        compare(Tabs.stepFrom([], "media", 1), "media")
    }

    function test_spanCountsTheDots() {
        compare(Tabs.spanOf(tabs, "media").above, 1)
        compare(Tabs.spanOf(tabs, "media").below, 1)
        compare(Tabs.spanOf(tabs, "recording").below, 3)
    }
}
