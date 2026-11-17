pragma Singleton
import QtQuick
QtObject {
    property bool isActive: false
    readonly property var names: ["firefox", "code", "quickshell", "driftwm", "pipewire", "discord", "spotify", "kitty", "python3", "systemd", "Xwayland", "steamwebhelper", "wireplumber", "nautilus"]
    property var groups: names.map((name, index) => ({ key: name, name: name, path: "/usr/bin/" + name, pids: [1000 + index], cpu: Math.random() * 0.08, memory: (40 + Math.random() * 900) * 1048576, disk: Math.random() * 2e6, network: -1 }))
    property var history: ({})
    readonly property var historyRows: names.map((name, index) => ({ key: name, name: name, path: "/usr/bin/" + name, pids: [], cpuTime: 30 + index * 517, memory: (200 + index * 90) * 1048576, disk: index * 3.4e8, network: -1 }))
    readonly property real diskRate: groups.reduce((total, row) => total + row.disk, 0)
    property var acted: []
    function kill(row) { acted = acted.concat(["kill " + row.name]); groups = groups.filter(candidate => candidate.key !== row.key) }
    function open(row) { acted = acted.concat(["open " + row.name]) }
    function find(row) { acted = acted.concat(["find " + row.path]) }
    property Timer drift: Timer {
        interval: 1500; running: true; repeat: true
        onTriggered: groups = groups.map(row => Object.assign({}, row, { cpu: Math.max(0, Math.min(0.5, row.cpu + (Math.random() - 0.5) * 0.04)), disk: Math.random() * 2e6 }))
    }
}
