.pragma library
.import "Geometry.js" as Geometry
.import "Liquid.js" as Liquid
.import "Variation.js" as Variation
.import "Veil.js" as Veil

const hidden = { x: 0, y: 0, width: 0, height: 0, rotation: 0, corner: 0, isShown: false }

function hiddenForm() {
    return hidden
}

function slungAt(time, windup, flight, pull, carry) {
    if (time <= 0)
        return 0
    if (time < windup)
        return -pull * Math.sin(Math.PI / 2 * time / windup)
    const flown = Geometry.clampUnit((time - windup) / Math.max(1, flight))
    return -pull + (1 + pull) * (carry * flown + (1 - carry) * (1 - (1 - flown) * (1 - flown)))
}

function flownAt(share, pull, carry) {
    const target = Geometry.clampUnit((share + pull) / (1 + pull))
    if (carry >= 1)
        return target
    const curve = 1 - carry
    return ((2 - carry) - Math.sqrt(Math.max(0, (2 - carry) * (2 - carry) - 4 * curve * target))) / (2 * curve)
}

function tangentAt(from, control, to, share) {
    return Qt.point(2 * (1 - share) * (control.x - from.x) + 2 * share * (to.x - control.x), 2 * (1 - share) * (control.y - from.y) + 2 * share * (to.y - control.y))
}

function foldedOf(heading) {
    return Math.abs(heading) > 90 ? heading - Math.sign(heading) * 180 : heading
}

function unitOf(vector) {
    const length = Math.hypot(vector.x, vector.y)
    return length > 0.0001 ? Qt.point(vector.x / length, vector.y / length) : Qt.point(0, 0)
}

function knockAt(hits, time, character) {
    let x = 0
    let y = 0
    let swell = 0
    for (const hit of hits) {
        const since = (time - hit.at) / 1000
        if (since <= 0)
            continue
        const ring = Liquid.ring(character, since)
        x += hit.x * ring
        y += hit.y * ring
        swell += hit.swell * ring
    }
    return { x: x, y: y, swell: swell }
}

function sizeOf(hits, time) {
    let area = 0
    for (const hit of hits) {
        if (hit.at <= time)
            area += hit.area
    }
    return Math.sqrt(area)
}

function bendsOf(count, random, least, most) {
    const bends = []
    const start = random() < 0.5 ? -1 : 1
    for (let index = 0; index < count; index++)
        bends.push((index % 2 === 0 ? start : -start) * Variation.between(random, least, most))
    return bends
}

function flightOf(from, to, bend, launch, windup, flight, pull, pullLimit) {
    const distance = Math.hypot(to.x - from.x, to.y - from.y)
    const share = distance > 1 ? Math.min(pullLimit, pull / distance) : 0
    return { from: from, to: to, control: Veil.bendOf(from, to, bend), launch: launch, windup: windup, flight: flight, pull: share, arrival: launch + windup + flight }
}

function motionAt(path, time, carry, step) {
    const since = time - path.launch
    const share = slungAt(since, path.windup, path.flight, path.pull, carry)
    const ahead = slungAt(since + step, path.windup, path.flight, path.pull, carry)
    const point = Geometry.arcAt(path.from, path.control, path.to, share)
    const next = Geometry.arcAt(path.from, path.control, path.to, ahead)
    const speed = Math.hypot(next.x - point.x, next.y - point.y) / step
    const heading = Math.atan2(next.y - point.y, next.x - point.x) * 180 / Math.PI
    return { share: share, x: point.x, y: point.y, speed: speed, heading: speed > 0.01 ? heading : 0 }
}

function blobOf(x, y, size, stretch, heading) {
    const along = size * (1 + stretch)
    const across = size / (1 + stretch)
    return { x: x - along / 2, y: y - across / 2, width: along, height: across, rotation: foldedOf(heading), corner: across / 2, isShown: size > 0.5 }
}

function stretchedOf(x, y, size, motion, look) {
    return blobOf(x, y, size, Geometry.stretchOf(motion.speed, look.stretchGain, look.stretchLimit), motion.heading)
}

function directedOf(width, height, stretch, heading) {
    const angle = heading * Math.PI / 180
    const lean = Math.cos(angle) * Math.cos(angle) - Math.sin(angle) * Math.sin(angle)
    const factor = Math.pow(1 + stretch, lean)
    return { width: width * factor, height: height / factor }
}

