pragma Singleton
import QtQuick
QtObject {
    property bool isActive: false
    property bool isOnDesktop: false
    property bool isOnLock: false
    readonly property bool isPolling: isActive || isOnDesktop || isOnLock
    property bool isReady: true
    property real temperature: 28
    property real rainChance: 0
    property string kind: "partly"
    readonly property int forecastDays: 3
    property var days: [
        { kind: "clear", high: 20 }, { kind: "clear", high: 20 }, { kind: "partly", high: 21 }
    ]
}
