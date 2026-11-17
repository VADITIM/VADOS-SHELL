pragma Singleton
import QtQuick
QtObject {
    property var devices: [{ label: "KINGSTON", path: "/dev/sdb", partitions: [] }]
    function eject(device) { devices = devices.filter(candidate => candidate !== device) }
}