function knockedOf(x, y, size, knock, look) {
    const reach = Math.hypot(knock.x, knock.y)
    const stretch = Math.min(look.stretchLimit, reach * look.knockStretch)
    return blobOf(x + knock.x, y + knock.y, size, stretch, reach > 0.01 ? Math.atan2(knock.y, knock.x) * 180 / Math.PI : 0)
}

function convergeOf(sources, point, setup, timing, random, start) {
    const look = setup.look
    const order = sources.map((rect, index) => ({ index: index, distance: Math.hypot(rect.x + rect.width / 2 - point.x, rect.y + rect.height / 2 - point.y) }))
    order.sort((first, second) => first.distance - second.distance)
    const farthest = order.reduce((longest, entry) => Math.max(longest, entry.distance), 1)
    const stagger = Math.min(timing.stagger, timing.spread / Math.max(1, sources.length - 1))
    const gap = Math.min(timing.gap, stagger)
    const bends = bendsOf(sources.length, random, look.bendLeast, look.bend)
    const flights = new Array(sources.length)
    let lastArrival = -Infinity
    order.forEach((entry, rank) => {
        const rect = sources[entry.index]
        const from = Qt.point(rect.x + rect.width / 2, rect.y + rect.height / 2)
        const flight = timing.flight * Geometry.mix(timing.near, 1, entry.distance / farthest) * Variation.around(random, timing.wobble)
        let launch = start + rank * stagger * Variation.around(random, timing.wobble)
        const arrival = launch + timing.windup + flight
        if (arrival < lastArrival + gap)
            launch += lastArrival + gap - arrival
        const path = flightOf(from, point, bends[rank], launch, timing.windup, flight, look.pull, look.pullLimit)
        path.rect = rect
        path.corner = rect.corner ?? look.corner
        flights[entry.index] = path
        lastArrival = path.arrival
    })
    const ordered = flights.slice().sort((first, second) => first.arrival - second.arrival)
    const hits = []
    let area = 0
    for (const path of ordered) {
        const drop = look.drop * look.drop
        area += drop
        const share = drop / area
        const arriving = unitOf(tangentAt(path.from, path.control, path.to, 1))
        const isFirst = hits.length === 0
        hits.push({
            at: path.arrival,
            area: drop,
            x: isFirst ? 0 : arriving.x * look.knock * share,
            y: isFirst ? 0 : arriving.y * look.knock * share,
            swell: isFirst ? 0 : look.knockSwell * share
        })
    }
    return { flights: flights, hits: hits, done: hits.length > 0 ? hits[hits.length - 1].at : start }
}

function dropAt(path, time, setup) {
    if (time >= path.arrival)
        return hidden
    const look = setup.look
    const motion = motionAt(path, time, setup.pace.carry, setup.pace.step)
    const grown = 1 - Math.pow(1 - Geometry.clampUnit(motion.share), look.growth)
    const formWidth = Geometry.mix(path.rect.width, look.drop, grown)
    const formHeight = Geometry.mix(path.rect.height, look.drop, grown)
    if (formWidth < 0.5 || formHeight < 0.5)
        return hidden
    const turning = motion.share > 0 ? grown * grown : 0
    const speed = Geometry.stretchOf(motion.speed, look.stretchGain, look.stretchLimit)
    const stretch = speed * turning
    const directed = directedOf(formWidth, formHeight, speed * (1 - turning) * look.bodyStretch, motion.heading)
    return {
        x: motion.x - directed.width * (1 + stretch) / 2,
        y: motion.y - directed.height / (1 + stretch) / 2,
        width: directed.width * (1 + stretch),
        height: directed.height / (1 + stretch),
        rotation: foldedOf(motion.heading) * turning,
        corner: Geometry.mix(path.corner, look.drop / 2, grown),
        isShown: true
    }
}

function bubblesOf(random, origin, heading, cone, at, look, pace) {
    const count = Math.floor(Variation.between(random, look.bubblesLeast, look.bubblesMost + 1))
    const bubbles = []
    for (let index = 0; index < count; index++) {
        bubbles.push({
            x: origin.x,
            y: origin.y,
            angle: heading + cone * (2 * random() - 1),
            reach: look.bubbleReach * Variation.around(random, look.bubbleSpread),
            size: look.bubble * Variation.around(random, look.bubbleSpread),
            at: at + Variation.between(random, 0, pace.bubbleStagger),
            flight: pace.bubble * Variation.around(random, look.bubbleSpread)
        })
    }
    return bubbles
}

