pragma Singleton
import QtQuick
QtObject {
    property string mode: "canvas"
    property bool canConfine: true
    property bool isConfined: false
    property bool canMinimize: false
    property bool canSnap: false
    property var parked: ({})
    function isParked(windowId) { return false }
    function activate(toplevel) {}
    function minimize() {}
    function maximize() {}
    function fullscreen() {}
    function snap(direction) {}
}
