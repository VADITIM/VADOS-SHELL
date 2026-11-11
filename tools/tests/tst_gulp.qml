import QtQuick
import QtTest
import qs.config
import qs.components

Item {
    id: scene

    property real deepest: 0
    property real highest: 0

    Gulp {
        id: gulp
        isLanded: true
        amplitude: 10
        span: 420
        onSwellChanged: {
            scene.highest = Math.max(scene.highest, swell)
            scene.deepest = Math.min(scene.deepest, swell)
        }
    }

    TestCase {
        name: "Gulp"
        when: windowShown

        function rest() {
            gulp.isLanded = true
            scene.highest = 0
            scene.deepest = 0
        }

        function test_restsWithoutSwellUntilLanded() {
            rest()
            compare(gulp.swell, 0, "nothing plays at start")
            gulp.isLanded = false
            compare(gulp.swell, 0)
            verify(!gulp.ring.running)
        }

        function test_landingSwellsAndSettles() {
            rest()
            gulp.isLanded = false
            gulp.isLanded = true
            verify(gulp.ring.running)
            compare(gulp.playing, "gulp")
            tryVerify(() => !gulp.ring.running, 2000)
            verify(scene.highest > 0, "the body bulges as it lands")
            verify(scene.deepest < 0, "and springs back past its rest")
            verify(scene.highest <= gulp.amplitude, "never more than its amplitude")
            compare(gulp.swell, 0, "it settles at rest")
            compare(gulp.playing, "")
        }

        function test_takingOffStopsTheRing() {
            rest()
            gulp.isLanded = false
            gulp.isLanded = true
            gulp.isLanded = false
            verify(!gulp.ring.running)
            compare(gulp.swell, 0)
        }
    }
}