function bubbleAt(bubble, time, look) {
    const flown = (time - bubble.at) / bubble.flight
    if (flown <= 0 || flown >= 1)
        return hidden
    const out = 1 - Math.pow(1 - flown, 3)
    const x = bubble.x + Math.cos(bubble.angle) * bubble.reach * out
    const y = bubble.y + Math.sin(bubble.angle) * bubble.reach * out
    const popping = Geometry.clampUnit((flown - look.bubblePopAt) / (1 - look.bubblePopAt))
    const size = bubble.size * (popping > 0 ? Geometry.mix(1, look.bubblePop, popping) : Geometry.mix(look.bubbleBirth, 1, flown / look.bubblePopAt))
    return { x: x - size / 2, y: y - size / 2, width: size, height: size, rotation: 0, corner: size / 2, isShown: true }
}

function wallXOf(setup, isFar) {
    return isFar !== setup.isMirrored ? setup.width : 0
}

function enterOf(setup, seed) {
    const random = Variation.seeded(seed)
    const look = setup.look
    const pace = setup.pace
    const gather = setup.gather
    const sources = setup.sources.length > 0 ? setup.sources : [{ x: gather.x, y: gather.y, width: 0, height: 0 }]
    const converge = convergeOf(sources, gather, setup, { stagger: pace.gatherStagger, spread: pace.gatherSpread, flight: pace.gatherFlight, windup: pace.windup, near: pace.near, wobble: pace.wobble, gap: pace.mergeGap }, random, 0)
    const size = sizeOf(converge.hits, Infinity)
    const side = setup.isMirrored ? -1 : 1
    const wallX = wallXOf(setup, true)
    const contact = Qt.point(wallX - side * size / 2, setup.height / 2 + setup.height * look.wallSpread * (2 * random() - 1))
    const launchAt = converge.done + pace.gatherPop
    const core = flightOf(gather, contact, (random() < 0.5 ? -1 : 1) * Variation.between(random, look.bendLeast, look.bend), launchAt, pace.coreWindup, pace.sling, look.corePull, look.pullLimit)
    const hitAt = core.arrival
    const splitAt = hitAt + pace.wallHold / 2
    const order = setup.frames.map((frame, index) => index)
    for (let index = order.length - 1; index > 0; index--) {
        const swap = Math.floor(random() * (index + 1))
        const kept = order[index]
        order[index] = order[swap]
        order[swap] = kept
    }
    const stagger = Math.min(pace.splitStagger, pace.splitSpread / Math.max(1, order.length - 1))
    const bends = bendsOf(order.length, random, look.bendLeast, look.bend)
    const splits = new Array(setup.frames.length)
    const springs = Qt.point(wallX - side * size / (2 * Math.sqrt(Math.max(1, setup.frames.length))), contact.y)
    order.forEach((frameIndex, rank) => {
        const frame = setup.frames[frameIndex]
        const launch = splitAt + rank * stagger * Variation.around(random, pace.wobble)
        const path = flightOf(springs, Geometry.centerOf(frame), bends[rank], launch, pace.splitWindup, pace.splitFlight * Variation.around(random, pace.wobble), look.splitPull, look.pullLimit)
        path.frame = frame
        splits[frameIndex] = path
    })
    const lastArrival = splits.reduce((latest, path) => Math.max(latest, path.arrival), splitAt)
    const share = size * size / Math.max(1, splits.length)
    const birth = Math.sqrt(share)
    for (const path of splits)
        path.birth = birth
    return {
        kind: "enter",
        converge: converge,
        size: size,
        gather: gather,
        core: core,
        side: side,
        wallX: wallX,
        contact: contact,
        hitAt: hitAt,
        splitAt: splitAt,
        share: share,
        splits: splits,
        bubbles: bubblesOf(random, Qt.point(wallX, contact.y), setup.isMirrored ? 0 : Math.PI, look.wallCone, hitAt, look, pace),
        total: (splits.length > 0 ? lastArrival : splitAt + pace.splitFlight) + pace.settle
    }
}

