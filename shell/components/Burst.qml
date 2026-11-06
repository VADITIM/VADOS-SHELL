import QtQuick
import QtQuick.Shapes
import qs.config

Item {
    id: burst

    property bool isShown: false
    property var parts: []
    property real rootX: 0
    property real seedX: 0
    property real seedY: 0
    property real formWidth: 0
    property real formHeight: 0
    property real leftCorner: 0
    property real rightCorner: 0
    property real edgePad: 0
    property bool canHandOff: false
    property bool hasSteps: true
    property bool hasSideStep: false
    property var wall: []

    property real merge: 0
    property real leaveWallShare: 0
    property real leaveFlare: 0
    property real spread: 0
    property real exit: 0
    property real impact: 0
    property bool isLeaving: false
    property var leaveFrom: ({ x: 0, y: 0, width: 0, height: 0, left: 0, right: 0 })

    readonly property var look: Appearance.burst
    readonly property var pace: Motion.burst
    readonly property bool isActive: isShown || leave.running
    readonly property bool isOpened: isShown && !isLeaving && spread >= pace.openShare
    readonly property bool isSplashing: isShown && !isLeaving && spread > pace.impactShare

    readonly property real halfHeight: formHeight / 2
    readonly property real farX: rootX + formWidth
    readonly property real farDistance: farX - seedX
    readonly property real startReach: look.ball * (1 + pace.inflate) / 2
    readonly property real opening: clampUnit((spread - pace.impactShare) / (1 - pace.impactShare))
    readonly property real widthShare: bounce(opening)
    readonly property real heightShare: bounce(opening * pace.heightLead)
    readonly property real front: startReach + (farDistance - startReach) * widthShare
    readonly property real crossShare: 1 / (4 * pace.bounceCycles * pace.heightLead)
    readonly property real meetShare: pace.impactShare + (crossShare + pace.crestRun * (1 - crossShare)) * (1 - pace.impactShare)

    readonly property var flights: (parts || []).map(part => flightOf(part))
    readonly property real nearest: flights.reduce((shortest, flight) => Math.min(shortest, flight.distance), Infinity)
    readonly property real farthest: flights.reduce((longest, flight) => Math.max(longest, flight.distance), 0)
    readonly property real totalArea: flights.reduce((sum, flight) => sum + flight.area, 0)
    readonly property real arrived: totalArea > 0
        ? flights.reduce((sum, flight) => sum + flight.area * absorbedShare(flight), 0) / totalArea
        : merge * merge * (3 - 2 * merge)

    readonly property var closed: ({ x: seedX, y: seedY, width: 0, height: 0, left: 0, right: 0 })
    readonly property var form: !isActive ? closed : isLeaving ? leaveForm(exit, leaveFrom) : enterForm(spread)
    readonly property real formRight: form.x + form.width / 2
    readonly property bool isHandedOff: canHandOff && isLeaving && exit >= pace.leaveShrink
    readonly property bool isStepped: hasSteps && (isSplashing || isLeaving) && !isHandedOff
    readonly property var topStep: stepForm("top")
    readonly property var bottomStep: stepForm("bottom")
    readonly property var sideStep: stepForm("side")
    readonly property real aboveRise: isStepped ? topStep.rise : 0
    readonly property real belowRise: isStepped ? bottomStep.rise : 0
    readonly property real formTop: form.y - form.height / 2
    readonly property real rootTip: Math.min(rootX + look.rootSpan, form.x)
    readonly property real rootInner: (form.height + aboveRise + belowRise) / 2
    readonly property real rootOuter: rootInner + Math.min(look.rootSwell, form.height * look.swellShare)
    readonly property real wallShare: wall.length === 0 || !isActive ? 0
        : isLeaving ? leaveWallShare * clampUnit((form.width - look.leaveBall) / Math.max(1, leaveFrom.width - look.leaveBall))
        : spread < pace.impactShare ? 0
        : Math.max(0, (form.width - 2 * startReach) / Math.max(1, farX - rootX - 2 * startReach))
    readonly property bool hasWall: wallShare > 0 && !isHandedOff && form.height > 0.5
    readonly property real flare: !isActive ? 0
        : isLeaving ? leaveFlare * (1 - smooth(clampUnit(exit / pace.flareRetract)))
        : smooth(clampUnit((opening - pace.flareStart) / (1 - pace.flareStart)))
    readonly property var wallPoints: wall.map((point, index) => Qt.point(formRight + flaredX(index) * wallShare, formTop + point.y * form.height))
    readonly property var wallOutline: hasWall ? traceSpline(wallPoints) : []
    readonly property bool hasTracks: isSplashing || hasWall
    property var topTrack: null
    property var bottomTrack: null
    property var bodyOutline: []
    property var crests: [[], []]
    readonly property real farFront: hasWall ? wallXAt(form.y) : formRight
    readonly property var visitor:isActive && isLeaving ? ({ x: form.x, y: form.y, width: form.width, height: form.height, isHandedOff: isHandedOff }) : null

    signal landed()

    function clampUnit(value) {
        return Math.max(0, Math.min(1, value))
    }

    function smooth(value) {
        return value * value * (3 - 2 * value)
    }

    function bounce(time) {
        return 1 - Math.exp(-pace.bounceDamping * time) * Math.cos(2 * Math.PI * pace.bounceCycles * time)
    }

    function sinceCross(lead) {
        const cross = 1 / (4 * pace.bounceCycles * lead)
        return opening < cross ? -1 : (opening - cross) / (1 - cross)
    }

    function splineAt(before, from, to, after, time) {
        const square = time * time
        return 0.5 * (2 * from + (to - before) * time + (2 * before - 5 * from + 4 * to - after) * square + (3 * from - before - 3 * to + after) * square * time)
    }

    function traceSpline(points) {
        const outline = [points[0]]
        for (let index = 0; index < points.length - 1; index++) {
            const before = points[Math.max(0, index - 1)]
            const from = points[index]
            const to = points[index + 1]
            const after = points[Math.min(points.length - 1, index + 2)]
            for (let sample = 1; sample <= look.curveSamples; sample++) {
                const time = sample / look.curveSamples
                outline.push(Qt.point(splineAt(before.x, from.x, to.x, after.x, time), splineAt(before.y, from.y, to.y, after.y, time)))
            }
        }
        return outline
    }

    function flaredX(index) {
        const isEnd = index === 0 || index === wall.length - 1
        if (!isEnd || wall.length < 2)
            return wall[index].x
        const neighbour = wall[index === 0 ? 1 : wall.length - 2]
        return neighbour.x + (wall[index].x - neighbour.x) * (2 * flare - 1)
    }

    function wallXAt(y) {
        for (let index = 0; index < wallOutline.length - 1; index++) {
            const from = wallOutline[index]
            const to = wallOutline[index + 1]
            if ((from.y - y) * (to.y - y) <= 0)
                return from.x + (to.x - from.x) * (y - from.y) / Math.max(0.001, to.y - from.y)
        }
        return formRight
    }

    function enterForm(share) {
        if (share <= 0) {
            const size = look.ball * Math.sqrt(arrived)
            return { x: seedX, y: seedY, width: size, height: size, left: size / 2, right: size / 2 }
        }
        if (share < pace.impactShare) {
            const charge = share / pace.impactShare
            const size = look.ball * (1 + pace.inflate * charge)
            const squash = pace.squash * Math.sin(Math.PI * charge)
            const narrow = size * (1 - squash) / 2
            return { x: seedX, y: seedY, width: size * (1 + squash), height: size * (1 - squash), left: narrow, right: narrow }
        }
        const grip = smooth(clampUnit(opening / pace.rootShare))
        const wobble = look.impactPush * impactWobble()
        const left = seedX - startReach + (rootX - seedX + startReach) * grip
        const right = seedX + front + wobble
        const drag = 1 - pace.drag * Math.max(0, widthShare - 1)
        const height = (2 * startReach + (formHeight - 2 * startReach) * heightShare) * drag - wobble * pace.impactSquash
        const width = right - left
        const limit = Math.min(width, height) / 2
        return {
            x: (left + right) / 2,
            y: seedY,
            width: width,
            height: height,
            left: Math.min(limit, limit + (leftCorner - limit) * grip),
            right: Math.min(limit, limit + (rightCorner - limit) * clampUnit(widthShare))
        }
    }

    function leaveForm(exit, from) {
        const size = look.leaveBall
        const collapse = 1 - Math.pow(1 - clampUnit(exit / pace.leaveShrink), 3)
        const width = from.width + (size - from.width) * collapse
        const height = from.height + (size - from.height) * collapse
        const limit = Math.min(width, height) / 2
        const fromLeft = from.x - from.width / 2
        const left = fromLeft + (seedX - size / 2 - fromLeft) * collapse
        const slide = exit * exit * (seedX + size / 2 + edgePad)
        return {
            x: left + width / 2 - slide,
            y: from.y + (seedY - from.y) * collapse,
            width: width,
            height: height,
            left: Math.min(limit, from.left + (size / 2 - from.left) * collapse),
            right: Math.min(limit, from.right + (size / 2 - from.right) * collapse)
        }
    }

    function flightOf(part) {
        const fromX = part.x + part.width / 2
        const fromY = part.y + part.height / 2
        const isUpright = part.height >= part.width
        const along = isUpright ? Math.abs(seedY - fromY) : Math.abs(seedX - fromX)
        const lengthwise = Math.max(1, isUpright ? part.height : part.width)
        return {
            x: fromX,
            y: fromY,
            width: part.width,
            height: part.height,
            area: part.width * part.height,
            isUpright: isUpright,
            lean: clampUnit(along / lengthwise),
            distance: Math.hypot(seedX - fromX, seedY - fromY),
            heading: Math.atan2(seedY - fromY, seedX - fromX) * 180 / Math.PI
        }
    }

    function startAngleOf(flight) {
        if (flight.isUpright)
            return flight.heading >= 0 ? 90 : -90
        if (Math.abs(flight.heading) <= 90)
            return 0
        return flight.heading > 0 ? 180 : -180
    }

    function progressOf(flight) {
        const order = farthest > nearest ? (flight.distance - nearest) / (farthest - nearest) : 0
        return clampUnit((merge - pace.convergeLag * order) / (1 - pace.convergeLag))
    }

    function absorbedShare(flight) {
        return clampUnit((progressOf(flight) - (1 - pace.absorbShare)) / pace.absorbShare)
    }

    function streamForm(flight) {
        const progress = progressOf(flight)
        const tilt = smooth(clampUnit(progress / pace.tiltShare)) * flight.lean
        const travel = progress * progress
        const remaining = 1 - absorbedShare(flight)
        const thin = flight.isUpright ? flight.width : flight.height
        const lengthwise = flight.isUpright ? flight.height : flight.width
        const start = startAngleOf(flight)
        return {
            x: flight.x + (seedX - flight.x) * travel,
            y: flight.y + (seedY - flight.y) * travel,
            width: (lengthwise + (thin * (1 + pace.streamStretch) - lengthwise) * tilt) * remaining,
            height: thin * (1 - pace.thin * tilt) * remaining,
            rotation: start + (flight.heading - start) * tilt * tilt
        }
    }

    function lineSegment(fromX, fromDepth, toX, toDepth) {
        const length = Math.hypot(toX - fromX, toDepth - fromDepth)
        const safe = Math.max(0.001, length)
        return { isArc: false, x: fromX, depth: fromDepth, toX: toX, toDepth: toDepth, length: length, normalX: (fromDepth - toDepth) / safe, normalDepth: (toX - fromX) / safe }
    }

    function arcSegment(centerX, centerDepth, radius) {
        return { isArc: true, x: centerX, depth: centerDepth, radius: radius, length: Math.PI / 2 * radius }
    }

    function depthOf(side, point) {
        return side * (point.y - form.y)
    }

    function rootSegments(side) {
        const segments = []
        let before = rootLobe.bendAt(0, side)
        for (let sample = 1; sample <= look.curveSamples; sample++) {
            const next = rootLobe.bendAt(sample / look.curveSamples, side)
            segments.push(lineSegment(before.x, depthOf(side, before), next.x, depthOf(side, next)))
            before = next
        }
        return segments
    }

    function wallSegments(side, alongX) {
        const ordered = side < 0 ? wallOutline : wallOutline.slice().reverse()
        const segments = [lineSegment(alongX, form.height / 2, Math.max(alongX, ordered[0].x), form.height / 2)]
        for (let index = 0; index < ordered.length - 1; index++) {
            const from = ordered[index]
            const to = ordered[index + 1]
            const fromDepth = depthOf(side, from)
            const toDepth = depthOf(side, to)
            if (toDepth <= 0) {
                const share = fromDepth / Math.max(0.001, fromDepth - toDepth)
                segments.push(lineSegment(from.x, fromDepth, from.x + (to.x - from.x) * share, 0))
                break
            }
            segments.push(lineSegment(from.x, fromDepth, to.x, toDepth))
        }
        return segments
    }

    function wallTrack(side) {
        const step = side < 0 ? topStep : bottomStep
        const rise = isStepped ? step.rise : 0
        const corner = Math.min(step.corner, rise)
        const edge = form.height / 2
        const radius = Math.max(0.001, form.right)
        const start = rootLobe.neck
        const stepRight = step.x + step.width
        const segments = rootSegments(side)
        let alongX = start
        if (rise > 0.5 && stepRight - corner > start && stepRight <= formRight - radius) {
            segments.push(lineSegment(start, edge + rise, stepRight - corner, edge + rise))
            segments.push(arcSegment(stepRight - corner, edge + rise - corner, corner))
            segments.push(lineSegment(stepRight, edge + rise - corner, stepRight, edge))
            alongX = stepRight
        }
        if (hasWall) {
            const whole = segments.concat(wallSegments(side, alongX))
            return { segments: whole, total: whole.reduce((sum, segment) => sum + segment.length, 0) }
        }
        segments.push(lineSegment(alongX, edge, Math.max(alongX, formRight - radius), edge))
        segments.push(arcSegment(formRight - radius, edge - radius, radius))
        const down = Math.max(0, edge - radius)
        const sideRise = hasSideStep && isStepped ? sideStep.rise : 0
        const near = side < 0 ? form.y - sideStep.y : sideStep.y + sideStep.height - form.y
        if (sideRise > 0.5 && near > 0 && near < down) {
            const sideCorner = Math.min(sideStep.corner, near)
            segments.push(lineSegment(formRight, down, formRight, near))
            segments.push(lineSegment(formRight, near, formRight + sideRise - sideCorner, near))
            segments.push(arcSegment(formRight + sideRise - sideCorner, near - sideCorner, sideCorner))
            segments.push(lineSegment(formRight + sideRise, near - sideCorner, formRight + sideRise, 0))
        } else {
            segments.push(lineSegment(formRight, down, formRight, 0))
        }
        return { segments: segments, total: segments.reduce((sum, segment) => sum + segment.length, 0) }
    }

    function segmentPoint(segment, side, remaining, offset) {
        if (segment.isArc) {
            const angle = Math.PI / 2 - remaining / Math.max(0.001, segment.radius)
            const reach = segment.radius + offset
            return Qt.point(segment.x + reach * Math.cos(angle), form.y + side * (segment.depth + reach * Math.sin(angle)))
        }
        const share = segment.length > 0 ? Math.min(1, remaining / segment.length) : 0
        return Qt.point(segment.x + (segment.toX - segment.x) * share + segment.normalX * offset,
                        form.y + side * (segment.depth + (segment.toDepth - segment.depth) * share + segment.normalDepth * offset))
    }

    function trace() {
        if (!hasTracks) {
            topTrack = null
            bottomTrack = null
            bodyOutline = []
            crests = [[], []]
            return
        }
        topTrack = wallTrack(-1)
        bottomTrack = wallTrack(1)
        bodyOutline = hasWall ? edgePoints(-1).concat(edgePoints(1).reverse()) : []
        crests = [crestPath(-1), crestPath(1)]
    }

    function queueTrace() {
        Qt.callLater(trace)
    }

    function trackOf(side) {
        return side < 0 ? topTrack : bottomTrack
    }

    function waveHead(total) {
        return total * smooth(clampUnit(sinceCross(pace.heightLead) / pace.crestRun))
    }

    function troughDepth(distance, head, scale) {
        const away = Math.abs(distance - head) - look.crestLength / 2
        if (scale <= 0 || away <= 0 || away >= look.troughLength)
            return 0
        return -look.trough * scale * Math.sin(Math.PI * away / look.troughLength)
    }

    function edgePoints(side) {
        const track = trackOf(side)
        if (!track)
            return []
        const scale = crestHeight() / look.crest
        const head = waveHead(track.total)
        const from = head - look.crestLength / 2 - look.troughLength
        const to = head + look.crestLength / 2 + look.troughLength
        const points = []
        let passed = 0
        for (const segment of track.segments) {
            const end = passed + segment.length
            points.push(segmentPoint(segment, side, 0, troughDepth(passed, head, scale)))
            if (scale > 0 && to > passed && from < end) {
                const first = Math.max(passed, from)
                const last = Math.min(end, to)
                const count = Math.max(1, Math.ceil((last - first) / look.troughStep))
                for (let sample = 0; sample <= count; sample++) {
                    const distance = first + (last - first) * sample / count
                    points.push(segmentPoint(segment, side, distance - passed, troughDepth(distance, head, scale)))
                }
            }
            passed = end
        }
        const closing = track.segments[track.segments.length - 1]
        points.push(segmentPoint(closing, side, closing.length, troughDepth(passed, head, scale)))
        return points
    }

    function crestPath(side) {
        const height = crestHeight()
        const track = trackOf(side)
        if (height < 0.5 || !track)
            return []
        const segments = track.segments
        const total = track.total
        const head = waveHead(total)
        const from = Math.max(0, head - look.crestLength / 2)
        const to = Math.min(total, head + look.crestLength / 2)
        const outer = []
        const inner = []
        let index = 0
        let passed = 0
        for (let sample = 0; sample <= look.crestSamples; sample++) {
            const distance = from + (to - from) * sample / look.crestSamples
            while (index < segments.length - 1 && distance > passed + segments[index].length) {
                passed += segments[index].length
                index++
            }
            const bump = Math.cos(Math.PI * (distance - head) / look.crestLength)
            outer.push(segmentPoint(segments[index], side, distance - passed, height * bump * bump))
            inner.unshift(segmentPoint(segments[index], side, distance - passed, -look.crestInset))
        }
        return outer.concat(inner, [outer[0]])
    }

    function crestHeight() {
        const since = sinceCross(pace.heightLead)
        if (since < 0)
            return 0
        const swell = impact < pace.moundPeak ? Math.sin(Math.PI / 2 * impact / pace.moundPeak) : 1
        const sink = smooth(clampUnit((impact - pace.moundPeak) / pace.moundSink))
        return look.crest * clampUnit(since / pace.crestRise) * (1 + pace.moundRise * swell) * (1 - sink)
    }

    function jetForm() {
        const flight = clampUnit(impact / pace.jetShare)
        const isFlying = impact > 0 && flight < 1
        return {
            x: farFront + look.jetReach * 4 * flight * (1 - flight),
            y: seedY,
            size: isFlying ? look.jet * (1 - flight * flight) : 0
        }
    }

    function impactWobble() {
        return impact <= 0 || impact >= 1 ? 0 : -Math.exp(-pace.impactDamping * impact) * Math.sin(2 * Math.PI * pace.impactCycles * impact)
    }

    function stepForm(kind) {
        const grow = clampUnit(form.height / Math.max(1, formHeight))
        if (kind === "side") {
            const rise = look.stepSide * grow * smooth(clampUnit((spread - meetShare) / (1 - meetShare)))
            const height = look.stepSideHeight * grow
            return {
                x: formRight - look.stepSideCorner,
                y: seedY + look.stepSideOffset * grow - height / 2,
                width: rise + look.stepSideCorner,
                height: height,
                rise: rise,
                corner: Math.min(look.stepSideCorner, rise)
            }
        }
        const isTop = kind === "top"
        const rise = (isTop ? look.stepTop : look.stepBottom) * grow
        const left = form.x - form.width / 2
        const width = form.width * (isTop ? look.stepTopShare : look.stepBottomShare)
        const edge = isTop ? form.y - form.height / 2 - rise : form.y + form.height / 2 - look.stepCorner
        return { x: left, y: edge, width: width, height: rise + look.stepCorner, rise: rise, corner: Math.min(look.stepCorner, rise) }
    }

    function cornerSplashForm(index) {
        const side = index === 0 ? -1 : 1
        const since = sinceCross(1)
        const arc = since < 0 ? 0 : Math.sin(Math.PI * clampUnit(since / pace.splashSpan))
        if (hasWall) {
            const corner = index === 0 ? wallOutline[0] : wallOutline[wallOutline.length - 1]
            const reach = look.cornerReach * arc * Math.SQRT1_2
            return { x: corner.x + reach, y: corner.y + side * reach, size: look.cornerSplash * arc }
        }
        const offset = rightCorner * (1 - Math.SQRT1_2) - look.cornerReach * arc * Math.SQRT1_2
        return { x: formRight - offset, y: seedY + side * (form.height / 2 - offset), size: look.cornerSplash * arc }
    }

    function sprayForm(index) {
        const angle = Math.PI * ((index + 0.5) / look.sprayCount - 0.5)
        const cosine = Math.cos(angle)
        const sine = Math.sin(angle)
        const edge = Math.min(farDistance / Math.max(0.001, cosine), halfHeight / Math.max(0.001, Math.abs(sine)))
        const distance = Math.min(front * pace.sprayLead, edge - look.spray / 2)
        const caught = clampUnit((front - edge * pace.catchShare) / (edge * (1 - pace.catchShare)))
        const fade = clampUnit((spread - pace.sprayFade) / (1 - pace.sprayFade))
        return { x: seedX + cosine * distance, y: seedY + sine * distance, size: look.spray * (1 - Math.max(caught, fade)) }
    }

    function start() {
        leave.stop()
        isLeaving = false
        merge = 0
        spread = 0
        impact = 0
        exit = 0
        enter.restart()
    }

    function finish() {
        enter.stop()
        leaveWallShare = wallShare
        leaveFlare = flare
        leaveFrom = form
        isLeaving = true
        exit = 0
        leave.restart()
    }

    onIsShownChanged: isShown ? start() : finish()
    onFormChanged: queueTrace()
    onImpactChanged: queueTrace()
    onWallOutlineChanged: queueTrace()
    onHasTracksChanged: queueTrace()
    Component.onCompleted: if (isShown) start()

    anchors.fill: parent

    Repeater {
        model: burst.flights

        LiquidShape {
            required property var modelData
            readonly property var stream: burst.streamForm(modelData)
            visible: burst.isShown && !burst.isLeaving && burst.spread <= 0 && stream.height > 0.5
            width: stream.width
            height: stream.height
            rotation: stream.rotation
            x: stream.x - width / 2
            y: stream.y - height / 2
        }
    }

    Lobe {
        id: rootLobe
        visible: burst.isActive && !burst.isHandedOff && burst.form.height > 0.5 && burst.form.x > 0
        side: 1
        edge: -burst.edgePad
        tip: burst.rootTip
        centerY: burst.form.y + (burst.belowRise - burst.aboveRise) / 2
        innerHalf: burst.rootInner
        outerHalf: burst.rootOuter
        capShare: burst.look.rootCap
    }

    Shape {
        anchors.fill: parent
        visible: burst.hasWall

        ShapePath {
            fillColor: "white"
            strokeColor: "transparent"
            strokeWidth: 0
            PathPolyline { path: burst.bodyOutline }
        }
    }

    Rectangle {
        visible: burst.isActive && (!burst.hasWall || burst.bodyOutline.length === 0) && !burst.isHandedOff && burst.form.width > 0.5 && burst.form.height > 0.5
        color: "white"
        antialiasing: true
        width: burst.form.width
        height: burst.form.height
        topLeftRadius: burst.form.left
        bottomLeftRadius: burst.form.left
        topRightRadius: burst.form.right
        bottomRightRadius: burst.form.right
        x: burst.form.x - width / 2
        y: burst.form.y - height / 2
    }

    Repeater {
        model: burst.hasSideStep ? ["top", "bottom", "side"] : ["top", "bottom"]

        Rectangle {
            required property string modelData
            readonly property var step: modelData === "top" ? burst.topStep : modelData === "bottom" ? burst.bottomStep : burst.sideStep
            visible: burst.isStepped && step.width > 0.5 && step.corner > 0.5
            color: "white"
            antialiasing: true
            x: step.x
            y: step.y
            width: step.width
            height: step.height
            topRightRadius: modelData === "bottom" ? 0 : step.corner
            bottomRightRadius: modelData === "top" ? 0 : step.corner
        }
    }

    Repeater {
        model: [-1, 1]

        Shape {
            required property int modelData
            anchors.fill: parent
            visible: burst.isSplashing

            ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                strokeWidth: 0
                PathPolyline { path: burst.crests[modelData < 0 ? 0 : 1] }
            }
        }
    }

    LiquidShape {
        readonly property var jet: burst.jetForm()
        visible: burst.isSplashing && jet.size > 0.5
        width: jet.size
        height: jet.size
        x: jet.x - width / 2
        y: jet.y - height / 2
    }

    Repeater {
        model: 2

        LiquidShape {
            required property int index
            readonly property var drop: burst.cornerSplashForm(index)
            visible: burst.isSplashing && drop.size > 0.5
            width: drop.size
            height: drop.size
            x: drop.x - width / 2
            y: drop.y - height / 2
        }
    }

    Repeater {
        model: burst.look.sprayCount

        LiquidShape {
            required property int index
            readonly property var drop: burst.sprayForm(index)
            visible: burst.isSplashing && drop.size > 0.5
            width: drop.size
            height: drop.size
            x: drop.x - width / 2
            y: drop.y - height / 2
        }
    }

    SequentialAnimation {
        id: enter

        NumberAnimation {
            target: burst
            property: "merge"
            to: 1
            duration: Motion.burst.converge
            easing.type: Easing.InQuad
        }
        ParallelAnimation {
            NumberAnimation {
                target: burst
                property: "spread"
                to: 1
                duration: Motion.burst.spread
            }
            SequentialAnimation {
                PauseAnimation { duration: Math.round(Motion.burst.spread * burst.meetShare) }
                NumberAnimation {
                    target: burst
                    property: "impact"
                    to: 1
                    duration: Motion.burst.impact
                }
            }
        }
    }

    SequentialAnimation {
        id: leave

        PauseAnimation { duration: Motion.burst.leaveHold }
        ScriptAction { script: burst.landed() }
        NumberAnimation {
            target: burst
            property: "exit"
            to: 1
            duration: Motion.burst.leave
        }
    }
}
