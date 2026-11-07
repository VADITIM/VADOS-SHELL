.pragma library

function delayOf(failures, policy) {
    const steps = Math.max(0, failures - 1)
    return Math.min(policy.cap, policy.base * Math.pow(policy.factor, steps))
}
