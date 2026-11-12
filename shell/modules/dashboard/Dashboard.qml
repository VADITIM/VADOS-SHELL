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
    property bool shouldStream: true
    property bool canHandOff: false
    property bool isHandingOver: false
    property bool hasCircle: false
    property bool hasTaskIcons: false
    readonly property bool isPresent: isOpen || burst.isActive || taskBurst.isActive || rising.living > 0 || taskRising.living > 0
    readonly property string phase: burst.phase

    property real dim: isOpen ? 1 : 0
    property int diskPage: 0
    readonly property bool isContentShown: burst.isOpened
    readonly property var visitor: burst.visitor
    readonly property bool isCarrying: burst.isCarrying

    readonly property var look: Appearance.dashboard
    readonly property real rootX: Appearance.taskbar.margin
    readonly property real bodyTop: Math.round((height - look.height) / 2)
    readonly property real centerY: bodyTop + look.height / 2
    readonly property real memoryShare: Hardware.memoryTotal > 0 ? Hardware.memoryUsed / Hardware.memoryTotal : 0
    readonly property var disk: Hardware.disks.length > 0 ? Hardware.disks[Math.min(diskPage, Hardware.disks.length - 1)] : null

    readonly property var task: look.task
    readonly property real taskBodyFar: rootX + look.width + (Battery.isPresent ? Appearance.burst.stepSide : 0)
    readonly property real taskWidth: Math.min(task.width, width - taskBodyFar - task.bodyGap)
    readonly property real taskHeight: Math.min(task.height, height - task.edgeGap * 2)
    readonly property real taskTop: Math.round((height - taskHeight) / 2)
    readonly property real taskLeft: isMirrored ? 0 : width - taskWidth
    readonly property real shotY: centerY
    readonly property real shotStart: burst.formRight + (Battery.isPresent ? burst.sideStep.rise : 0) - task.shotInset
    readonly property real shotDistance: width + task.shotSink - task.shot / 2 - taskBodyFar + task.shotInset
    readonly property bool hasTaskRoom: taskWidth >= task.minWidth
    readonly property bool isTaskWanted: isOpen && hasTaskRoom && !burst.isLeaving && burst.spread >= Motion.dashboard.taskAt
    readonly property bool isShotLanded: isTaskWanted && taskShot.isArrived && taskShot.width > shotDistance / 2
    readonly property real taskBodyLeft: width - (taskBurst.form.x + taskBurst.form.width / 2)
    readonly property real taskBodyRight: width - (taskBurst.form.x - taskBurst.form.width / 2)
    readonly property real taskBodyTop: taskBurst.form.y - taskBurst.form.height / 2
    readonly property real taskBodyBottom: taskBurst.form.y + taskBurst.form.height / 2

    signal closeRequested()
    signal landed()
    signal taskIconsToggled()

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
        return (isKnown ? String(Math.round(share * 100)) : "--").padStart(3, " ") + "%"
    }

    function temperatureText(temperature, isKnown) {
        return (isKnown && temperature > 0 ? String(Math.round(temperature)) : "--").padStart(3, " ") + "°"
    }

    function gigabytes(bytes) {
        return String(Math.round(bytes / 1073741824))
    }

    function placeX(localX, itemWidth) {
        return isMirrored ? width - rootX - localX - itemWidth : rootX + localX
    }

    function tilt(degrees) {
        return isMirrored ? -degrees : degrees
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

    MouseArea {
        x: dashboard.taskLeft
        y: dashboard.taskTop
        width: dashboard.taskWidth
        height: dashboard.taskHeight
        enabled: dashboard.isTaskWanted
    }

    Reshape {
        id: taskShot
        targetWidth: dashboard.isTaskWanted ? dashboard.shotDistance : 0
        targetHeight: targetWidth
        growDuration: Motion.pace(Motion.dashboard.taskShot)
        shrinkDuration: Motion.pace(Motion.dashboard.taskShotBack)
        shrinkDelay: Motion.pace(Math.round(Motion.burst.leaveHold + Motion.burst.leave * Motion.burst.leaveShrink))
        overshoot: Motion.dashboard.taskShotBounce
        arriveShare: Motion.dashboard.taskShotLand
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
                shouldStream: dashboard.shouldStream
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

            TaskShape {
                id: taskShape
                anchors.fill: parent
                shotStart: dashboard.shotStart
                shotY: dashboard.shotY
                shotFrom: dashboard.task.shotFrom
                shotSize: dashboard.task.shot
                shotStretch: dashboard.task.shotStretch
                shotSink: dashboard.task.shotSink
                shotSquash: dashboard.task.shotSquash
                travel: dashboard.shotDistance > 0 ? taskShot.width / dashboard.shotDistance : 0
                edgeX: liquid.width
                corner: dashboard.task.corner
                fillet: dashboard.task.fillet
            }

            Item {
                anchors.fill: parent
                transform: Scale {
                    origin.x: liquid.width / 2
                    xScale: -1
                }

                Burst {
                    id: taskBurst
                    label: "task manager burst"
                    isShown: dashboard.isShotLanded
                    shouldStream: false
                    hasCircle: true
                    isHandingOver: true
                    hasSteps: false
                    ball: dashboard.task.shot
                    leaveBall: dashboard.task.shot
                    rootX: 0
                    seedX: dashboard.task.shot / 2 - dashboard.task.shotSink
                    seedY: dashboard.taskTop + dashboard.taskHeight / 2
                    formWidth: dashboard.taskWidth
                    formHeight: dashboard.taskHeight
                    leftCorner: dashboard.task.fillet
                    rightCorner: dashboard.task.corner
                    edgePad: dashboard.look.melt
                    screenHeight: dashboard.height
                }
            }

            Item {
                id: tabShapes
                anchors.fill: parent
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

            Rising {
                id: taskRising
                anchors.fill: parent
                isRunning: taskManager.isShown
                fromX: dashboard.taskBodyLeft + dashboard.task.corner
                toX: liquid.width - dashboard.task.corner
                ceiling: dashboard.taskTop
                floor: dashboard.taskTop + dashboard.taskHeight
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
                id: graphicsGauge
                x: dashboard.placeX(dashboard.look.graphicsX, width)
                y: dashboard.bodyTop + dashboard.look.top
                name: Hardware.hasGpu ? Hardware.gpuName : "NO GPU"
                chipName: "gpu"
                ringShare: dashboard.heatShare(Hardware.gpuTemperature, Hardware.hasGpu)
                ringColor: dashboard.heatColor(Hardware.gpuTemperature, Hardware.hasGpu)
                glyphColor: dashboard.usageColor(Hardware.gpuLoad, Hardware.hasGpu)
                chipLabel: "GPU"
                hasUsage: true
                usageShare: Hardware.hasGpu ? Hardware.gpuLoad : 0
                usageColor: dashboard.usageColor(Hardware.gpuLoad, Hardware.hasGpu)
                readout: dashboard.percentText(Hardware.gpuLoad, Hardware.hasGpu)
                caption: dashboard.temperatureText(Hardware.gpuTemperature, Hardware.hasGpu)
                nameTilt: dashboard.tilt(dashboard.look.gauge.graphicsTilt)
                hasBar: true
                barUsed: Hardware.videoMemoryUsed
                barTotal: Hardware.videoMemoryTotal
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.graphicsX)
            }

            Gauge {
                id: processorGauge
                x: dashboard.placeX(dashboard.look.processorX, width)
                y: dashboard.bodyTop + dashboard.look.top + dashboard.look.gauge.blockHeight + dashboard.look.gauge.blockGap
                name: Hardware.cpuName || "CPU"
                chipName: "cpu"
                ringShare: dashboard.heatShare(Hardware.cpuTemperature, true)
                ringColor: dashboard.heatColor(Hardware.cpuTemperature, true)
                glyphColor: dashboard.usageColor(Hardware.cpuLoad, true)
                chipLabel: "CPU"
                hasUsage: true
                usageShare: Hardware.cpuLoad
                usageColor: dashboard.usageColor(Hardware.cpuLoad, true)
                readout: dashboard.percentText(Hardware.cpuLoad, true)
                caption: dashboard.temperatureText(Hardware.cpuTemperature, true)
                nameTilt: dashboard.tilt(dashboard.look.gauge.processorTilt)
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.processorX) + Motion.pill.elementStagger
            }

            Gauge {
                id: memoryGauge
                x: dashboard.placeX(dashboard.look.memoryX, width)
                y: dashboard.bodyTop + dashboard.look.top + dashboard.look.gauge.blockHeight + dashboard.look.gauge.blockGap
                chipName: "ram"
                ringShare: dashboard.memoryShare
                ringColor: dashboard.usageColor(dashboard.memoryShare, true)
                name: "MEMORY"
                glyphColor: dashboard.usageColor(dashboard.memoryShare, true)
                chipLabel: "RAM"
                usageColor: dashboard.usageColor(dashboard.memoryShare, true)
                readout: dashboard.percentText(dashboard.memoryShare, true)
                caption: dashboard.gigabytes(Hardware.memoryUsed).padStart(dashboard.gigabytes(Hardware.memoryTotal).length, " ") + "GB/" + dashboard.gigabytes(Hardware.memoryTotal) + "GB"
                nameTilt: dashboard.tilt(dashboard.look.gauge.memoryTilt)
                isShown: dashboard.isContentShown
                enterDelay: dashboard.revealDelay(dashboard.look.memoryX) + Motion.pill.elementStagger * 2
            }

            Item {
                id: readout

                readonly property var hovered: graphicsGauge.isHovered ? graphicsGauge : processorGauge.isHovered ? processorGauge : memoryGauge.isHovered ? memoryGauge : null
                property var held: null

                x: dashboard.placeX(dashboard.look.readoutX, width)
                y: dashboard.bodyTop + dashboard.look.top + (dashboard.look.gauge.blockHeight - height) / 2
                width: dashboard.look.dividerX - dashboard.look.traffic.dividerGap - dashboard.look.readoutX
                height: upperReadout.height + dashboard.look.gauge.readoutGap + lowerReadout.height
                onHoveredChanged: if (hovered) held = hovered

                Roll {
                    id: upperReadout
                    x: dashboard.isMirrored ? readout.width - width : 0
                    target: readout.held?.caption ?? ""
                    isShown: readout.hovered !== null
                    holdsWidth: true
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: dashboard.look.gauge.readout
                    font.bold: true
                }

                Roll {
                    id: lowerReadout
                    x: dashboard.isMirrored ? readout.width - width : 0
                    y: upperReadout.height + dashboard.look.gauge.readoutGap
                    target: readout.held?.readout ?? ""
                    isShown: readout.hovered !== null
                    holdsWidth: true
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: dashboard.look.gauge.readout
                    font.bold: true
                }
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
                samples: Traffic.samples
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
                y: dashboard.centerY - height / 2
                level: Battery.level
                isCharging: Battery.isCharging
                isShown: dashboard.isContentShown && sideClip.step.rise > Appearance.burst.stepSide / 2
                enterDelay: Motion.pill.elementStagger
            }
        }
    }

    Item {
        id: taskClip

        readonly property real clipTop: Math.max(dashboard.taskTop, dashboard.taskBodyTop)
        readonly property real clipBottom: Math.min(dashboard.taskTop + dashboard.taskHeight, dashboard.taskBodyBottom)
        readonly property real clipLeft: Math.max(dashboard.width - dashboard.taskWidth, dashboard.taskBodyLeft)
        readonly property real clipRight: Math.min(dashboard.width, dashboard.taskBodyRight)

        visible: taskBurst.isActive
        x: dashboard.isMirrored ? dashboard.width - clipRight : clipLeft
        y: clipTop
        width: Math.max(0, clipRight - clipLeft)
        height: Math.max(0, clipBottom - clipTop)
        clip: true

        TaskManager {
            id: taskManager
            x: dashboard.taskLeft - taskClip.x
            y: dashboard.taskTop - taskClip.y
            width: dashboard.taskWidth
            height: dashboard.taskHeight
            focus: true
            hasIcons: dashboard.hasTaskIcons
            isShown: taskBurst.isOpened
            onIconsToggled: dashboard.taskIconsToggled()
        }
    }

    TaskTabs {
        anchors.fill: parent
        shapes: tabShapes
        isMirrored: dashboard.isMirrored
        isShown: taskManager.isShown
        current: taskManager.tab
        stackRight: dashboard.taskBodyLeft - dashboard.task.tabOut
        centerY: taskBurst.form.y
        onPicked: key => taskManager.pickTab(key)
    }
}
