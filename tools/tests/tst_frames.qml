import QtQuick
import QtTest
import qs.config
import qs.state
import qs.components
import qs.modules.framedebug

Item {
    id: root

    property real travel: 0

    Lifecycle {
        id: first
    }

    Lifecycle {
        id: second
    }

    NumberAnimation {
        id: probe
        target: root
        property: "travel"
        from: 0
        to: 1000
        duration: 1000
        paused: Motion.isHeld && running
    }

    Rectangle {
        id: swatch
        width: 40
        height: 20
        color: "red"
    }

    Component {
        id: keeperComponent

        Image {
            visible: false
            cache: true
        }
    }

    FrameStage {
        id: replayStage
        width: swatch.width
        height: swatch.height
        shots: FrameDebug.shotsOn("A")
    }

    Connections {
        target: FrameDebug

        function onCaptureRequested(token, scale) {
            FrameDebug.expect()
            swatch.grabToImage(result => FrameDebug.store(token, {
                keeper: keeperComponent.createObject(root, { source: result.url }),
                url: result.url,
                screenName: "A",
                side: "left",
                order: 0,
                width: swatch.width,
                height: swatch.height,
                bytes: swatch.width * swatch.height * Motion.frames.bytesPerPixel
            }), Qt.size(Math.round(swatch.width * scale), Math.round(swatch.height * scale)))
        }
    }

    SignalSpy {
        id: snapshotSpy
        target: FrameDebug
        signalName: "snapshotReady"
    }

    FrameHud {
        id: hud
        width: 400
        height: 300
        isActive: FrameDebug.isActive
        counter: FrameDebug.counter
        label: FrameDebug.shownLabel
        property int steps: 0
        property int backs: 0
        property int shots: 0
        property int closes: 0
        onStepRequested: steps++
        onBackRequested: backs++
        onShotRequested: shots++
        onCloseRequested: closes++
    }

    TestCase {
        name: "Frames"
        when: windowShown

        function prepare() {
            FrameDebug.close()
            silence()
            probe.stop()
            root.travel = 0
        }

        function cleanup() {
            FrameDebug.memory = Motion.frames.memory
            FrameDebug.close()
            silence()
            probe.stop()
        }

        function silence() {
            first.phase = "idle"
            second.phase = "idle"
        }

        function play(name, phase) {
            first.name = name
            first.phase = phase
        }

        function test_holdFreezesAnimationsAlreadyRunning() {
            prepare()
            probe.restart()
            wait(100)
            verify(root.travel > 0)
            FrameDebug.begin("A")
            const frozen = root.travel
            wait(150)
            compare(root.travel, frozen)
        }

        function test_holdFreezesAnimationsStartedWhileHeld() {
            prepare()
            FrameDebug.begin("A")
            probe.restart()
            FrameDebug.refresh()
            wait(150)
            compare(root.travel, 0)
        }

        function test_stepAdvancesAboutOneFrameAndHoldsAgain() {
            prepare()
            FrameDebug.begin("A")
            probe.restart()
            FrameDebug.refresh()
            FrameDebug.step()
            verify(FrameDebug.isStepping)
            tryVerify(() => !FrameDebug.isStepping, 1000)
            const afterStep = root.travel
            verify(afterStep > 0, "the step moved the animation")
            verify(afterStep < 60, "the step moved it by about one frame, not " + afterStep + " ms")
            wait(150)
            compare(root.travel, afterStep)
            verify(Motion.isHeld)
        }

        function test_closeLetsAnimationsRun() {
            prepare()
            FrameDebug.begin("A")
            probe.restart()
            FrameDebug.refresh()
            wait(100)
            compare(root.travel, 0)
            FrameDebug.close()
            verify(!Motion.isHeld)
            wait(150)
            verify(root.travel > 0)
        }

        function test_stepDoesNothingUnlessHeld() {
            prepare()
            FrameDebug.step()
            verify(!FrameDebug.isStepping)
            verify(!Motion.isHeld)
        }

        function test_namesAndFramesFollowTheAnimation() {
            prepare()
            play("search burst", "entering")
            FrameDebug.begin("A")
            compare(FrameDebug.label, "search burst entering")
            compare(FrameDebug.counter, "FRAME 0")
            FrameDebug.step()
            tryVerify(() => !FrameDebug.isStepping, 1000)
            compare(FrameDebug.counter, "FRAME 1")
            FrameDebug.step()
            tryVerify(() => !FrameDebug.isStepping, 1000)
            compare(FrameDebug.counter, "FRAME 2")
            silence()
            FrameDebug.refresh()
            compare(FrameDebug.label, "")
            compare(FrameDebug.counter, "HELD")
        }

        function test_duplicateNamesAreCounted() {
            prepare()
            play("pill", "entering")
            second.name = "pill"
            second.phase = "entering"
            FrameDebug.begin("A")
            compare(FrameDebug.label, "pill entering x2")
        }

        function test_newAnimationStartsAtFrameZero() {
            prepare()
            FrameDebug.begin("A")
            compare(FrameDebug.counter, "HELD")
            play("dashboard burst", "preparing")
            FrameDebug.refresh()
            compare(FrameDebug.counter, "FRAME 0")
        }

        function test_watchdogWaitsWhileHeld() {
            prepare()
            FrameDebug.begin("A")
            first.send("show")
            verify(!first.watchdog.running)
            FrameDebug.close()
            verify(first.watchdog.running)
        }

        function stepOnce() {
            FrameDebug.step()
            tryVerify(() => !FrameDebug.isStepping, 1000)
        }

        function test_stepsAreRecordedAndGoBackwards() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            stepOnce()
            stepOnce()
            stepOnce()
            compare(FrameDebug.history.length, 4)
            compare(FrameDebug.counter, "FRAME 3")
            verify(!FrameDebug.isViewingPast)
            FrameDebug.back()
            compare(FrameDebug.counter, "FRAME 2 REPLAY")
            compare(FrameDebug.shownLabel, "burst entering")
            FrameDebug.back()
            FrameDebug.back()
            compare(FrameDebug.counter, "FRAME 0 REPLAY")
            FrameDebug.back()
            compare(FrameDebug.counter, "FRAME 0 REPLAY")
            FrameDebug.step()
            compare(FrameDebug.counter, "FRAME 1 REPLAY")
            FrameDebug.step()
            FrameDebug.step()
            compare(FrameDebug.counter, "FRAME 3")
            verify(!FrameDebug.isViewingPast)
        }

        function test_goingBackAndForwardInTheRecordingDoesNotRunTheAnimation() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            probe.restart()
            FrameDebug.refresh()
            stepOnce()
            stepOnce()
            const travelled = root.travel
            FrameDebug.back()
            FrameDebug.step()
            FrameDebug.back()
            wait(100)
            compare(root.travel, travelled)
            verify(!FrameDebug.isStepping)
        }

        function test_recordedFramesKeepTheirPictures() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            stepOnce()
            tryVerify(() => FrameDebug.history[0].shots.length === 1 && FrameDebug.history[1].shots.length === 1, 2000)
            FrameDebug.back()
            compare(FrameDebug.shotsOn("A").length, 1)
            compare(FrameDebug.shotsOn("B").length, 0)
        }

        function test_oldPicturesStillShowAfterManyLaterOnes() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            for (let frame = 0; frame < 6; frame++)
                stepOnce()
            tryVerify(() => FrameDebug.pending === 0, 2000)
            gc()
            wait(100)
            gc()
            for (let frame = 0; frame < 6; frame++)
                FrameDebug.back()
            compare(FrameDebug.counter, "FRAME 0 REPLAY")
            wait(100)
            const image = grabImage(replayStage)
            compare(image.red(5, 5), 255)
            compare(image.green(5, 5), 0)
        }

        function test_historyIsCapped() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            for (let frame = 0; frame < Motion.frames.history + 30; frame++)
                FrameDebug.capture()
            compare(FrameDebug.history.length, Motion.frames.history)
            compare(FrameDebug.cursor, Motion.frames.history - 1)
        }

        function test_historyKeepsWithinItsMemory() {
            prepare()
            const frameBytes = swatch.width * swatch.height * Motion.frames.bytesPerPixel
            FrameDebug.memory = frameBytes * 3
            play("burst", "entering")
            FrameDebug.begin("A")
            for (let frame = 0; frame < 6; frame++)
                stepOnce()
            tryVerify(() => FrameDebug.pending === 0, 2000)
            compare(FrameDebug.history.length, 3)
            compare(FrameDebug.cursor, 2)
            compare(FrameDebug.counter, "FRAME 6")
            FrameDebug.back()
            compare(FrameDebug.counter, "FRAME 5 REPLAY")
        }

        function test_recordedFramesAreFullResolution() {
            compare(Motion.frames.scale, 1)
        }

        function test_closeForgetsTheRecording() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            stepOnce()
            FrameDebug.close()
            compare(FrameDebug.history.length, 0)
            compare(FrameDebug.cursor, -1)
        }

        function test_screenshotRendersTheWindowIntoOnePicture() {
            prepare()
            snapshotSpy.clear()
            FrameDebug.snap("A")
            verify(FrameDebug.isSnapping)
            tryVerify(() => snapshotSpy.count === 1, 2000)
            const shots = snapshotSpy.signalArguments[0][0]
            compare(shots.length, 1)
            compare(shots[0].width, swatch.width)
            hud.snapshotShots = shots
            let address = ""
            verify(hud.capture(result => address = result.url.toString()))
            tryVerify(() => address.length > 0, 2000)
            FrameDebug.finishSnap()
            verify(!FrameDebug.isSnapping)
        }

        function test_screenshotOfAPastFrameUsesThatFrame() {
            prepare()
            play("burst", "entering")
            FrameDebug.begin("A")
            stepOnce()
            tryVerify(() => FrameDebug.pending === 0, 2000)
            FrameDebug.back()
            snapshotSpy.clear()
            FrameDebug.snap("A")
            tryVerify(() => snapshotSpy.count === 1, 2000)
            compare(snapshotSpy.signalArguments[0][0].length, 1)
            compare(snapshotSpy.signalArguments[0][0][0].width, swatch.width)
            FrameDebug.finishSnap()
        }

        function test_hudAsksForStepsAndLeaving() {
            prepare()
            hud.forceActiveFocus()
            hud.steps = 0
            hud.backs = 0
            hud.shots = 0
            hud.closes = 0
            keyClick(Qt.Key_Up)
            keyClick(Qt.Key_Right)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Left)
            keyClick(Qt.Key_Plus)
            keyClick(Qt.Key_Escape)
            compare(hud.steps, 2)
            compare(hud.backs, 2)
            compare(hud.shots, 1)
            compare(hud.closes, 1)
        }
    }
}
