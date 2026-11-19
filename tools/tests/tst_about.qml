import QtQuick
import QtTest
import "../../shell/utils/About.js" as About

TestCase {
    name: "About"

    function test_theSystemNameComesFromOsRelease() {
        compare(About.osNameOf("NAME=\"Arch Linux\"\nPRETTY_NAME=\"Arch Linux\"\nID=arch"), "Arch Linux")
        compare(About.osNameOf("NAME=Fedora\nID=fedora"), "Fedora")
        compare(About.osNameOf(""), "")
    }

    function test_uptimeReadsInTheLargestUnits() {
        compare(About.uptimeOf(0), "")
        compare(About.uptimeOf(59), "0 M")
        compare(About.uptimeOf(3 * 3600 + 12 * 60), "3 H 12 M")
        compare(About.uptimeOf(2 * 86400 + 4 * 3600 + 30), "2 D 4 H")
    }

    function test_memoryRoundsToGigabytes() {
        compare(About.memoryOf(32 * 1073741824), "32 GB")
        compare(About.memoryOf(0), "")
    }

    function test_everyKeyHasALabel() {
        verify(About.keys.every(key => About.labels[key].length > 0))
    }
}