function enterCoreAt(plan, time, setup) {
    const look = setup.look
    const pace = setup.pace
    const hits = plan.converge.hits
    if (hits.length === 0 || time < hits[0].at)
        return hidden
    const knock = knockAt(hits, time, setup.knock)
    let size = sizeOf(hits, time) * (1 + knock.swell)
    const popSince = time - plan.converge.done
    if (popSince > 0 && popSince < pace.gatherPop)
        size *= 1 + (look.gatherPop - 1) * Math.sin(Math.PI * popSince / pace.gatherPop)
    if (time < plan.core.launch)
        return knockedOf(plan.gather.x, plan.gather.y, size, knock, look)
    const motion = motionAt(plan.core, Math.min(time, plan.core.arrival), pace.carry, pace.step)
    if (time < plan.core.arrival)
        return stretchedOf(motion.x + knock.x, motion.y + knock.y, size, motion, look)
    const popping = Geometry.clampUnit((time - plan.splitAt) / pace.pop)
    if (popping >= 1)
        return hidden
    const burst = popping > 0 ? (1 + (look.popSwell - 1) * Math.sin(Math.PI * popping)) * (1 - popping) : 1
    const pressing = Math.sin(Math.PI * Geometry.clampUnit((Math.min(time, plan.splitAt) - plan.hitAt) / pace.wallHold))
    const pressed = Veil.pressOf(plan.size, plan.size / 2 - plan.size * look.press * pressing, look.press)
    const along = pressed.along * burst
    const across = pressed.across * burst
    if (along < 0.5 || across < 0.5)
        return hidden
    const middleX = plan.wallX - plan.side * pressed.distance * burst
    return { x: middleX - along / 2, y: plan.contact.y - across / 2, width: along, height: across, rotation: 0, corner: Math.min(along, across) / 2, isShown: true }
}

function settledAt(path, time, setup) {
    const frame = path.frame
    const look = setup.look
    const pace = setup.pace
    if (time < path.launch)
        return hidden
    if (time >= path.arrival + pace.settle)
        return { x: frame.x, y: frame.y, width: frame.width, height: frame.height, rotation: 0, corner: look.corner, isShown: true }
    if (time < path.arrival) {
        const motion = motionAt(path, time, pace.carry, pace.step)
        const flown = Geometry.clampUnit(motion.share)
        const grown = Math.pow(flown, look.bloom)
        const formWidth = Math.max(1, Geometry.mix(path.birth, frame.width, grown))
        const formHeight = Math.max(1, Geometry.mix(path.birth, frame.height, grown))
        const steering = Geometry.smooth(Geometry.clampUnit((1 - flown) / look.stretchFade))
        const round = (1 - grown) * (1 - grown)
        const speed = Geometry.stretchOf(motion.speed, look.stretchGain, look.stretchLimit) * steering
        const stretch = speed * round
        const directed = directedOf(formWidth, formHeight, speed * (1 - round) * look.bodyStretch, motion.heading)
        return {
            x: motion.x - directed.width * (1 + stretch) / 2,
            y: motion.y - directed.height / (1 + stretch) / 2,
            width: directed.width * (1 + stretch),
            height: directed.height / (1 + stretch),
            rotation: foldedOf(motion.heading) * round,
            corner: Geometry.mix(path.birth / 2, look.corner, grown),
            isShown: true
        }
    }
    const since = time - path.arrival
    const taper = 1 - since / pace.settle
    const ring = Liquid.ring(setup.knock, since / 1000) * taper
    const arriving = unitOf(tangentAt(path.from, path.control, path.to, 1))
    const swell = 1 + look.settleSwell * ring
    const squash = look.settleSquash * ring
    const formWidth = frame.width * swell * (1 - squash * Math.abs(arriving.x) + squash * Math.abs(arriving.y))
    const formHeight = frame.height * swell * (1 + squash * Math.abs(arriving.x) - squash * Math.abs(arriving.y))
    const center = Geometry.centerOf(frame)
    return {
        x: center.x + arriving.x * look.settle * ring - formWidth / 2,
        y: center.y + arriving.y * look.settle * ring - formHeight / 2,
        width: formWidth,
        height: formHeight,
        rotation: 0,
        corner: look.corner,
        isShown: true
    }
}

function enterAt(plan, time, setup) {
    if (time >= plan.total) {
        return {
            drops: plan.converge.flights.map(() => hidden),
            core: hidden,
            bubbles: plan.bubbles.map(() => hidden),
            bodies: plan.splits.map(path => settledAt(path, Infinity, setup)),
            pills: []
        }
    }
    return {
        drops: plan.converge.flights.map(path => dropAt(path, time, setup)),
        core: enterCoreAt(plan, time, setup),
        bubbles: plan.bubbles.map(bubble => bubbleAt(bubble, time, setup.look)),
        bodies: plan.splits.map(path => settledAt(path, time, setup)),
        pills: []
    }
}

