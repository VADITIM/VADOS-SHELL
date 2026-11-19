import QtQuick
import qs.config
import "../utils/Liquid.js" as Liquid
import "../utils/SliceText.js" as Slice
import "../utils/Geometry.js" as Geometry
import "../utils/Playing.js" as Playing

Item {
    id: slice

    required property var look
    required property var pace
    required property var character
    property string label: "slice text"
    property string text: ""
    property bool isShown: false
    property color color: Appearance.color.text
    property string fontFamily: Appearance.font.mono
    property int pixelSize: Appearance.font.body
    property real lineHeight: 1
    property real enterTime: 0
    property real leaveTime: 0
    property bool isGone: true
    property Item field: null
    property rect reach: Qt.rect(0, 0, 0, 0)
    property real enterRound: 0
    property real leaveRound: 0
    readonly property var glyphs: Slice.glyphsOf(text, look.jitter)
    readonly property real advance: metrics.advanceWidth("M")
    readonly property real lineStep: metrics.height * lineHeight
    readonly property real enterTotal: Slice.enterTotal(pace, look.jitter)
    readonly property real leaveTotal: pace.leaveSweep + pace.leave
    readonly property bool isSettled: isShown && !arrival.running && enterTime >= enterTotal
    readonly property string playing: arrival.running || departure.running || sweeping.running ? label : ""
    readonly property real pushReach: look.pushReach || 0
    readonly property bool isPushed: pointer.hovered && pushReach > 0 && !isGone
    property real pushStrength: isPushed ? 1 : 0
    property real pushAtX: 0
    property real pushAtY: 0
    readonly property bool isPushing: pushStrength > 0.001
    readonly property var unpushed: ({ x: 0, y: 0 })
    property bool hasSweep: false
    readonly property bool shouldSweep: hasSweep && isSettled && !Motion.isReduced
    property real sweepTime: 0
    property int sweepRest: 0
    readonly property real sweepTotal: hasSweep ? Slice.sweepTotal(text, pace.sweepStagger, pace.sweepSpin, pace.sweepStretch) : 0
    readonly property var sweepTiming: ({ stagger: 0, spin: pace.sweepSpin, stretch: pace.sweepStretch, settle: Motion.type.scrambleSettle, turns: Motion.type.scrambleTurns, cycles: Motion.type.scrambleCycles })

    Behavior on pushStrength {
        NumberAnimation {
            duration: Motion.pace(slice.pace.push)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on pushAtX {
        enabled: slice.isPushing

        NumberAnimation {
            duration: Motion.pace(slice.pace.push)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on pushAtY {
        enabled: slice.isPushing

        NumberAnimation {
            duration: Motion.pace(slice.pace.push)
            easing.type: Easing.OutCubic
        }
    }

    Binding {
        target: slice
        property: "pushAtX"
        value: pointer.point.position.x - slice.pushReach
        when: pointer.hovered
        restoreMode: Binding.RestoreNone
    }

    Binding {
        target: slice
        property: "pushAtY"
        value: pointer.point.position.y - slice.pushReach
        when: pointer.hovered
        restoreMode: Binding.RestoreNone
    }

    implicitWidth: Slice.columnsOf(text) * advance
    implicitHeight: Slice.rowsOf(text) * lineStep

    property bool isTracing: false

    function placeGlyph(item) {
        const glyph = item.modelData
        const arrived = isSettled ? 1 : Liquid.rise(character, Slice.enterClock(glyph, enterTime, pace))
        const away = isShown ? 0 : Slice.pullOf(glyph, leaveTime, pace)
        const homeX = glyph.column * advance
        const homeY = glyph.row * lineStep
        const push = isPushing ? Slice.pushOf(homeX + advance / 2, homeY + lineStep / 2, pushAtX, pushAtY, pushReach, look.pushDepth * pushStrength) : unpushed
        const rest = push !== unpushed || away !== 0 ? "" : arrived === 1 ? "home" : arrived === 0 ? "waiting" : ""
        if (rest.length > 0 && item.rest === rest)
            return
        const origin = arrived === 1 ? null : item.origin
        const target = away === 0 ? null : item.target
        const settledX = origin ? Geometry.mix(origin.x, homeX, arrived) : homeX
        const settledY = origin ? Geometry.mix(origin.y, homeY, arrived) : homeY
        item.x = (target ? Geometry.mix(settledX, target.x, away) : settledX) + push.x
        item.y = (target ? Geometry.mix(settledY, target.y, away) : settledY) + push.y
        item.rotation = glyph.spin * look.spin * ((1 - arrived) - away)
        item.opacity = Geometry.clampUnit(arrived * look.fade) * (1 - away)
        item.rest = rest
    }

    function aim(item) {
        item.origin = Slice.pointIn(reach, item.modelData, enterRound, advance, lineStep)
        item.target = Slice.pointIn(reach, item.modelData, leaveRound, advance, lineStep)
        item.rest = ""
    }

    function placeGlyphs() {
        isTracing = false
        for (let index = 0; index < glyphRepeater.count; index++) {
            const item = glyphRepeater.itemAt(index)
            if (item)
                placeGlyph(item)
        }
    }

    function unplace() {
        for (let index = 0; index < glyphRepeater.count; index++) {
            const item = glyphRepeater.itemAt(index)
            if (item)
                aim(item)
        }
        trace()
    }

    function trace() {
        if (isTracing)
            return
        isTracing = true
        Qt.callLater(placeGlyphs)
    }

    onEnterTimeChanged: trace()
    onLeaveTimeChanged: trace()
    onPushStrengthChanged: trace()
    onPushAtXChanged: trace()
    onPushAtYChanged: trace()
    onIsSettledChanged: trace()
    onSweepTimeChanged: sweepGlyphs()
    onShouldSweepChanged: {
        if (shouldSweep) {
            rollRest()
            return
        }
        sweeping.stop()
        sweepTime = 0
        sweepGlyphs()
    }
    onReachChanged: unplace()
    onAdvanceChanged: unplace()
    onLineStepChanged: unplace()
    onEnterRoundChanged: unplace()
    onLeaveRoundChanged: unplace()

    function rollRest() {
        sweepRest = Math.round(pace.sweepRestShortest + Math.random() * (pace.sweepRestLongest - pace.sweepRestShortest))
    }

    function sweepGlyphs() {
        for (let index = 0; index < glyphRepeater.count; index++) {
            const item = glyphRepeater.itemAt(index)
            if (!item)
                continue
            const swept = Slice.sweepOf(item.modelData, sweepTime, pace.sweepStagger, sweepTiming, Appearance.font.scrambleSymbols)
            if (item.text !== swept.glyph)
                item.text = swept.glyph
            item.spin = swept.rotation
        }
    }

    function measure() {
        reach = field ? mapFromItem(field, 0, 0, field.width, field.height) : Qt.rect(0, 0, width, height)
    }

    function play() {
        measure()
        if (isShown) {
            departure.stop()
            leaveTime = 0
            enterTime = 0
            enterRound = Math.random()
            isGone = false
            arrival.restart()
            return
        }
        arrival.stop()
        if (isGone)
            return
        leaveTime = 0
        leaveRound = Math.random()
        departure.restart()
    }

    onIsShownChanged: {
        play()
        unplace()
    }
    Component.onCompleted: {
        Playing.enlist(slice)
        if (isShown)
            play()
    }
    Component.onDestruction: {
        arrival.stop()
        departure.stop()
        sweeping.stop()
        Playing.delist(slice)
    }

    FontMetrics {
        id: metrics
        font.family: slice.fontFamily
        font.pixelSize: slice.pixelSize
    }

    NumberAnimation {
        id: arrival
        paused: Motion.isHeld && running
        target: slice
        property: "enterTime"
        from: 0
        to: slice.enterTotal
        duration: Motion.pace(slice.enterTotal)
    }

    SequentialAnimation {
        id: departure
        paused: Motion.isHeld && running

        NumberAnimation {
            target: slice
            property: "leaveTime"
            from: 0
            to: slice.leaveTotal
            duration: Motion.pace(slice.leaveTotal)
        }

        ScriptAction {
            script: slice.isGone = true
        }
    }

    Timer {
        interval: Math.max(1, slice.sweepRest)
        running: slice.shouldSweep && slice.sweepRest > 0 && !sweeping.running && !Motion.isHeld
        onTriggered: sweeping.restart()
    }

    SequentialAnimation {
        id: sweeping
        paused: Motion.isHeld && running

        NumberAnimation {
            target: slice
            property: "sweepTime"
            from: 0
            to: slice.sweepTotal
            duration: Motion.pace(slice.sweepTotal)
        }

        ScriptAction {
            script: slice.rollRest()
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: -slice.pushReach

        HoverHandler {
            id: pointer
        }
    }

    Repeater {
        id: glyphRepeater
        model: slice.glyphs

        Text {
            required property var modelData
            property string rest: ""
            property var origin: Qt.point(0, 0)
            property var target: Qt.point(0, 0)
            property real spin: 0

            visible: !slice.isGone
            text: modelData.glyph
            textFormat: Text.PlainText
            color: slice.color
            font.family: slice.fontFamily
            font.pixelSize: slice.pixelSize
            font.preferShaping: false
            transform: Rotation {
                origin.x: width / 2
                origin.y: height / 2
                angle: spin
            }
            Component.onCompleted: {
                slice.aim(this)
                slice.trace()
            }
        }
    }
}
