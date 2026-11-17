pragma Singleton
import QtQuick
QtObject {
    property bool isWatching: false
    property var keys: ["performance", "balanced", "power-saver"]
    property string active: "balanced"
    readonly property bool isAvailable: keys.length > 0
    function set(key) { active = key }
}
