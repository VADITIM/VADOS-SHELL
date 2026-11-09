import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Geometry.js" as Geometry

FocusScope {
    id: dashboard

    property bool isOpen: false
    property bool isMirrored: false
    property var parts: []
    property bool canHandOff: false
    property bool isHandingOver: false
    property bool hasCircle: false
    readonly property bool isPresent: isOpen || burst.isActive || rising.living > 0
    readonly property string phase: burst.phase

    property real dim: isOpen ? 1 : 0
    property int diskPage: 0
    readonly property bool isContentShown: burst.isOpened
    readonly property var visitor: burst.visitor

    readonly property var look: Appearance.dashboard
    readonly property real rootX: Appearance.taskbar.margin
    readonly property real bodyTop: Math.round((height - look.height) / 2)
    readonly property real centerY: bodyTop + look.height / 2
    readonly property real memoryShare: Hardware.memoryTotal > 0 ? Hardware.memoryUsed / Hardware.memoryTotal : 0
    readonly property var disk: Hardware.disks.length > 0 ? Hardware.disks[Math.min(diskPage, Hardware.disks.length - 1)] : null

    signal closeRequested()
    signal landed()

    function heatColor(temperature, isKnown) {
        return isKnown ? Appearance.bandColor(temperature, look.temperatureBands) : Appearance.color.textMuted
    }

    function heatShare(temperature, isKnown) {
        return isKnown ? temperature / look.temperatureScale : 0
    }

    function usageColor(share, isKnown) {
        return isKnown ? Appearance.bandColor(share, look.usageBands) : Appearance.color.textMuted
    }

    function percentText(share, isKnown) {
        return isKnown ? Math.round(share * 100) + "%" : "--%"
    }

    function temperatureText(temperature, isKnown) {
        return isKnown && temperature > 0 ? Math.round(temperature) + "°C" : "--°C"
    }

    function gigabytes(bytes) {
        return String(Math.round(bytes / 1073741824))
    }

    function placeX(localX, itemWidth) {
        return isMirrored ? width - rootX - localX - itemWidth : rootX + localX
    }

    function revealDelay(localX) {
        return Math.round(localX * Motion.dashboard.reveal)
    }

    onIsOpenChanged: if (isOpen) forceActiveFocus()

    Behavior on dim {
        NumberAnimation {
            duration: Motion.pace(dashboard.isOpen ? Motion.dashboard.dim : Motion.dashboard.dimOut)
            easing.type: dashboard.isOpen ? Easing.OutQuad : Easing.InQuad
        }
    }

    Keys.onEscapePressed: closeRequested()

    Rectangle {
        anchors.fill: parent
        color: Appearance.color.shadow
        opacity: dashboard.dim * dashboard.look.dim
    }

    MouseArea {
        anchors.fill: parent
        enabled: dashboard.isOpen
        onClicked: dashboard.closeRequested()
    }

    MouseArea {
        x: dashboard.placeX(0, dashboard.look.width)
        y: dashboard.bodyTop
        width: dashboard.look.width
        height: dashboard.look.height
        enabled: dashboard.isOpen
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: burst.isActive
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: dashboard.look.melt

        Item {
            parent: liquid.shapes
            anchors.fill: parent
            transform: Upright {
                isMirrored: dashboard.isMirrored
                axis: liquid.width / 2
            }

            Burst {
                id: burst
                label: "dashboard burst"
                isShown: dashboard.isOpen
                parts: dashboard.parts
                rootX: dashboard.rootX
                seedX: dashboard.rootX + Appearance.taskbar.thickness / 2
                seedY: dashboard.centerY
                formWidth: dashboard.look.width
                formHeight: dashboard.look.height
                leftCorner: dashboard.look.rootCorner
                rightCorner: dashboard.look.corner
                edgePad: dashboard.look.melt
                screenHeight: dashboard.height
                canHandOff: dashboard.canHandOff
                isHandingOver: dashboard.isHandingOver
                hasCircle: dashboard.hasCircle
                hasSideStep: Battery.isPresent
                onLanded: dashboard.landed()
            }

            Rising {
                id: rising
                anchors.fill: parent
                isRunning: burst.isOpened
                fromX: burst.form.x - burst.form.width / 2 + dashboard.look.rootCorner
                toX: burst.form.x + burst.form.width / 2 - dashboard.look.corner * 0.6
                ceiling: burst.form.y - burst.form.height / 2
                floor: burst.form.y + burst.form.height / 2
            }
        }
    }

    Item {
        id: bodyClip

        readonly property real formLeft: burst.form.x - burst.form.width / 2

        x: dashboard.isMirrored ? dashboard.width - formLeft - width : formLeft
        y: burst.form.y - burst.form.height / 2
        width: Math.max(0, burst.form.width)
        height: Math.max(0, burst.form.height)
        opacity: burst.isLeaving ? 1 - Geometry.smooth(Geometry.clampUnit(burst.exit / Motion.burst.leaveFade)) : 1
        clip: true

        Item {
            id: content
            x: -bodyClip.x
            y: -bodyClip.y
            width: dashboard.width
            height: dashboard.height

            Gauge {
                x: dashboard.placeX(dashboard.look.graphicsX, width)
                y: dashboard.bodyTop + dashboard.look.top
                name: Hardware.hasGpu ? Hardware.gpuName : "NO GPU"
                chipName: "gpu"
                ringShare: dashboard.heatShare(Hardware.gpuTemperature, Hardware.hasGpu)
                ringColor: dashboard.heatColor(Hardware.gpuTemperature, Hardware.hasGpu)
                glyphColor: dashboard.usageColor(Hardware.gpuLoad, Hardware.hasGpu)
                centerText: dashboard.percentText(Hardware.gpuLoad, Hardware.hasGpu)
                caption: dashboard.temperatureText(Hardware.gpuTemperature, Hardware.hasGpu)
                captionColor: dashboard.heatColor(Hardware.gpuTemperature, Hardware.hasGpu)
                hasBar: true
                barUsed: Hardware.videoMemoryUsed
                barTotal: Hardware.videoMemoryTotal
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.graphicsX)
            }

            Gauge {
                x: dashboard.placeX(dashboard.look.processorX, width)
                y: dashboard.bodyTop + dashboard.look.top
                name: Hardware.cpuName || "CPU"
                chipName: "cpu"
                ringShare: dashboard.heatShare(Hardware.cpuTemperature, true)
                ringColor: dashboard.heatColor(Hardware.cpuTemperature, true)
                glyphColor: dashboard.usageColor(Hardware.cpuLoad, true)
                centerText: dashboard.percentText(Hardware.cpuLoad, true)
                caption: dashboard.temperatureText(Hardware.cpuTemperature, true)
                captionColor: dashboard.heatColor(Hardware.cpuTemperature, true)
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.processorX) + Motion.pill.elementStagger
            }

            Gauge {
                x: dashboard.placeX(dashboard.look.memoryX, width)
                y: dashboard.bodyTop + dashboard.look.top + dashboard.look.gauge.blockHeight + dashboard.look.gauge.blockGap
                chipName: "ram"
                ringShare: dashboard.memoryShare
                ringColor: dashboard.usageColor(dashboard.memoryShare, true)
                glyphColor: dashboard.usageColor(dashboard.memoryShare, true)
                centerText: "RAM"
                caption: dashboard.gigabytes(Hardware.memoryUsed) + "GB/" + dashboard.gigabytes(Hardware.memoryTotal) + "GB"
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.memoryX) + Motion.pill.elementStagger * 2
            }

            Throughput {
                readonly property real fromTop: dashboard.look.top + dashboard.look.gauge.blockHeight * 2 + dashboard.look.gauge.blockGap + dashboard.look.traffic.gap

                x: dashboard.placeX(dashboard.look.graphicsX, width)
                y: dashboard.bodyTop + fromTop
                width: dashboard.look.dividerX - dashboard.look.graphicsX - dashboard.look.traffic.dividerGap
                height: dashboard.look.height - fromTop - dashboard.look.traffic.inset
                download: Traffic.download
                upload: Traffic.upload
                downloads: Traffic.downloads
                uploads: Traffic.uploads
                ping: Traffic.ping
                jitter: Traffic.jitter
                hasPing: Traffic.hasPing
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.graphicsX) + Motion.pill.elementStagger * 3
            }

            Item {
                x: dashboard.placeX(dashboard.look.dividerX, 1)
                y: dashboard.bodyTop + dashboard.look.dividerInset
                width: 1
                height: dashboard.look.height - dashboard.look.dividerInset * 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: parent.height * divider.presence
                    color: Appearance.color.hairline
                }

                Turn {
                    id: divider
                    isShown: dashboard.isContentShown
                    enterDelay: dashboard.revealDelay(dashboard.look.dividerX)
                    enterDuration: Motion.dashboard.level
                    enterEasing: Easing.OutCubic
                }
            }

            Forecast {
                x: dashboard.placeX(dashboard.look.weatherX, width)
                y: dashboard.bodyTop + dashboard.look.top
                width: dashboard.look.weatherWidth
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.weatherX)
                stagger: Motion.pill.elementStagger
            }

            Vacant {
                x: dashboard.placeX(dashboard.look.weatherX, width)
                y: dashboard.bodyTop + dashboard.look.top + dashboard.look.weather.vacantY
                width: dashboard.look.weatherWidth
                height: dashboard.look.weather.vacantHeight
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.weatherX) + Motion.pill.elementStagger * 3
            }
        }
    }
    Item {
        id: notchClip

        readonly property var step: burst.bottomStep

        visible: burst.isStepped
        x: dashboard.isMirrored ? dashboard.width - step.x - width : step.x
        y: step.y
        width: Math.max(0, step.width)
        height: Math.max(0, step.height)
        clip: true

        MouseArea {
            anchors.fill: parent
            enabled: dashboard.isOpen
        }

        Item {
            x: -notchClip.x
            y: -notchClip.y
            width: dashboard.width
            height: dashboard.height

            Drive {
                x: dashboard.placeX(dashboard.look.graphicsX, width)
                y: dashboard.bodyTop + dashboard.look.height + dashboard.look.drive.inset
                label: dashboard.disk ? "DISK " + dashboard.disk.mount : "DISK"
                used: dashboard.disk?.used ?? 0
                total: dashboard.disk?.total ?? 0
                pageCount: Hardware.disks.length
                page: dashboard.diskPage
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.graphicsX) + Motion.pill.elementStagger * 3
                onPaged: dashboard.diskPage = (dashboard.diskPage + 1) % Hardware.disks.length
            }
        }
    }
    Item {
        id: sideClip

        readonly property var step: burst.sideStep

        visible: Battery.isPresent && burst.isStepped
        x: dashboard.isMirrored ? dashboard.width - step.x - width : step.x
        y: step.y
        width: Math.max(0, step.width)
        height: Math.max(0, step.height)
        clip: true

        MouseArea {
            anchors.fill: parent
            enabled: dashboard.isOpen
        }

        Item {
            x: -sideClip.x
            y: -sideClip.y
            width: dashboard.width
            height: dashboard.height

            Charge {
                x: dashboard.placeX(dashboard.look.width + (Appearance.burst.stepSide - width) / 2 - dashboard.look.battery.pull, width)
                y: dashboard.centerY + Appearance.burst.stepSideOffset - height / 2
                level: Battery.level
                isCharging: Battery.isCharging
                isShown: dashboard.isContentShown && sideClip.step.rise > Appearance.burst.stepSide / 2
                enterDelay: Motion.pill.elementStagger
            }
        }
    }
}
