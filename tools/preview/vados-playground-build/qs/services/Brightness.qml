pragma Singleton
import QtQuick
QtObject {
    property bool isWatching: false
    property bool isAvailable: true
    property real level: 0.6
    function setLevel(value) { level = Math.max(0.01, Math.min(1, value)) }
}