function leaveOf(setup, seed) {
    const random = Variation.seeded(seed)
    const look = setup.look
    const pace = setup.pace
    const center = Qt.point(setup.width / 2, setup.height / 2)
    const sources = setup.sources.length > 0 ? setup.sources : [{ x: center.x, y: center.y, width: 0, height: 0 }]
    const converge = convergeOf(sources, center, setup, { stagger: pace.convergeStagger, spread: pace.convergeSpread, flight: pace.convergeFlight, windup: pace.windup, near: pace.near, wobble: pace.wobble, gap: pace.mergeGap }, random, 0)
    const size = sizeOf(converge.hits, Infinity)
    const groups = Veil.groupsOf(setup.groups, setup.width, setup.isMirrored)
    const side = setup.isMirrored ? 1 : -1
    const wallX = wallXOf(setup, false)
    const anchorY = groups.length > 0 ? groups.reduce((total, group) => total + group.anchor.y, 0) / groups.length : center.y
    const isSmashing = setup.isSmashing === true
    const target = Qt.point(wallX - side * (isSmashing ? size : look.drop) / 2, anchorY)
    const core = flightOf(center, target, (random() < 0.5 ? -1 : 1) * Variation.between(random, look.bendLeast, look.bend), converge.done + pace.hold, pace.throwWindup, pace.throwFlight, look.corePull, look.pullLimit)
    if (isSmashing) {
        return {
            kind: "leave",
            isSmashing: true,
            converge: converge,
            size: size,
            gather: center,
            core: core,
            side: side,
            wallX: wallX,
            contact: target,
            hitAt: core.arrival,
            splitAt: Infinity,
            splitPoint: target,
            shots: [],
            bubbles: bubblesOf(random, Qt.point(wallX, target.y), setup.isMirrored ? Math.PI : 0, look.wallCone, core.arrival, look, pace),
            handOff: Infinity,
            arrivals: [],
            total: core.arrival + pace.smash
        }
    }
    const splitAt = core.launch + core.windup + flownAt(look.splitAt, core.pull, pace.carry) * core.flight
    const splitPoint = Geometry.arcAt(core.from, core.control, core.to, look.splitAt)
    const heading = unitOf(tangentAt(core.from, core.control, core.to, look.splitAt))
    const count = groups.reduce((total, group) => total + group.rects.length, 0)
    const shots = groups.map(group => {
        const contact = Qt.point(wallX - side * look.drop / 2, group.anchor.y)
        const reach = Math.hypot(contact.x - splitPoint.x, contact.y - splitPoint.y)
        const control = Qt.point(splitPoint.x + heading.x * reach * look.lead, splitPoint.y + heading.y * reach * look.lead)
        const flight = pace.shot * Variation.around(random, pace.wobble)
        return {
            kind: group.kind,
            rects: group.rects,
            from: splitPoint,
            control: control,
            to: contact,
            launch: splitAt,
            windup: 0,
            flight: flight,
            pull: 0,
            arrival: splitAt + flight,
            size: size * Math.sqrt(group.rects.length / Math.max(1, count))
        }
    })
    const lastHit = shots.reduce((latest, shot) => Math.max(latest, shot.arrival), splitAt)
    const total = shots.length > 0 ? lastHit + pace.wall + pace.handOver : splitAt + pace.pop
    return {
        kind: "leave",
        converge: converge,
        size: size,
        gather: center,
        core: core,
        splitAt: splitAt,
        splitPoint: splitPoint,
        shots: shots,
        bubbles: bubblesOf(random, splitPoint, Math.atan2(heading.y, heading.x), Math.PI, splitAt, look, pace),
        handOff: splitAt,
        arrivals: shots.reduce((all, shot) => all.concat(shot.rects.map(rect => ({ y: rect.y + rect.height / 2, arrival: (shot.arrival + pace.wall - splitAt) / Math.max(1, total - splitAt) }))), []),
        total: total
    }
}

