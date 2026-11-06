pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: hardware

    property bool isActive: false

    property real cpuLoad: 0
    property real cpuTemperature: 0
    property string cpuName: ""
    property real memoryUsed: 0
    property real memoryTotal: 0

    property bool hasGpu: false
    property string gpuName: ""
    property real gpuLoad: 0
    property real gpuTemperature: 0
    property real videoMemoryUsed: 0
    property real videoMemoryTotal: 0

    property var disks: []

    property var previousCpu: null

    readonly property var spaces: new RegExp("\\s+", "g")
    readonly property var memoryLine: new RegExp("^(\\w+):\\s+(\\d+)")
    readonly property var cpuNoise: [
        new RegExp("\\((R|TM)\\)", "g"),
        new RegExp("\\s*@.*$"),
        new RegExp("\\s+\\d+-Core", "i"),
        new RegExp("\\s+(Processor|CPU)\\b", "gi")
    ]
    readonly property var vendorPrefix: new RegExp("^NVIDIA\\s+", "i")
    readonly property var bracketed: new RegExp("\\[([^\\]]+)\\]", "g")
    readonly property var watchedMounts: ["/home", "/mnt", "/media", "/run/media", "/data"]

    readonly property string probe: [
        "for hwmon in /sys/class/hwmon/hwmon*; do",
        "  case \"$(cat \"$hwmon/name\" 2>/dev/null)\" in",
        "    k10temp|coretemp|zenpower|cpu_thermal) echo \"cpu_temperature=$(cat \"$hwmon/temp1_input\" 2>/dev/null)\"; break;;",
        "  esac",
        "done",
        "if command -v nvidia-smi >/dev/null 2>&1; then",
        "  echo \"nvidia=$(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits | head -1)\"",
        "else",
        "  for card in /sys/class/drm/card*/device; do",
        "    if [ -r \"$card/gpu_busy_percent\" ]; then",
        "      echo \"amd_load=$(cat \"$card/gpu_busy_percent\")\"",
        "      echo \"amd_vram_used=$(cat \"$card/mem_info_vram_used\" 2>/dev/null)\"",
        "      echo \"amd_vram_total=$(cat \"$card/mem_info_vram_total\" 2>/dev/null)\"",
        "      echo \"amd_temperature=$(cat \"$card\"/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)\"",
        "      echo \"amd_name=$(lspci -s \"$(basename \"$(readlink -f \"$card\")\")\" 2>/dev/null)\"",
        "      break",
        "    fi",
        "  done",
        "fi",
        "df -B1 --output=target,used,size -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs 2>/dev/null | tail -n +2 | sed 's/^/disk=/'"
    ].join("\n")

    function refresh() {
        statFile.reload()
        memoryFile.reload()
        probeQuery.running = true
    }

    function readCpu(text) {
        const fields = text.split("\n")[0].trim().split(spaces).slice(1, 9).map(Number)
        const idle = fields[3] + fields[4]
        const total = fields.reduce((sum, value) => sum + value, 0)
        if (previousCpu) {
            const spent = total - previousCpu.total
            if (spent > 0)
                cpuLoad = Math.max(0, Math.min(1, 1 - (idle - previousCpu.idle) / spent))
        }
        previousCpu = { idle: idle, total: total }
    }

    function readMemory(text) {
        const values = {}
        for (const line of text.split("\n")) {
            const match = line.match(memoryLine)
            if (match)
                values[match[1]] = Number(match[2]) * 1024
        }
        memoryTotal = values.MemTotal ?? 0
        memoryUsed = memoryTotal - (values.MemAvailable ?? memoryTotal)
    }

    function readCpuName(text) {
        const line = text.split("\n").find(candidate => candidate.startsWith("model name"))
        if (!line)
            return
        let name = line.split(":").slice(1).join(":")
        for (const noise of cpuNoise)
            name = name.replace(noise, "")
        cpuName = name.replace(spaces, " ").trim()
    }

    function isWatchedMount(target) {
        return target === "/" || watchedMounts.some(prefix => target.startsWith(prefix))
    }

    function readProbe(text) {
        const values = {}
        const found = []
        const seen = {}
        for (const line of text.split("\n")) {
            const at = line.indexOf("=")
            if (at < 0)
                continue
            const key = line.slice(0, at)
            const value = line.slice(at + 1).trim()
            if (key !== "disk") {
                values[key] = value
                continue
            }
            const parts = value.split(spaces)
            const identity = parts[1] + "|" + parts[2]
            if (parts.length < 3 || !isWatchedMount(parts[0]) || seen[identity])
                continue
            seen[identity] = true
            found.push({ mount: parts[0], used: Number(parts[1]), total: Number(parts[2]) })
        }
        disks = found
        cpuTemperature = Number(values.cpu_temperature || 0) / 1000
        if (values.nvidia) {
            const parts = values.nvidia.split(",").map(part => part.trim())
            hasGpu = true
            gpuName = parts[0].replace(vendorPrefix, "")
            gpuLoad = Number(parts[1]) / 100
            gpuTemperature = Number(parts[2])
            videoMemoryUsed = Number(parts[3]) * 1048576
            videoMemoryTotal = Number(parts[4]) * 1048576
            return
        }
        if (values.amd_load !== undefined) {
            const brackets = (values.amd_name || "").match(bracketed) ?? []
            hasGpu = true
            gpuName = brackets.length > 0 ? brackets[brackets.length - 1].slice(1, -1) : "GPU"
            gpuLoad = Number(values.amd_load) / 100
            gpuTemperature = Number(values.amd_temperature || 0) / 1000
            videoMemoryUsed = Number(values.amd_vram_used || 0)
            videoMemoryTotal = Number(values.amd_vram_total || 0)
            return
        }
        hasGpu = false
    }

    onIsActiveChanged: if (isActive) refresh()

    Timer {
        interval: Motion.dashboard.poll
        running: hardware.isActive
        repeat: true
        onTriggered: hardware.refresh()
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: hardware.readCpu(text())
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        onLoaded: hardware.readMemory(text())
    }

    FileView {
        path: "/proc/cpuinfo"
        onLoaded: hardware.readCpuName(text())
    }

    Process {
        id: probeQuery
        command: ["sh", "-c", hardware.probe]
        stdout: StdioCollector {
            onStreamFinished: hardware.readProbe(text)
        }
    }
}
