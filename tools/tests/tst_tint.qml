import QtQuick
import QtTest
import "../../shell/utils/Tint.js" as Tint

Item {
    id: root
    width: 64
    height: 64

    readonly property var look: ({ sample: 8, buckets: 12, alpha: 0.5, saturation: 0.25, darkest: 0.12, brightest: 0.92, lightness: 0.6 })
    property string sampled: ""

    Image {
        id: picture
        source: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAHUlEQVR4nGP4DwQ3y8PBGBubAZ8kXAE+UxiGghUAJ3zFj6ncqEkAAAAASUVORK5CYII="
        onStatusChanged: if (status === Image.Ready) sampler.requestPaint()
    }

    Canvas {
        id: sampler
        width: root.look.sample
        height: root.look.sample
        opacity: 0
        onPaint: {
            const context = getContext("2d")
            context.drawImage(picture, 0, 0, width, height)
            root.sampled = Tint.dominant(context.getImageData(0, 0, width, height).data, root.look)
        }
    }

    function pixelsOf(colors) {
        const pixels = []
        for (const color of colors)
            pixels.push(color[0], color[1], color[2], color[3])
        return pixels
    }

    function shadeOfHex(hex) {
        const color = Qt.color(hex)
        return Tint.shadeOf(color.r, color.g, color.b)
    }

    TestCase {
        name: "Tint"
        when: windowShown

        function test_theMostColourfulHueWins() {
            const pixels = root.pixelsOf([[88, 101, 242, 255], [88, 101, 242, 255], [90, 100, 240, 255], [240, 60, 60, 255], [255, 255, 255, 255], [0, 0, 0, 255]])
            const shade = root.shadeOfHex(Tint.dominant(pixels, root.look))
            verify(shade.hue > 0.6 && shade.hue < 0.7, "blue hue " + shade.hue)
        }

        function test_greyAndTransparentPixelsGiveNothing() {
            const pixels = root.pixelsOf([[128, 128, 128, 255], [255, 255, 255, 255], [0, 0, 0, 255], [255, 0, 0, 10]])
            compare(Tint.dominant(pixels, root.look), "")
        }

        function test_darkColoursAreLiftedToBeReadable() {
            const pixels = root.pixelsOf([[20, 40, 120, 255]])
            const shade = root.shadeOfHex(Tint.dominant(pixels, root.look))
            verify(shade.lightness >= root.look.lightness - 0.01, "lightness " + shade.lightness)
        }

        function test_shadeRoundTrips() {
            for (const hex of ["#5865f2", "#1db954", "#e01e5a", "#d97757"]) {
                const color = Qt.color(hex)
                compare(Tint.hexOf(Tint.colorOf(Tint.shadeOf(color.r, color.g, color.b))), hex)
            }
        }

        function test_aNudgeDarkensLightColoursAndLightensDarkOnes() {
            const light = root.shadeOfHex("#7fb8ff")
            const darker = root.shadeOfHex(Tint.nudge("#7fb8ff", 0.1))
            verify(Math.abs(darker.lightness - (light.lightness - 0.1)) < 0.01, "darker " + darker.lightness)
            verify(Math.abs(darker.hue - light.hue) < 0.01, "same hue")
            const dark = root.shadeOfHex("#102a60")
            const lighter = root.shadeOfHex(Tint.nudge("#102a60", 0.1))
            verify(Math.abs(lighter.lightness - (dark.lightness + 0.1)) < 0.01, "lighter " + lighter.lightness)
        }

        function test_anIconIsSampledThroughAnInvisibleCanvas() {
            tryVerify(() => root.sampled.length > 0, 3000, "the canvas sampled the icon")
            const shade = root.shadeOfHex(root.sampled)
            verify(shade.hue > 0.02 && shade.hue < 0.08, "orange hue " + shade.hue)
        }
    }
}
