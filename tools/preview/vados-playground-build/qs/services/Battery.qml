pragma Singleton
import QtQuick
QtObject {
    property bool isPresent: true
    property real level: 0.62
    property bool isCharging: false
    property real secondsLeft: 7600
    property bool canLimit: true
    property bool isLimited: false
}
