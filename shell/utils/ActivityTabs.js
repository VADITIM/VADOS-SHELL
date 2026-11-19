.pragma library

function stepFrom(order, lead, direction) {
    if (order.length === 0)
        return lead
    const at = order.indexOf(lead)
    if (at < 0)
        return order[direction > 0 ? 0 : order.length - 1]
    return order[Math.max(0, Math.min(order.length - 1, at + direction))]
}

function slotOf(tabs, lead, key) {
    const at = tabs.indexOf(lead)
    const index = tabs.indexOf(key)
    return at < 0 ? index + 1 : index - at
}

function distanceOf(slot, base, pitch) {
    const reach = Math.abs(slot)
    const distance = reach < 1 ? reach * base : base + (reach - 1) * pitch
    return slot < 0 ? -distance : distance
}

function spanOf(tabs, lead) {
    const at = tabs.indexOf(lead)
    return { above: Math.max(0, at), below: at < 0 ? tabs.length : tabs.length - 1 - at }
}
