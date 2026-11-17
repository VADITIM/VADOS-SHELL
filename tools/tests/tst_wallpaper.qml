import QtQuick
import QtTest
import qs.config
import qs.modules.wallpaper

Item {
    id: scene

    width: 64
    height: 36

    readonly property string first: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAFElEQVQImWNUcEhggAEmBiSAmwMAJkQAyNOZ5U8AAAAASUVORK5CYII="
    readonly property string second: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAFElEQVQImWM80ODAAANMDEgANwcATIQBiPt/5qMAAAAASUVORK5CYII="

    Wallpaper {
        id: wallpaper
        anchors.fill: parent
        source: scene.first
    }

    TestCase {
        name: "Wallpaper"
        when: windowShown

        function slotOf(path) {
            return wallpaper.children.find(child => child.path === path)
        }

        function frontSlot() {
            return wallpaper.children[wallpaper.front]
        }

        function init() {
            wallpaper.source = scene.first
            tryVerify(() => frontSlot().path === scene.first && frontSlot().presence >= 1, Motion.wallpaper.fade * 4)
        }

        function test_theImageIsLoadedOnce() {
            compare(wallpaper.children.filter(child => child.path === scene.first).length, 1, "only one slot holds the image")
        }

        function test_aNewImageFadesInOverTheOldOne() {
            const before = wallpaper.front
            wallpaper.source = scene.second
            tryVerify(() => wallpaper.front !== before)
            verify(slotOf(scene.first) !== undefined, "the old image stays under the new one while it fades in")
            tryVerify(() => slotOf(scene.second).presence >= 1, Motion.wallpaper.fade * 4)
            compare(slotOf(scene.second).z, 1)
        }

        function test_switchingBackReusesTheSlotThatHoldsIt() {
            wallpaper.source = scene.second
            wallpaper.source = scene.first
            tryVerify(() => frontSlot().path === scene.first)
        }

        function test_anEmptySourceShowsNothing() {
            wallpaper.source = ""
            compare(wallpaper.children.filter(child => child.path !== undefined && child.path.length > 0).length, 0)
            tryVerify(() => frontSlot().presence <= 0, Motion.wallpaper.fade * 4)
        }
    }
}
