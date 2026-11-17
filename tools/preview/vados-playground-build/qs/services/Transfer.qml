pragma Singleton
import QtQuick
QtObject {
    property var installed: ["blip"]
    property bool isPicking: false
    property string appKey: "blip"
    property string appName: "BLIP"
    property bool isAvailable: true
    property var devices: [{ name: "Phone", peer: "pixel" }, { name: "Laptop", peer: "work" }, { name: "Tablet", peer: "tab" }]
    property var sent: []
    function nextApp() { return appKey }
    function send(peer) { sent = sent.concat([peer]) }
}
