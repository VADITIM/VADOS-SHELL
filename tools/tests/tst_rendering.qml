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
            liquid.isShown = true
            liquid.opacity = 1
            masked.visible = true
        }

        function verifyBlurRuns(isRunning) {
            compare(part("blurPass").visible, isRunning, "blur pass drawn")
            compare(part("blurPass").blurEnabled, isRunning, "blur enabled")
            compare(part("blurredTexture").live, isRunning, "blurred texture updated")
            compare(part("rimSurface").layer.enabled, isRunning, "rim surface layered")
            compare(part("rimPass").visible, isRunning, "rim pass drawn")
            compare(part("fillPass").visible, isRunning, "blurred fill pass drawn")
        }

        function verifyNothingRuns() {
            verify(!liquid.visible)
            verify(!liquid.isRendering)
            verifyBlurRuns(false)
            verify(!part("shapeTexture").live)
            verify(!part("fillSurface").layer.enabled)
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
