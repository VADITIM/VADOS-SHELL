.pragma library

function frequency(character) {
    return 2 * Math.PI / character.response
}

function stiffness(character) {
    return Math.pow(frequency(character), 2)
}

function friction(character) {
    return 2 * character.damping * frequency(character)
}

function decay(character) {
    return character.damping * frequency(character)
}

function swing(character) {
    return frequency(character) * Math.sqrt(1 - character.damping * character.damping)
}

function lean(character) {
    return decay(character) / swing(character) - character.expansion
}

function rise(character, time) {
    if (time <= 0)
        return 0
    const angle = swing(character) * time
    return 1 - Math.exp(-decay(character) * time) * (Math.cos(angle) + lean(character) * Math.sin(angle))
}

function ring(character, time) {
    if (time <= 0)
        return 0
    return character.expansion * Math.exp(-decay(character) * time) * Math.sin(swing(character) * time)
}

function arrival(character) {
    return Math.atan2(1, -lean(character)) / swing(character)
}

function pull(value, velocity, target, character, frameTime, clock) {
    const springiness = stiffness(character)
    const drag = friction(character)
    let remaining = Math.min(clock.frameCap, frameTime)
    let position = value
    let moving = velocity
    while (remaining > 0) {
        const step = Math.min(remaining, clock.substep)
        moving += (-springiness * (position - target) - drag * moving) * step
        position += moving * step
        remaining -= step
    }
    return { value: position, velocity: moving }
}

function isMerged(wasMerged, closeness, neck) {
    return wasMerged ? closeness > neck.separate : closeness > neck.merge
}

function neckKick(isMerged, neck) {
    return isMerged ? -neck.mergeKick : neck.separateKick
}
