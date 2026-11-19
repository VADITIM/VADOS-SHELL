import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    width: 400
    height: 300

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: true
        fillAlpha: 0.8

        LiquidShape {
            parent: liquid.shapes
            x: 40
            y: 40
            width: 80
            height: 80
        }
    }

    LiquidLayer {
        id: frosted
        width: 200
        height: 150
        isShown: true
        fillAlpha: 0.6
        frostSource: Qt.resolvedUrl("../icons/source/image.svg")
        frostSize: Qt.size(400, 300)

        LiquidShape {
            parent: frosted.shapes
            x: 20
            y: 20
            width: 80
            height: 80
        }
    }

    Masked {
        id: masked
        anchors.fill: parent
        mask: Rectangle {
            anchors.fill: parent
            radius: width / 2
        }

        Rectangle {
            anchors.fill: parent
        }
    }

    Backdrop {
        id: backdrop
        width: 200
        height: 150
        isShown: true
        source: Qt.resolvedUrl("../icons/source/image.svg")
        blur: 32
        detail: 0.5
    }

    Backdrop {
        id: unsized
        isShown: false
        source: Qt.resolvedUrl("../icons/source/image.svg")
    }

    TestCase {
        name: "Rendering"
        when: windowShown

        function part(name) {
            const found = findChild(liquid, name)
            verify(found !== null, name)
            return found
        }

        function cleanup() {
            Config.setRenderQuality("full")
            Config.setPillBlur(1)
            liquid.isShown = true
            liquid.opacity = 1
            frosted.isShown = true
            masked.visible = true
        }

        function verifyBlurRuns(isRunning) {
            compare(part("blurPass").visible, isRunning, "blur pass drawn")
            compare(part("blurPass").blurEnabled, isRunning, "blur enabled")
            compare(part("blurredTexture").live, isRunning, "blurred texture updated")
            compare(part("rimTexture").live, isRunning, "rim colour updated")
            compare(part("rimPass").visible, isRunning, "rim pass drawn")
            compare(part("fillPass").visible, isRunning, "blurred fill pass drawn")
        }

        function verifyNothingRuns() {
            verify(!liquid.visible)
            verify(!liquid.isRendering)
            verifyBlurRuns(false)
            verify(!part("shapeTexture").live)
            verify(!part("fillTexture").live)
            verify(!part("passes").layer.enabled)
            verify(!part("corePass").visible)
        }

        function test_fullQualityBlurs() {
            verify(liquid.isBlurring)
            compare(liquid.blurRadius, liquid.melt)
            verifyBlurRuns(true)
            verify(part("corePass").visible)
            verify(part("passes").layer.enabled, "translucent passes are flattened before their opacity")
        }

        function test_liteKeepsShapesAndThresholdWithoutBlur() {
            Config.setRenderQuality("lite")
            verify(Rendering.isLite)
            compare(Rendering.blur(liquid.melt), 0)
            compare(liquid.blurRadius, 0)
            verify(liquid.isRendering)
            verify(!liquid.isBlurring)
            verifyBlurRuns(false)
            verify(part("shapeTexture").live, "shapes still reach the threshold")
            verify(part("corePass").visible, "the threshold still draws the body")
            verify(!part("passes").layer.enabled, "one pass needs no flattening")
            Config.setRenderQuality("full")
            verifyBlurRuns(true)
        }

        function verifyColourSurfacesUnlayered() {
            verify(!part("rimSurface").layer.enabled, "a layer switched off never draws again when switched back on")
            verify(!part("fillSurface").layer.enabled)
        }

        function test_colourSurfacesNeverLayer() {
            verifyColourSurfacesUnlayered()
            liquid.opacity = 0
            verifyColourSurfacesUnlayered()
            liquid.opacity = 1
            liquid.isShown = false
            verifyColourSurfacesUnlayered()
            liquid.isShown = true
            verifyColourSurfacesUnlayered()
            verify(part("fillTexture").live, "the fill updates again once shown")
            verify(part("rimTexture").live)
        }

        function test_hiddenLayerRunsNoEffect() {
            liquid.isShown = false
            verifyNothingRuns()
            liquid.isShown = true
            verify(liquid.isBlurring)
        }

        function test_transparentLayerRunsNoEffect() {
            liquid.opacity = 0
            verifyNothingRuns()
        }

        function backdropPart(name) {
            const found = findChild(backdrop, name)
            verify(found !== null, name)
            return found
        }

        function verifyBackdropBlurs(isRunning) {
            compare(backdrop.isBlurring, isRunning)
            compare(backdropPart("pictureTexture").live, isRunning, "picture texture updated")
            compare(backdropPart("pictureTexture").hideSource, isRunning, "the sharp picture hides under its blur")
            compare(backdropPart("blurPass").visible, isRunning, "blur pass drawn")
        }

        function test_backdropBlursOnlyWhileShownWithItsPicture() {
            tryVerify(() => backdrop.hasPicture, 3000)
            compare(backdrop.blurRadius, 32)
            verifyBackdropBlurs(true)
            compare(backdrop.bleed, 32, "the picture reaches past the edges so the blur never darkens them")
            backdrop.isShown = false
            verify(!backdrop.visible)
            verifyBackdropBlurs(false)
            backdrop.isShown = true
            backdrop.opacity = 0
            verifyBackdropBlurs(false)
            backdrop.opacity = 1
            verifyBackdropBlurs(true)
        }

        function test_backdropPreloadsHiddenButNeverAtNoSize() {
            const picture = findChild(unsized, "picture")
            compare(String(picture.source), "", "no decode before the backdrop has a size")
            unsized.width = 120
            unsized.height = 80
            verify(String(picture.source).length > 0)
            tryVerify(() => unsized.hasPicture, 3000)
            verify(!unsized.visible, "decoded ahead while hidden")
        }

        function test_liteBackdropDrawsThePictureWithoutBlur() {
            tryVerify(() => backdrop.hasPicture, 3000)
            Config.setRenderQuality("lite")
            compare(backdrop.blurRadius, 0)
            verifyBackdropBlurs(false)
            verify(backdropPart("picture").visible, "the picture still covers the screen")
            compare(backdrop.bleed, 0)
            Config.setRenderQuality("full")
            verifyBackdropBlurs(true)
        }

        function frostPart(name) {
            const found = findChild(frosted, name)
            verify(found !== null, name)
            return found
        }

        function verifyFrostRuns(isRunning) {
            compare(frosted.isFrosting, isRunning)
            compare(frostPart("frostTexture").live, isRunning, "wallpaper texture updated")
            compare(frostPart("frostBlurred").live, isRunning, "frosted texture updated")
            compare(frostPart("frostBlurPass").blurEnabled, isRunning, "frost blur enabled")
            compare(frostPart("frostPass").visible, isRunning, "frost drawn inside the body")
        }

        function test_pillBlurFrostsTheWholeBodyAndLeavesTheEdgesAlone() {
            tryVerify(() => frosted.isFrosting, 3000)
            compare(frosted.frostRadius, Appearance.liquid.frost)
            verifyFrostRuns(true)
            compare(frostPart("frostPass").maskSource, frostPart("blurredTexture"), "the frost fills the body up to its edge")
            Config.setPillBlur(0.5)
            compare(frosted.frostRadius, Math.round(Appearance.liquid.frost * 0.5))
            compare(liquid.blurRadius, liquid.melt, "the pill blur never changes the melt of the edges")
            compare(frosted.blurRadius, frosted.melt)
            Config.setPillBlur(0)
            verifyFrostRuns(false)
            compare(frostPart("frostPicture").source.toString(), "", "no wallpaper is held while the frost is off")
            Config.setPillBlur(1)
            tryVerify(() => frosted.isFrosting, 3000)
            frosted.isShown = false
            verifyFrostRuns(false)
            frosted.isShown = true
            tryVerify(() => frosted.isFrosting, 3000)
            Config.setRenderQuality("lite")
            verifyFrostRuns(false)
        }

        function test_maskedLayersFollowVisibility() {
            verify(masked.isRendering)
            compare(findChild(masked, "maskShape").children[0].width, masked.width, "the mask fills the masked area")
            verify(findChild(masked, "maskShape").layer.enabled)
            verify(findChild(masked, "maskedContent").layer.enabled)
            masked.visible = false
            verify(!findChild(masked, "maskShape").layer.enabled)
            verify(!findChild(masked, "maskedContent").layer.enabled)
        }
    }
}
