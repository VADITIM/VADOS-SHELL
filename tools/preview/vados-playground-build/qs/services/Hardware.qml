pragma Singleton
import QtQuick
QtObject {
    property bool isActive: false
    property bool isOnDesktop: false
    property bool isOnLock: false
    readonly property bool isPolling: isActive || isOnDesktop || isOnLock
    property real cpuLoad: 0.3
    property real cpuTemperature: 40
    property string cpuName: "Ryzen 7 5800X"
    property real memoryUsed: 22 * 1073741824
    property real memoryTotal: 32 * 1073741824
    property bool hasGpu: true
    property string gpuName: "GeForce RTX 3080"
    property real gpuLoad: 0.7
    property real gpuTemperature: 75
    property real videoMemoryUsed: 7.4 * 1073741824
    property real videoMemoryTotal: 10 * 1073741824
    property var disks: [
        { mount: "/", used: 412 * 1073741824, total: 931 * 1073741824 },
        { mount: "/home", used: 1520 * 1073741824, total: 1863 * 1073741824 },
        { mount: "/mnt/games", used: 1940 * 1073741824, total: 2000 * 1073741824 }
    ]
    property Timer drift: Timer {
        interval: 1500; running: true; repeat: true
        onTriggered: {
            cpuLoad = Math.max(0.05, Math.min(0.98, cpuLoad + (Math.random() - 0.5) * 0.12))
            gpuLoad = Math.max(0.05, Math.min(0.98, gpuLoad + (Math.random() - 0.5) * 0.12))
        }
    }
}
