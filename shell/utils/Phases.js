.pragma library

const idle = "idle"
const preparing = "preparing"
const entering = "entering"
const active = "active"
const exiting = "exiting"
const recovering = "recovering"

const moves = {
    idle: { show: preparing },
    preparing: { prepared: entering, hide: exiting, settle: active },
    entering: { entered: active, hide: exiting, settle: active },
    active: { hide: exiting },
    exiting: { show: recovering, exited: idle, settle: idle },
    recovering: { recovered: entering, hide: exiting, settle: active }
}

function next(phase, event, canRecover) {
    const target = (moves[phase] ?? {})[event] ?? phase
    if (target === recovering && !canRecover)
        return preparing
    return target
}

function isInterruption(phase, event) {
    return phase === exiting && event === "show"
}

function isPresent(phase) {
    return phase !== idle
}

function isMoving(phase) {
    return phase !== idle && phase !== active
}

function isLeaving(phase) {
    return phase === exiting || phase === recovering
}

function isShowing(phase) {
    return phase === preparing || phase === entering || phase === active || phase === recovering
}
