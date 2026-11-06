pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: state

    readonly property var modes: ["hidden", "idle", "active", "expanded"]
    property string mode: "idle"
    property string screenName: ""
    property string lead: ""
    readonly property bool isAnyLive: Activities.isAnyLive
    readonly property string leadKey: Activities.order.includes(lead) ? lead : Activities.order[0] ?? "media"

    onIsAnyLiveChanged: {
        lead = ""
        if (isAnyLive && mode === "idle")
            mode = "active"
        else if (!isAnyLive && (mode === "active" || mode === "expanded"))
            mode = "idle"
    }

    function modeOn(name) {
        return mode === "expanded" && screenName !== name ? "active" : mode
    }

    function set(name, wanted) {
        if (modes.indexOf(wanted) < 0)
            return
        if (wanted === "expanded")
            screenName = name
        mode = wanted
    }

    function step(name, direction) {
        const at = modes.indexOf(modeOn(name))
        set(name, modes[Math.max(0, Math.min(modes.length - 1, at + direction))])
    }

    function rotate(direction) {
        const order = Activities.order
        if (order.length < 2)
            return
        const at = Math.max(0, order.indexOf(leadKey))
        lead = order[(at + direction + order.length) % order.length]
    }
}
