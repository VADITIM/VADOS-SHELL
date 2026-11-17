pragma Singleton
import QtQuick
QtObject {
    property bool isWatching: false
    property var families: ["DejaVu Sans", "Inter", "Noto Sans", "Space Mono"]
    property string applied: ""
    readonly property bool isApplied: applied.length > 0
    property bool isBusy: false
    function refresh() {}
    function apply(family) { applied = family }
    function restore() { applied = "" }
}
