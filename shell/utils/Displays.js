.pragma library
.import "Toml.js" as Toml

const transforms = ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
const rotations = ["normal", "90", "180", "270"]
const scales = [1, 1.25, 1.5, 1.75, 2]
const lowestScale = 0.5
const highestScale = 4

function hertzOf(refresh) {
    return Math.round(refresh / 1000)
}

function roundedScale(scale) {
    return Math.round(scale * 100) / 100
}

function transformName(index) {
    return transforms[index] ?? "normal"
}

function isTurned(transform) {
    return ["90", "270", "flipped-90", "flipped-270"].indexOf(transform) >= 0
}

function isLit(output) {
    return output.isEnabled !== false
}

function litOf(layout) {
    return layout.filter(isLit)
}

function isSameMode(first, second) {
    return first.width === second.width && first.height === second.height && hertzOf(first.refresh) === hertzOf(second.refresh)
}

function distinctModes(modes) {
    const result = []
    for (const mode of modes) {
        if (!(mode.width > 0 && mode.height > 0))
            continue
        const known = result.find(entry => isSameMode(entry, mode))
        if (known)
            known.isPreferred = known.isPreferred || mode.isPreferred
        else
            result.push({ width: mode.width, height: mode.height, refresh: hertzOf(mode.refresh) * 1000, isPreferred: mode.isPreferred === true })
    }
    return result.sort((first, second) => second.width * second.height - first.width * first.height || second.refresh - first.refresh)
}

function fromHeads(answer) {
    const heads = answer && Array.isArray(answer.heads) ? answer.heads : []
    return heads.filter(head => typeof head.name === "string" && head.name.length > 0).map(head => {
        const listed = (head.modes ?? []).map(mode => ({ width: mode.width, height: mode.height, refresh: mode.refresh, isPreferred: mode.preferred === true }))
        const modes = distinctModes(listed)
        const current = listed[head.current] ?? modes.find(mode => mode.isPreferred) ?? modes[0] ?? { width: 0, height: 0, refresh: 0 }
        return {
            isEnabled: head.enabled !== false,
            name: head.name,
            description: head.description ?? "",
            make: head.make ?? "",
            model: head.model ?? "",
            x: Math.round(head.x ?? 0),
            y: Math.round(head.y ?? 0),
            scale: roundedScale(head.scale ?? 1),
            transform: transformName(head.transform ?? 0),
            mode: { width: current.width, height: current.height, refresh: hertzOf(current.refresh) * 1000 },
            modes: modes
        }
    })
}

function hyprlandMode(text) {
    const parts = String(text).split("@")
    const size = parts[0].split("x").map(Number)
    const refresh = Math.round(parseFloat(parts[1] ?? "60") * 1000)
    if (size.length !== 2 || !(size[0] > 0 && size[1] > 0) || !(refresh > 0))
        return null
    return { width: size[0], height: size[1], refresh: refresh, isPreferred: false }
}

function fromHyprland(monitors) {
    const list = Array.isArray(monitors) ? monitors : []
    return list.filter(monitor => typeof monitor.name === "string").map(monitor => ({
        isEnabled: monitor.disabled !== true,
        name: monitor.name,
        description: monitor.description ?? "",
        make: monitor.make ?? "",
        model: monitor.model ?? "",
        x: Math.round(monitor.x ?? 0),
        y: Math.round(monitor.y ?? 0),
        scale: roundedScale(monitor.scale ?? 1),
        transform: transformName(monitor.transform ?? 0),
        mode: { width: monitor.width ?? 0, height: monitor.height ?? 0, refresh: hertzOf((monitor.refreshRate ?? 60) * 1000) * 1000 },
        modes: distinctModes((monitor.availableModes ?? []).map(hyprlandMode).filter(mode => mode !== null))
    }))
}

function sizeOf(output) {
    const width = Math.round(output.mode.width / output.scale)
    const height = Math.round(output.mode.height / output.scale)
    return isTurned(output.transform) ? { width: height, height: width } : { width: width, height: height }
}

function rectOf(output) {
    const size = sizeOf(output)
    return { name: output.name, x: output.x, y: output.y, width: size.width, height: size.height }
}

function boundsOf(layout) {
    const lit = litOf(layout)
    if (lit.length === 0)
        return { x: 0, y: 0, width: 0, height: 0 }
    const rects = lit.map(rectOf)
    const left = Math.min(...rects.map(rect => rect.x))
    const top = Math.min(...rects.map(rect => rect.y))
    const right = Math.max(...rects.map(rect => rect.x + rect.width))
    const bottom = Math.max(...rects.map(rect => rect.y + rect.height))
    return { x: left, y: top, width: right - left, height: bottom - top }
}

