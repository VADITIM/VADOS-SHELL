import QtQuick
import QtQuick.Shapes
import qs.config
import "../utils/Liquid.js" as Liquid
import "../utils/Geometry.js" as Geometry

Item {
    id: burst

    property string label: "burst"
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
    property real screenHeight: 0
    property bool canHandOff: false
    property bool hasSteps: true
    property bool hasSideStep: false
    property bool isHandingOver: false
    property bool hasCircle: false
    property var wall: []

    property real merge: 0
    property real leaveWallShare: 0
    property real leaveFlare: 0
    property real spread: 0
    property real exit: 0
    property real release: 0
    property bool isReleasing: false
    property real impact: 0
    property real leaveSpread: 0
    property real leaveImpact: 0
    property int rewindDuration: 0
    property var heldForm: ({ x: 0, y: 0, width: 0, height: 0, left: 0, right: 0 })
    property var heldFrame: ({ x: 0, y: 0, width: 0, height: 0 })
    property bool hasLanded: false
    property bool isSwapped: false
    property bool startsFromCircle: false

    readonly property var look: Appearance.burst
    readonly property var pace: Motion.burst
    readonly property var character: Motion.liquid.burst
    readonly property real openTime: pace.spread * (1 - pace.impactShare) / 1000
    readonly property bool isActive: lifecycle.isPresent
    readonly property bool isLeaving: lifecycle.isLeaving
    readonly property string phase: lifecycle.phase
    readonly property bool canRewind: isLeaving && !isHandedOff && exit < pace.leaveShrink
    readonly property bool isOpened: isShown && !isLeaving && spread >= pace.openShare
    readonly property bool isSplashing: !Motion.isReduced && isShown && !isLeaving && spread > pace.impactShare

    readonly property var frame: ({ x: seedX, y: seedY, width: formWidth, height: formHeight })
    readonly property var leaveFrom: Geometry.refit(heldForm, heldFrame, frame)
    readonly property real halfHeight: formHeight / 2
    readonly property real farX: rootX + formWidth
    readonly property real farDistance: farX - seedX
    readonly property real startReach: look.ball * (1 + pace.inflate) / 2
    readonly property real opening: Geometry.clampUnit((spread - pace.impactShare) / (1 - pace.impactShare))
    readonly property real widthShare: Liquid.rise(character, opening * openTime)
    readonly property real heightShare: Liquid.rise(character, opening * pace.heightLead * openTime)
    readonly property real front: startReach + (farDistance - startReach) * widthShare
    readonly property real crossShare: crossOf(pace.heightLead)
    readonly property real meetShare: pace.impactShare + (crossShare + pace.crestRun * (1 - crossShare)) * (1 - pace.impactShare)

    readonly property var flights: (parts || []).map(part => flightOf(part))
    readonly property real nearest: flights.reduce((shortest, flight) => Math.min(shortest, flight.distance), Infinity)
    readonly property real farthest: flights.reduce((longest, flight) => Math.max(longest, flight.distance), 0)
    readonly property real longestExtension: flights.reduce((longest, flight) => Math.max(longest, flight.extension), 0)
    readonly property real totalArea: flights.reduce((sum, flight) => sum + flight.area, 0)
    readonly property real arrived: totalArea > 0
        ? flights.reduce((sum, flight) => sum + flight.area * absorbedShare(flight), 0) / totalArea
        : Geometry.smooth(merge)

    readonly property var closed: ({ x: seedX, y: seedY, width: 0, height: 0, left: 0, right: 0 })
    readonly property var form: !isActive ? closed : isLeaving ? leaveForm(exit, leaveFrom) : enterForm(spread)
    readonly property real formRight: form.x + form.width / 2
    readonly property real restSize: isSwapped ? look.ball : look.leaveBall
    readonly property bool isHandedOff: (canHandOff || isSwapped) && !isReleasing && isLeaving && exit >= pace.leaveShrink
    readonly property bool hasReleased: isReleasing && release >= 1
    readonly property real releasedArea: isReleasing && totalArea > 0 ? flights.reduce((sum, flight) => sum + flight.area * releaseTravelOf(flight), 0) / totalArea : 0
    readonly property bool isStepped: hasSteps && (isSplashing || isLeaving) && !isHandedOff
    readonly property var topStep: stepForm("top")
    readonly property var bottomStep: stepForm("bottom")
    readonly property var sideStep: stepForm("side")
    readonly property real aboveRise: isStepped ? topStep.rise : 0
    readonly property real belowRise: isStepped ? bottomStep.rise : 0
    readonly property bool isFullHeight: formHeight >= screenHeight - 1
    readonly property real formTop:form.y - form.height / 2
    readonly property real rootTip: Math.min(rootX + look.rootSpan, form.x)
    readonly property real rootInner: (form.height + aboveRise + belowRise) / 2
    readonly property real rootOuter: rootInner + Math.min(look.rootSwell, form.height * look.swellShare)
    readonly property real wallShare: wall.length === 0 || !isActive ? 0
        : isLeaving ? leaveWallShare * Geometry.clampUnit((form.width - restSize) / Math.max(1, leaveFrom.width - restSize))
        : spread < pace.impactShare ? 0
        : Math.max(0, (form.width - 2 * startReach) / Math.max(1, farX - rootX - 2 * startReach))
    readonly property bool hasWall: wallShare > 0 && !isHandedOff && form.height > 0.5
    readonly property real flare: !isActive ? 0
        : isLeaving ? leaveFlare * (1 - Geometry.smooth(Geometry.clampUnit(exit / pace.flareRetract)))
        : Geometry.smooth(Geometry.clampUnit((opening - pace.flareStart) / (1 - pace.flareStart)))
    property var wallOutline: []
    readonly property bool hasTracks: isSplashing || hasWall
    property var topTrack: null
    property var bottomTrack: null
    property var bodyOutline: []
    property var crests: [[], []]
    property real farFront: 0
    readonly property var visitor: isActive && isLeaving && !isSwapped ? ({ x: form.x, y: form.y, width: form.width, height: form.height, isHandedOff: isHandedOff, hasReleased: hasReleased, isReleasing: isReleasing, release: release, arrivals: flights.map(flight => ({ y: flight.y, arrival: arrivalOf(flight) })) }) : null

    signal landed()

    function crossOf(lead) {
        return Liquid.arrival(character) / (lead * openTime)
    }

    function sinceCross(lead) {
        const cross = crossOf(lead)
        return opening < cross ? -1 : (opening - cross) / (1 - cross)
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
        const grip = Geometry.smooth(Geometry.clampUnit(opening / pace.rootShare))
        const wobble = look.impactPush * impactWobble()
        const left = seedX - startReach + (rootX - seedX + startReach) * grip
        const right = seedX + front + wobble
        const drag = 1 - pace.drag * Math.max(0, widthShare - 1)
        const open = (2 * startReach + (formHeight - 2 * startReach) * heightShare) * drag - wobble * pace.impactSquash
        const missing = Math.max(0, formHeight - open)
        const snap = Geometry.smooth(Geometry.clampUnit(1 - missing / 2 / look.edgeSnap))
        const reached = Geometry.smooth(Geometry.clampUnit((heightShare - look.edgeReached) / (1 - look.edgeReached)))
        const height = open + missing * (isFullHeight ? Math.max(snap, reached) : snap)
        const width = right - left
        const limit = Math.min(width, height) / 2
        return {
            x: (left + right) / 2,
            y: seedY,
            width: width,
            height: height,
            left: Math.min(limit, limit + (leftCorner - limit) * grip),
            right: Math.min(limit, limit + (rightCorner - limit) * Geometry.clampUnit(widthShare))
        }
    }

    function leaveForm(exit, from) {
        const size = restSize * (isReleasing ? Math.sqrt(1 - releasedArea) : 1)
        const collapse = 1 - Math.pow(1 - Geometry.clampUnit(exit / pace.leaveShrink), 3)
        const width = from.width + (size - from.width) * collapse
        const height = from.height + (size - from.height) * collapse
        const limit = Math.min(width, height) / 2
        const fromLeft = from.x - from.width / 2
        const left = fromLeft + (seedX - size / 2 - fromLeft) * collapse
        const slide = isReleasing || isSwapped ? 0 : exit * exit * (seedX + size / 2 + edgePad)
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
        return {
            x: fromX,
            y: fromY,
            width: part.width,
            height: part.height,
            area: part.width * part.height,
            isUpright: part.height >= part.width,
            extension: Math.abs(part.height - part.width),
            distance: Math.hypot(seedX - fromX, seedY - fromY)
        }
    }

    function progressOf(flight) {
        const order = farthest > nearest ? (flight.distance - nearest) / (farthest - nearest) : 0
        return Geometry.clampUnit((merge - pace.convergeLag * order) / (1 - pace.convergeLag))
    }

    function absorbedShare(flight) {
        return Geometry.clampUnit((progressOf(flight) - (1 - pace.absorbShare)) / pace.absorbShare)
    }

    function streamForm(flight) {
        const progress = progressOf(flight)
        const shrink = shrinkShareOf(flight)
        const rounded = shrink > 0 ? Geometry.smooth(Geometry.clampUnit(progress / shrink)) : 1
        const flown = Geometry.clampUnit((progress - shrink) / (1 - shrink))
        const travel = flown * (pace.travelStart + (1 - pace.travelStart) * flown)
        const remaining = 1 - absorbedShare(flight)
        const thin = Math.min(flight.width, flight.height)
        const lengthwise = Math.max(flight.width, flight.height)
        const length = lengthwise + (thin - lengthwise) * rounded
        return {
            x: flight.x + (seedX - flight.x) * travel,
            y: flight.y + (seedY - flight.y) * travel,
            width: (flight.isUpright ? thin : length) * remaining,
            height: (flight.isUpright ? length : thin) * remaining
        }
    }

    function shrinkShareOf(flight) {
        return longestExtension > 0 ? pace.shrinkShare * flight.extension / longestExtension : 0
    }

    function arrivalOf(flight) {
        const extension = longestExtension > 0 ? flight.extension / longestExtension : 0
        return pace.releaseTravel + (1 - pace.releaseTravel) * extension
    }

    function releaseTravelOf(flight) {
        return Geometry.clampUnit(release / pace.releaseTravel)
    }

    function releaseForm(flight) {
        const moved = releaseTravelOf(flight)
        const travel = Geometry.smooth(moved)
        const grown = Geometry.clampUnit(moved / pace.releaseEmerge)
        const begin = pace.releaseTravel - pace.releaseExtendLead
        const span = (arrivalOf(flight) - begin) * pace.releaseExtendSpeed
        const start = arrivalOf(flight) - span
        const extension = span > 0 ? Geometry.rebound(Geometry.clampUnit((release - start) / span), pace.releaseRebound) : 1
        const thin = Math.min(flight.width, flight.height) * grown
        const lengthwise = Math.max(flight.width, flight.height)
        const length = thin + (lengthwise - thin) * extension
        return {
            x: seedX + (flight.x - seedX) * travel,
            y: seedY + (flight.y - seedY) * travel,
            width: flight.isUpright ? thin : length,
            height: flight.isUpright ? length : thin
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
        const last = rootLobe.bendAt(1, side)
        const count = Geometry.samplesFor(Math.hypot(last.x - before.x, last.y - before.y) * look.curveSlack, look.curveStep)
        for (let sample = 1; sample <= count; sample++) {
            const next = rootLobe.bendAt(sample / count, side)
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

    function traceContext() {
        return {
            top: form.y,
            screenHeight: screenHeight,
            seamBlend: look.seamBlend,
            edgeHold: look.edgeHold,
            edgeFade: look.edgeFade,
            curveStep: look.curveStep,
            troughStep: look.troughStep,
            crestLength: look.crestLength,
            troughLength: look.troughLength,
            trough: look.trough,
            crestInset: look.crestInset
        }
    }

    function seamShare(toEnd, context) {
        return Geometry.smooth(Geometry.clampUnit(toEnd / context.seamBlend))
    }

    function freeShare(point, context) {
        const gap = Math.min(point.x, point.y, context.screenHeight - point.y)
        return Geometry.smooth(Geometry.clampUnit((gap - context.edgeHold) / context.edgeFade))
    }

    function normalAt(segment, side, remaining, toEnd, context) {
        let x = segment.normalX
        let y = segment.normalDepth
        if (segment.isArc) {
            const angle = Math.PI / 2 - remaining / Math.max(0.001, segment.radius)
            x = Math.cos(angle)
            y = Math.sin(angle)
        }
        y *= side
        const blend = 1 - seamShare(toEnd, context)
        if (blend <= 0)
            return { x: x, y: y }
        const blendedX = x + ((x >= 0 ? 1 : -1) - x) * blend
        const blendedY = y * (1 - blend)
        const length = Math.max(0.001, Math.hypot(blendedX, blendedY))
        return { x: blendedX / length, y: blendedY / length }
    }

    function basePoint(segment, side, remaining, context) {
        if (segment.isArc) {
            const angle = Math.PI / 2 - remaining / Math.max(0.001, segment.radius)
            return { x: segment.x + segment.radius * Math.cos(angle), y: context.top + side * (segment.depth + segment.radius * Math.sin(angle)) }
        }
        const share = segment.length > 0 ? Math.min(1, remaining / segment.length) : 0
        return { x: segment.x + (segment.toX - segment.x) * share, y: context.top + side * (segment.depth + (segment.toDepth - segment.depth) * share) }
    }

    function segmentPoint(segment, side, remaining, depth, toEnd, context) {
        const base = basePoint(segment, side, remaining, context)
        if (depth === 0)
            return Qt.point(base.x, base.y)
        const offset = depth * seamShare(toEnd, context) * freeShare(base, context)
        if (offset === 0)
            return Qt.point(base.x, base.y)
        const normal = normalAt(segment, side, remaining, toEnd, context)
        return Qt.point(base.x + normal.x * offset, base.y + normal.y * offset)
    }

    function joinPoints(from, to, side, depth, toEnd, context) {
        if (depth === 0)
            return []
        const corner = basePoint(to, side, 0, context)
        const offset = depth * seamShare(toEnd, context) * freeShare(corner, context)
        if (Math.abs(offset) < 0.5)
            return []
        const before = normalAt(from, side, from.length, toEnd, context)
        const after = normalAt(to, side, 0, toEnd, context)
        const start = Math.atan2(before.y, before.x)
        let turn = Math.atan2(after.y, after.x) - start
        if (turn > Math.PI)
            turn -= 2 * Math.PI
        if (turn < -Math.PI)
            turn += 2 * Math.PI
        const count = Math.ceil(Math.abs(turn * offset) / context.curveStep)
        const points = []
        for (let sample = 0; sample < count; sample++) {
            const angle = start + turn * sample / count
            points.push(Qt.point(corner.x + Math.cos(angle) * offset, corner.y + Math.sin(angle) * offset))
        }
        return points
    }

    function wallPoints() {
        return wall.map((point, index) => Qt.point(formRight + flaredX(index) * wallShare, formTop + point.y * form.height))
    }

    function trace() {
        wallOutline = hasWall ? Geometry.traceSpline(wallPoints(), look.curveStep, look.curveSlack) : []
        farFront = wallOutline.length > 0 ? wallXAt(form.y) : formRight
        if (!hasTracks) {
            topTrack = null
            bottomTrack = null
            bodyOutline = []
            crests = [[], []]
            return
        }
        topTrack = wallTrack(-1)
        bottomTrack = wallTrack(1)
        bodyOutline = hasWall ? roundedOutline(edgePoints(-1).concat(edgePoints(1).reverse())) : []
        crests = [crestPath(-1), crestPath(1)]
    }

    function roundedOutline(points) {
        const gap = Math.max(0, Math.min(formTop, screenHeight - formTop - form.height))
        const fade = Geometry.smooth(Geometry.clampUnit(gap / look.edgeRoundFade))
        const reach = (form.right + (look.edgeRound - form.right) * Geometry.smooth(Geometry.clampUnit(wallShare))) * fade
        return Geometry.roundCorners(points, reach, look.curveStep, look.cornerSharpness)
    }

    function queueTrace() {
        Qt.callLater(trace)
    }

    function trackOf(side) {
        return side < 0 ? topTrack : bottomTrack
    }

    function waveHead(total) {
        return total * Geometry.smooth(Geometry.clampUnit(sinceCross(pace.heightLead) / pace.crestRun))
    }

    function troughDepth(distance, head, scale, context) {
        const away = Math.abs(distance - head) - context.crestLength / 2
        if (scale <= 0 || away <= 0 || away >= context.troughLength)
            return 0
        const wave = Math.sin(Math.PI * away / context.troughLength)
        return -context.trough * scale * wave * wave
    }

    function edgePoints(side) {
        const track = trackOf(side)
        if (!track)
            return []
        const context = traceContext()
        const scale = crestHeight() / look.crest
        const head = waveHead(track.total)
        const from = head - context.crestLength / 2 - context.troughLength
        const to = head + context.crestLength / 2 + context.troughLength
        const points = []
        const total = track.total
        const segments = track.segments
        let passed = 0
        let before = null
        for (let index = 0; index < segments.length; index++) {
            const segment = segments[index]
            const end = passed + segment.length
            const depth = troughDepth(passed, head, scale, context)
            if (before && depth !== 0)
                points.push(...joinPoints(before, segment, side, depth, total - passed, context))
            points.push(segmentPoint(segment, side, 0, depth, total - passed, context))
            const isTroughed = scale > 0 && to > passed && from < end
            if (isTroughed || segment.isArc) {
                const first = isTroughed ? Math.max(passed, from) : passed
                const last = isTroughed ? Math.min(end, to) : end
                const count = Geometry.samplesFor(last - first, segment.isArc ? context.curveStep : context.troughStep)
                for (let sample = 0; sample <= count; sample++) {
                    const distance = first + (last - first) * sample / count
                    points.push(segmentPoint(segment, side, distance - passed, troughDepth(distance, head, scale, context), total - distance, context))
                }
            }
            passed = end
            before = segment
        }
        const closing = segments[segments.length - 1]
        points.push(segmentPoint(closing, side, closing.length, troughDepth(passed, head, scale, context), 0, context))
        return points
    }

    function crestPath(side) {
        const height = crestHeight()
        const track = trackOf(side)
        if (height < 0.5 || !track)
            return []
        const context = traceContext()
        const segments = track.segments
        const total = track.total
        const head = waveHead(total)
        const from = Math.max(0, head - context.crestLength / 2)
        const to = Math.min(total, head + context.crestLength / 2)
        const outer = []
        const inner = []
        let index = 0
        let passed = 0
        const count = Geometry.samplesFor(to - from, context.curveStep)
        for (let sample = 0; sample <= count; sample++) {
            const distance = from + (to - from) * sample / count
            while (index < segments.length - 1 && distance > passed + segments[index].length) {
                passed += segments[index].length
                index++
                if (passed <= from)
                    continue
                const joint = Math.cos(Math.PI * (passed - head) / context.crestLength)
                outer.push(...joinPoints(segments[index - 1], segments[index], side, height * joint * joint, total - passed, context))
            }
            const bump = Math.cos(Math.PI * (distance - head) / context.crestLength)
            outer.push(segmentPoint(segments[index], side, distance - passed, height * bump * bump, total - distance, context))
            inner.push(segmentPoint(segments[index], side, distance - passed, -context.crestInset, total - distance, context))
        }
        return outer.concat(inner.reverse(), [outer[0]])
    }

    function crestHeight() {
        const since = sinceCross(pace.heightLead)
        if (since < 0 || isLeaving)
            return 0
        const swell = impact < pace.moundPeak ? Math.sin(Math.PI / 2 * impact / pace.moundPeak) : 1
        const sink = Geometry.smooth(Geometry.clampUnit((impact - pace.moundPeak) / pace.moundSink))
        return look.crest * Geometry.clampUnit(since / pace.crestRise) * (1 + pace.moundRise * swell) * (1 - sink)
    }

    function jetForm() {
        const flight = Geometry.clampUnit(impact / pace.jetShare)
        const isFlying = impact > 0 && flight < 1
        return {
            x: farFront + look.jetReach * 4 * flight * (1 - flight),
            y: seedY,
            size: isFlying ? look.jet * (1 - flight * flight) : 0
        }
    }

    function impactWobble() {
        return impact >= 1 ? 0 : -Liquid.ring(Motion.liquid.crash, impact * pace.impact / 1000)
    }

    function stepForm(kind) {
        const retract = isLeaving ? 1 - Geometry.smooth(Geometry.clampUnit(exit / pace.stepRetract)) : 1
        const grow = Geometry.clampUnit(form.height / Math.max(1, formHeight)) * retract
        if (kind === "side") {
            const rise = look.stepSide * grow * Geometry.smooth(Geometry.clampUnit((spread - meetShare) / (1 - meetShare)))
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
        const arc = since < 0 ? 0 : Math.sin(Math.PI * Geometry.clampUnit(since / pace.splashSpan))
        if (hasWall && wallOutline.length > 0) {
            const corner = index === 0 ? wallOutline[0] : wallOutline[wallOutline.length - 1]
            const reach = look.cornerReach * arc * Math.SQRT1_2
            return { x: corner.x + reach, y: corner.y + side * reach, size: look.cornerSplash * arc }
        }
        const offset = rightCorner * (1 - Math.SQRT1_2) - look.cornerReach * arc * Math.SQRT1_2
        return { x: formRight - offset, y: seedY + side * (form.height / 2 - offset), size: look.cornerSplash * arc }
    }

    function stopAll() {
        enter.stop()
        rewinding.stop()
        resuming.stop()
        leave.stop()
        releasing.stop()
    }

    function prepare() {
        stopAll()
        startsFromCircle = hasCircle
        merge = startsFromCircle ? 1 : 0
        spread = 0
        impact = 0
        exit = 0
        release = 0
        isReleasing = false
        isSwapped = false
        enter.restart()
    }

    function rewind() {
        leave.stop()
        releasing.stop()
        rewindDuration = Math.round(Motion.burst.leave * exit)
        rewinding.restart()
    }

    function reopen() {
        isReleasing = false
        merge = 1
        spread = leaveSpread
        impact = leaveImpact
        resuming.restart()
    }

    function holdLeave() {
        leaveSpread = spread
        leaveImpact = impact
        leaveWallShare = wallShare
        leaveFlare = flare
        const shape = form
        heldFrame = frame
        heldForm = shape
    }

    function land() {
        if (hasLanded)
            return
        hasLanded = true
        landed()
    }

    function startLeave() {
        enter.stop()
        rewinding.stop()
        resuming.stop()
        exit = 0
        release = 0
        isSwapped = isHandingOver
        isReleasing = canHandOff && flights.length > 0 && !isSwapped
        hasLanded = false
        if (isReleasing)
            releasing.restart()
        else
            leave.restart()
    }

    function settle(phase) {
        stopAll()
        if (phase === "active") {
            merge = 1
            spread = 1
            impact = 1
        }
        exit = phase === "active" ? 0 : 1
        release = phase === "idle" && isReleasing ? 1 : 0
        if (phase === "idle")
            land()
    }

    property Lifecycle lifecycle: Lifecycle {
        name: burst.label
        canRecover: burst.canRewind
        onMoving: (from, to, event) => {
            if (to === "exiting")
                burst.holdLeave()
        }
        onMoved: (from, to, event) => {
            if (event === "settle")
                burst.settle(to)
            else if (to === "preparing")
                burst.prepare()
            else if (to === "recovering")
                burst.rewind()
            else if (to === "entering" && from === "recovering")
                burst.reopen()
            else if (to === "exiting")
                burst.startLeave()
        }
    }

    onIsShownChanged: lifecycle.send(isShown ? "show" : "hide")
    onFormChanged: queueTrace()
    onImpactChanged: queueTrace()
    onHasTracksChanged: queueTrace()
    onWallChanged: queueTrace()
    Component.onCompleted: if (isShown) lifecycle.send("show")

    anchors.fill: parent

    Repeater {
        model: burst.flights

        LiquidShape {
            required property var modelData
            readonly property var stream: burst.releaseForm(modelData)
            visible: burst.isReleasing && burst.release > 0 && stream.height > 0.5
            width: stream.width
            height: stream.height
            x: stream.x - width / 2
            y: stream.y - height / 2
        }
    }

    Repeater {
        model: burst.flights

        LiquidShape {
            required property var modelData
            readonly property var stream: burst.streamForm(modelData)
            visible: burst.isShown && !burst.isLeaving && burst.spread <= 0 && stream.height > 0.5
            width: stream.width
            height: stream.height
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
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "white"
            fillRule: ShapePath.WindingFill
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
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "white"
                fillRule: ShapePath.WindingFill
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

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: enter

        NumberAnimation {
            target: burst
            property: "merge"
            to: 1
            duration: Motion.pace(burst.startsFromCircle ? 0 : Motion.burst.converge)
        }
        ScriptAction { script: burst.lifecycle.send("prepared") }
        ParallelAnimation {
            NumberAnimation {
                target: burst
                property: "spread"
                to: 1
                duration: Motion.pace(Motion.burst.spread)
            }
            SequentialAnimation {
                PauseAnimation { duration: Motion.pace(Math.round(Motion.burst.spread * burst.meetShare)) }
                NumberAnimation {
                    target: burst
                    property: "impact"
                    to: 1
                    duration: Motion.pace(Motion.burst.impact)
                }
            }
        }
        ScriptAction { script: burst.lifecycle.send("entered") }
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: rewinding

        NumberAnimation {
            target: burst
            property: "exit"
            to: 0
            duration: Motion.pace(burst.rewindDuration)
            easing.type: Easing.OutCubic
        }
        ScriptAction { script: burst.lifecycle.send("recovered") }
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: resuming

        ParallelAnimation {
            NumberAnimation {
                target: burst
                property: "spread"
                to: 1
                duration: Motion.pace(Math.round(Motion.burst.spread * (1 - burst.leaveSpread)))
            }
            NumberAnimation {
                target: burst
                property: "impact"
                to: 1
                duration: Motion.pace(Math.round(Motion.burst.impact * (1 - burst.leaveImpact)))
            }
        }
        ScriptAction { script: burst.lifecycle.send("entered") }
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: leave

        PauseAnimation { duration: Motion.pace(Motion.burst.leaveHold) }
        NumberAnimation {
            target: burst
            property: "exit"
            to: burst.pace.leaveShrink
            duration: Motion.pace(Motion.burst.leave * burst.pace.leaveShrink)
        }
        ScriptAction { script: burst.land() }
        NumberAnimation {
            target: burst
            property: "exit"
            to: 1
            duration: Motion.pace(Motion.burst.leave * (1 - burst.pace.leaveShrink))
        }
        ScriptAction { script: burst.lifecycle.send("exited") }
    }

    SequentialAnimation {
        paused: Motion.isHeld && running
        id: releasing

        PauseAnimation { duration: Motion.pace(Motion.burst.leaveHold) }
        NumberAnimation {
            target: burst
            property: "exit"
            to: burst.pace.leaveShrink
            duration: Motion.pace(Motion.burst.leave * burst.pace.leaveShrink)
        }
        NumberAnimation {
            target: burst
            property: "release"
            to: 1
            duration: Motion.pace(Motion.burst.release)
        }
        ScriptAction { script: burst.land() }
        ScriptAction { script: burst.lifecycle.send("exited") }
    }
}
