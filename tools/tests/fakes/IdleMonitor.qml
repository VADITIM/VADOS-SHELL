import QtQuick

QtObject {
    id: monitor

    property bool enabled: true
    property real timeout: 0
    property bool respectInhibitors: true
    property bool isIdle: false

    readonly property Timer quiet: Timer {
        interval: Math.max(1, monitor.timeout * 1000)
        running: monitor.enabled && monitor.timeout > 0 && !monitor.isIdle
        onTriggered: monitor.isIdle = true
    }

    function touch() {
        isIdle = false
    }

    onEnabledChanged: if (!enabled) isIdle = false
}