function spanOf(first, second) {
    return {
        horizontal: Math.min(first.x + first.width, second.x + second.width) - Math.max(first.x, second.x),
        vertical: Math.min(first.y + first.height, second.y + second.height) - Math.max(first.y, second.y)
    }
}

function overlapOf(first, second) {
    const span = spanOf(first, second)
    return Math.max(0, span.horizontal) * Math.max(0, span.vertical)
}

function isTouching(first, second) {
    const span = spanOf(first, second)
    return (span.horizontal === 0 && span.vertical > 0) || (span.vertical === 0 && span.horizontal > 0)
}

function isConnected(layout) {
    if (layout.length <= 1)
        return true
    const rects = layout.map(rectOf)
    const reached = [rects[0]]
    const waiting = [rects[0]]
    while (waiting.length > 0) {
        const current = waiting.pop()
        for (const rect of rects) {
            if (reached.indexOf(rect) < 0 && isTouching(current, rect)) {
                reached.push(rect)
                waiting.push(rect)
            }
        }
    }
    return reached.length === rects.length
}

function problemOf(requested) {
    const layout = Array.from(requested ?? [])
    if (layout.length === 0)
        return "empty"
    const names = layout.map(output => output.name)
    if (new Set(names).size !== names.length)
        return "duplicate"
    const lit = litOf(layout)
    if (lit.length === 0)
        return "dark"
    for (const output of lit) {
        if (!output.mode || !Number.isInteger(output.mode.width) || !Number.isInteger(output.mode.height) || output.mode.width <= 0 || output.mode.height <= 0 || !(output.mode.refresh > 0))
            return "mode"
        if (!(output.scale >= lowestScale && output.scale <= highestScale))
            return "scale"
        if (transforms.indexOf(output.transform) < 0)
            return "transform"
        if (!Number.isInteger(output.x) || !Number.isInteger(output.y))
            return "position"
    }
    const rects = lit.map(rectOf)
    for (let first = 0; first < rects.length; first++) {
        for (let second = first + 1; second < rects.length; second++) {
            if (overlapOf(rects[first], rects[second]) > 0)
                return "overlap"
        }
    }
    return isConnected(lit) ? "" : "gap"
}

function withOutput(layout, name, changes) {
    return layout.map(output => output.name === name ? Object.assign({}, output, changes) : output)
}

function onGrid(position, grid) {
    return grid > 0 ? Math.round(position / grid) * grid : position
}

function alignedOn(position, length, start, span, reach, grid) {
    let value = Math.max(start - length + 1, Math.min(start + span - 1, onGrid(position, grid)))
    let nearest = reach
    for (const target of [start, start + span - length, start + (span - length) / 2]) {
        const distance = Math.abs(position - target)
        if (distance <= nearest) {
            nearest = distance
            value = target
        }
    }
    return Math.round(value)
}

function snapped(layout, name, x, y, reach, grid) {
    const moving = layout.find(output => output.name === name)
    if (!moving || !isLit(moving))
        return layout
    const size = sizeOf(moving)
    const others = litOf(layout).filter(output => output.name !== name).map(rectOf)
    if (others.length === 0)
        return withOutput(layout, name, { x: 0, y: 0 })
    const candidates = []
    for (const other of others) {
        const slideX = alignedOn(x, size.width, other.x, other.width, reach, grid)
        const slideY = alignedOn(y, size.height, other.y, other.height, reach, grid)
        candidates.push({ x: other.x + other.width, y: slideY }, { x: other.x - size.width, y: slideY }, { x: slideX, y: other.y + other.height }, { x: slideX, y: other.y - size.height })
    }
    const free = candidates.filter(candidate => others.every(other => overlapOf({ x: candidate.x, y: candidate.y, width: size.width, height: size.height }, other) === 0))
    if (free.length === 0)
        return layout
    const best = free.reduce((found, candidate) => Math.hypot(candidate.x - x, candidate.y - y) < Math.hypot(found.x - x, found.y - y) ? candidate : found)
    return withOutput(layout, name, { x: Math.round(best.x), y: Math.round(best.y) })
}

function switched(layout, name, isEnabled, reach) {
    const output = layout.find(entry => entry.name === name)
    if (!output || isLit(output) === isEnabled)
        return layout
    if (!isEnabled)
        return withOutput(layout, name, { isEnabled: false })
    const bounds = boundsOf(layout)
    const lit = withOutput(layout, name, { isEnabled: true, x: bounds.x + bounds.width, y: bounds.y })
    return snapped(lit, name, bounds.x + bounds.width, bounds.y, reach)
}

