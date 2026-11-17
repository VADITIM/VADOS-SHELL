pragma Singleton
import QtQuick
QtObject {
    property bool isEnabled: true
    property bool isWired: false
    property string ssid: "VADOS-NET"
    property real strength: 0.8
    property bool isWatching: false
    property var networks: [{ ssid: "VADOS-NET", strength: 0.8, isSecured: true, isActive: true }, { ssid: "Cafe Free", strength: 0.5, isSecured: false, isActive: false }]
    property var known: ["VADOS-NET"]
    property var prompt: null
    property string joining: ""
    property string joinResult: ""
    readonly property bool isJoining: joining.length > 0
    readonly property string joinMessage: joinResult === "wrong" ? "WRONG PASSWORD" : joinResult === "missing" ? "NETWORK NOT FOUND" : joinResult === "error" ? "COULD NOT CONNECT" : ""
    readonly property bool isConnected: isEnabled && ssid.length > 0
    function connectTo(name, isHidden) {
        const entry = networks.find(candidate => candidate.ssid === name)
        joinResult = ""
        if (entry && !entry.isSecured || known.indexOf(name) >= 0) { ssid = name; return }
        joining = name
        prompt = { ssid: name, ask: "passphrase" }
    }
    function answer(values) {
        prompt = null
        if (values[0] === "wrong") { joinResult = "wrong"; prompt = { ssid: joining, ask: "passphrase" }; return }
        ssid = joining
        known = known.concat([joining])
        joining = ""
        joinResult = "connected"
    }
    function cancelJoin() { prompt = null; joining = ""; joinResult = "" }
    function settleJoin() { if (prompt !== null) cancelJoin(); else joinResult = "" }
    function forget(name) { known = known.filter(candidate => candidate !== name) }
    function toggle() { isEnabled = !isEnabled }
}