function leaveCoreAt(plan, time, setup) {
    const look = setup.look
    const pace = setup.pace
    const hits = plan.converge.hits
    if (hits.length === 0 || time < hits[0].at)
        return hidden
    const knock = knockAt(hits, time, setup.knock)
    let size = sizeOf(hits, time) * (1 + knock.swell)
    if (time < plan.core.launch)
        return knockedOf(plan.gather.x, plan.gather.y, size, knock, look)
    if (plan.isSmashing && time >= plan.hitAt)
        return smashedAt(plan, time, size, look, pace)
    const motion = motionAt(plan.core, time, pace.carry, pace.step)
    if (time >= plan.splitAt) {
        const popping = Geometry.clampUnit((time - plan.splitAt) / pace.pop)
        if (popping >= 1)
            return hidden
        size *= (1 + (look.popSwell - 1) * Math.sin(Math.PI * popping)) * (1 - popping)
        return { x: motion.x + knock.x - size / 2, y: motion.y + knock.y - size / 2, width: size, height: size, rotation: 0, corner: size / 2, isShown: size > 0.5 }
    }
    return stretchedOf(motion.x + knock.x, motion.y + knock.y, size, motion, look)
}

function smashedAt(plan, time, size, look, pace) {
    const smashed = Geometry.clampUnit((time - plan.hitAt) / pace.smash)
    if (smashed >= 1)
        return hidden
    const pressed = Veil.pressOf(size, size / 2 - size * look.press * Math.min(1, smashed / look.smashSquash), look.press)
    const inside = pressed.distance - (pressed.distance + pressed.along / 2) * smashed * smashed
    const middleX = plan.wallX - plan.side * inside
    return { x: middleX - pressed.along / 2, y: plan.contact.y - pressed.across / 2, width: pressed.along, height: pressed.across, rotation: 0, corner: Math.min(pressed.along, pressed.across) / 2, isShown: true }
}

function shotAt(shot, rect, time, setup) {
    const look = setup.look
    const pace = setup.pace
    if (time < shot.launch)
        return hidden
    if (time < shot.arrival) {
        const motion = motionAt(shot, time, pace.carry, pace.step)
        const grown = Geometry.clampUnit((time - shot.launch) / pace.pop)
        return stretchedOf(motion.x, motion.y, shot.size * Geometry.mix(look.shotBirth, 1, grown), motion, look)
    }
    const since = time - shot.arrival
    const mutation = since >= pace.wall ? 1 : Liquid.rise(setup.snap, since / 1000)
    const squash = look.press * Math.max(0, 1 - mutation)
    const handOver = Geometry.clampUnit((since - pace.wall) / pace.handOver)
    const shrink = 1 - handOver
    if (shrink <= 0)
        return hidden
    const target = Geometry.centerOf(rect)
    const formWidth = Math.max(1, Geometry.mix(shot.size, rect.width, mutation) * (1 - squash) * shrink)
    const formHeight = Math.max(1, Geometry.mix(shot.size, rect.height, mutation) * (1 + squash) * shrink)
    const middleX = Geometry.mix(shot.to.x, target.x, mutation)
    const middleY = Geometry.mix(shot.to.y, target.y, mutation)
    return { x: middleX - formWidth / 2, y: middleY - formHeight / 2, width: formWidth, height: formHeight, rotation: 0, corner: Math.min(formWidth, formHeight) / 2, isShown: true }
}

function leaveAt(plan, time, setup) {
    if (time >= plan.total) {
        return {
            drops: plan.converge.flights.map(() => hidden),
            core: hidden,
            bubbles: plan.bubbles.map(() => hidden),
            bodies: [],
            pills: plan.shots.reduce((all, shot) => all.concat(shot.rects.map(() => hidden)), [])
        }
    }
    const pills = []
    for (const shot of plan.shots) {
        for (const rect of shot.rects)
            pills.push(shotAt(shot, rect, time, setup))
    }
    return {
        drops: plan.converge.flights.map(path => dropAt(path, time, setup)),
        core: leaveCoreAt(plan, time, setup),
        bubbles: plan.bubbles.map(bubble => bubbleAt(bubble, time, setup.look)),
        bodies: [],
        pills: pills
    }
}

function releaseOf(plan, time) {
    if (time < plan.handOff)
        return 0
    return Geometry.clampUnit((time - plan.handOff) / Math.max(1, plan.total - plan.handOff))
}

function formsOf(scene) {
    const forms = []
    for (const list of [scene.drops, scene.bodies, scene.pills, [scene.core]]) {
        for (const form of list ?? []) {
            if (form && form.isShown && form.width > 1 && form.height > 1 && Math.abs(form.rotation) < 1)
                forms.push({ x: form.x, y: form.y, width: form.width, height: form.height, corner: form.corner })
            else if (form && form.isShown && form.width > 1 && form.height > 1)
                forms.push({ x: form.x + form.width / 2 - form.height / 2, y: form.y, width: form.height, height: form.height, corner: form.height / 2 })
        }
    }
    return forms
}
