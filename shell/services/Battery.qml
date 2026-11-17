pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config
import "../utils/Controls.js" as Controls
import "../utils/Log.js" as Log

Singleton {
    id: battery

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

    property var chargeLimit: null
    readonly property bool canLimit: chargeLimit !== null
    readonly property bool isLimited: chargeLimit?.isLimited ?? false
    readonly property bool shouldLimit: Config.data.battery.limit
    readonly property real cap: isLimited ? chargeLimit.cap : -1

    function apply() {
        if (!canLimit || isLimited === shouldLimit || writer.running)
            return
        if (!chargeLimit.isWritable) {
            Log.warn("battery", chargeLimit.path + " is not writable, the charge limit stays " + (isLimited ? "on" : "off") + "; add the tmpfiles rule from the README")
            return
        }
        writer.command = ["python3", Quickshell.shellPath("scripts/charge-limit.py"), "apply", chargeLimit.path, Controls.chargeLimitValue(chargeLimit.kind, shouldLimit)]
        writer.running = true
    }

    onShouldLimitChanged: apply()
    Component.onCompleted: probe.running = true

    Process {
        id: probe
        command: ["python3", Quickshell.shellPath("scripts/charge-limit.py"), "probe"]
        stdout: StdioCollector {
            onStreamFinished: {
                battery.chargeLimit = Controls.parseChargeLimit(text)
                battery.apply()
            }
        }
    }

    Process {
        id: writer
        onExited: exitCode => {
            if (exitCode !== 0)
                Log.warn("battery", "writing the charge limit exited with code " + exitCode + ", it stays " + (battery.isLimited ? "on" : "off"))
            probe.running = true
        }
    }
}