function settled(layout, name, reach) {
    const output = layout.find(entry => entry.name === name)
    return output ? snapped(layout, name, output.x, output.y, reach) : layout
}

function normalized(layout) {
    return layout.map(output => ({
        name: output.name,
        isEnabled: isLit(output),
        mode: { width: output.mode.width, height: output.mode.height, refresh: output.mode.refresh },
        x: Math.round(output.x),
        y: Math.round(output.y),
        scale: roundedScale(output.scale),
        transform: output.transform
    }))
}

function anchored(layout, reference) {
    const bounds = boundsOf(layout)
    const anchor = boundsOf(reference)
    return normalized(layout).map(output => Object.assign(output, { x: output.x - bounds.x + anchor.x, y: output.y - bounds.y + anchor.y }))
}

function isSameLayout(first, second) {
    if (first.length !== second.length)
        return false
    return first.every(output => {
        const other = second.find(entry => entry.name === output.name)
        if (other === undefined || isLit(output) !== isLit(other))
            return false
        if (!isLit(output))
            return true
        return isSameMode(output.mode, other.mode) && output.x === other.x && output.y === other.y && roundedScale(output.scale) === roundedScale(other.scale) && output.transform === other.transform
    })
}

function resolutionsOf(output) {
    const result = []
    for (const mode of output.modes ?? []) {
        if (!result.some(entry => entry.width === mode.width && entry.height === mode.height))
            result.push({ width: mode.width, height: mode.height })
    }
    return result
}

function refreshesOf(output, width, height) {
    const result = []
    for (const mode of output.modes ?? []) {
        if (mode.width === width && mode.height === height && result.indexOf(hertzOf(mode.refresh)) < 0)
            result.push(hertzOf(mode.refresh))
    }
    return result.sort((first, second) => second - first)
}

function modeFor(output, width, height, hertz) {
    const fitting = (output.modes ?? []).filter(mode => mode.width === width && mode.height === height)
    const exact = fitting.find(mode => hertzOf(mode.refresh) === hertz)
    const chosen = exact ?? fitting.reduce((found, mode) => found === null || mode.refresh > found.refresh ? mode : found, null)
    return chosen ? { width: chosen.width, height: chosen.height, refresh: hertzOf(chosen.refresh) * 1000 } : output.mode
}

function modeText(mode) {
    return mode.width + "x" + mode.height + "@" + hertzOf(mode.refresh)
}

function driftwmEntries(output) {
    if (!isLit(output))
        return { enabled: false }
    return { enabled: null, scale: roundedScale(output.scale), transform: output.transform, position: [output.x, output.y], mode: modeText(output.mode) }
}

function driftwmText(text, layout) {
    return layout.reduce((written, output) => Toml.withEntry(written, "outputs", "name", output.name, driftwmEntries(output)), text)
}

function hyprlandRule(output) {
    if (!isLit(output))
        return output.name + ",disable"
    return [output.name, output.mode.width + "x" + output.mode.height + "@" + (output.mode.refresh / 1000).toFixed(2), output.x + "x" + output.y, String(roundedScale(output.scale)), "transform", String(Math.max(0, transforms.indexOf(output.transform)))].join(",")
}

function hyprlandBatch(layout) {
    return layout.map(output => "keyword monitor " + hyprlandRule(output)).join(" ; ")
}

function hyprlandConfig(layout) {
    return layout.map(output => "monitor = " + hyprlandRule(output)).join("\n") + "\n"
}

function idle() {
    return { phase: "idle", deadline: 0, previous: [], applied: [], before: "", written: "" }
}

function begun(trial, previous, applied, now, duration, before, written) {
    const isTrying = trial.phase === "trying"
    return {
        phase: "trying",
        deadline: now + duration,
        previous: isTrying ? trial.previous : previous,
        applied: applied,
        before: isTrying ? trial.before : before,
        written: written
    }
}

function remaining(trial, now) {
    return trial.phase === "trying" ? Math.max(0, trial.deadline - now) : 0
}

function isExpired(trial, now) {
    return trial.phase === "trying" && now >= trial.deadline
}

function isTrial(value) {
    return value !== null && typeof value === "object" && (value.phase === "idle" || value.phase === "trying") && typeof value.deadline === "number" && Array.isArray(value.previous) && Array.isArray(value.applied) && typeof value.before === "string" && typeof value.written === "string"
}

function recovery(stored, now) {
    if (!isTrial(stored) || stored.phase !== "trying")
        return "none"
    return now >= stored.deadline ? "revert" : "resume"
}

function revertText(current, trial) {
    if (trial.written.length > 0 && current === trial.written)
        return trial.before
    return driftwmText(current, trial.previous)
}
