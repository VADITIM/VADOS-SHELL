pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Boot.js" as BootPlan
import "../utils/Log.js" as Log

Singleton {
    id: boot

    property bool isWatching: false
    property var current: null
    property string problem: ""
    readonly property bool isKnown: current !== null
    readonly property bool canSplash: isKnown && current.hasRenderer === true && BootPlan.canSplash(current)
    readonly property bool canPlymouth: isKnown && current.hasRenderer === true && BootPlan.canPlymouth(current)
    readonly property bool needsPlymouth: canSplash && current.hasPlymouth !== true
    readonly property bool isSplashOn: isKnown && BootPlan.isSplashOn(current.presets)
    readonly property bool isPlymouthOn: isKnown && BootPlan.isPlymouthOn(current)
    readonly property bool isBusy: worker.running

    signal applied(bool isSplash, bool isPlymouth)

    function refresh() {
        reader.running = true
    }

    function request(part, isOn, accent) {
        if (isBusy || !isKnown || (part === "splash" && !canSplash) || (part === "plymouth" && !canPlymouth))
            return
        const wanted = {
            splash: part === "splash" ? isOn : isSplashOn,
            plymouth: part === "plymouth" ? isOn : isPlymouthOn
        }
        const planned = BootPlan.plan(current, store.values, wanted)
        worker.begin(wanted, planned, accent)
    }

    onIsWatchingChanged: {
        if (isWatching)
            refresh()
    }

    StateFile {
        id: store
        name: "boot"
        defaults: BootPlan.emptyRecord()
    }

    Process {
        id: reader
        command: ["python3", Quickshell.shellPath("scripts/boot.py"), "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    boot.current = JSON.parse(text)
                } catch (error) {
                    Log.warn("boot", "boot.py status gave no readable answer; the boot options stay hidden")
                }
            }
        }
    }

    Process {
        id: worker

        property var wanted: ({})
        property var planned: ({})
        property string payload: ""

        function begin(nextWanted, nextPlanned, accent) {
            wanted = nextWanted
            planned = nextPlanned
            payload = JSON.stringify({
                accent: accent,
                splash: nextWanted.splash,
                plymouth: nextWanted.plymouth,
                files: nextPlanned.files,
                images: nextPlanned.images
            })
            boot.problem = ""
            stdinEnabled = true
            running = true
        }

        command: ["pkexec", "/usr/bin/python3", Quickshell.shellPath("scripts/boot.py"), "apply"]
        onStarted: {
            write(payload)
            stdinEnabled = false
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    Log.warn("boot", text.trim().split("\n").join("; "))
            }
        }
        onExited: code => {
            if (code === 0) {
                store.update(worker.planned.record)
                store.flush()
                boot.applied(worker.wanted.splash, worker.wanted.plymouth)
            } else {
                boot.problem = code === 126 ? "cancelled" : code === 127 ? "agent" : "failed"
                Log.warn("boot", `boot.py apply exited with code ${code}; the boot setup is unchanged`)
            }
            boot.refresh()
        }
    }
}
