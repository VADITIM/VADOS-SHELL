pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    readonly property var device: UPower.displayDevice
    readonly property bool isPresent: device?.isLaptopBattery ?? false
    readonly property real level: {
        const raw = device?.percentage ?? 0
        return raw > 1 ? raw / 100 : raw
    }
    readonly property bool isCharging: device
        ? device.state === UPowerDeviceState.Charging
            || device.state === UPowerDeviceState.FullyCharged
            || device.state === UPowerDeviceState.PendingCharge
        : false
    readonly property real secondsLeft: isCharging ? (device?.timeToFull ?? 0) : (device?.timeToEmpty ?? 0)
}
