import QtQuick
import qs.config
import qs.services
import qs.components

FocusScope {
    id: dashboard

    property bool isOpen: false
    property bool isMirrored: false
    property bool hasTaskbar: true
    readonly property bool isPresent: isOpen || leave.running || bubbles.living > 0

    property real dim: 0
    property real reach: 0
    property real swell: 0
    property real crest: 0
    property real surge: 0
    property real clock: 0
    property bool isContentShown: false
    property bool isBubbling: false
    property int diskPage: 0

    readonly property var look: Appearance.dashboard
    readonly property real rootX: hasTaskbar ? Appearance.taskbar.margin + Appearance.taskbar.thickness + look.rootGap : 0
    readonly property real pad: look.melt * 3
    readonly property real bodyTop: Math.round((height - look.height) / 2)
    readonly property real centerY: bodyTop + look.height / 2
    readonly property real waveRoot: pad
    readonly property real waveFront: waveRoot + look.width * reach
    readonly property real waveHalf: look.height * swell / 2
    readonly property var disk: Hardware.disks.length > 0 ? Hardware.disks[Math.min(diskPage, Hardware.disks.length - 1)] : null

    signal closeRequested()

    function placeX(localX, itemWidth) {
        return isMirrored ? width - rootX - localX - itemWidth : rootX + localX
    }

    function revealDelay(localX) {
        return Math.round(localX * Motion.dashboard.reveal)
    }

    onIsOpenChanged: {
        if (isOpen) {
            leave.stop()
            enter.restart()
            forceActiveFocus()
        } else {
            enter.stop()
            leave.restart()
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

    FrameAnimation {
        running: dashboard.isPresent
        onTriggered: dashboard.clock += Math.min(frameTime, Motion.liquid.frameCap)
    }

    Item {
        id: stage
        x: dashboard.isMirrored ? 0 : dashboard.rootX
        width: dashboard.width - dashboard.rootX
        height: dashboard.height
        clip: true

        LiquidLayer {
            id: liquid
            x: dashboard.isMirrored ? 0 : -dashboard.pad
            width: stage.width + dashboard.pad
            height: stage.height
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

                Wave {
                    root: dashboard.waveRoot
                    front: dashboard.waveFront
                    ceiling: dashboard.centerY - dashboard.waveHalf
                    floor: dashboard.centerY + dashboard.waveHalf
                    corner: dashboard.look.corner
                    fillet: dashboard.look.fillet
                    crest: dashboard.crest * dashboard.look.crest
                    ripple: dashboard.look.idleRipple + dashboard.surge * dashboard.look.ripple
                    wavelength: dashboard.look.wavelength
                    phase: dashboard.clock * Motion.dashboard.waveSpeed
                }

                Bubbles {
                    id: bubbles
                    anchors.fill: parent
                    isRunning: dashboard.isBubbling
                    fromX: dashboard.waveRoot + dashboard.look.fillet * 2
                    toX: dashboard.waveFront - dashboard.look.corner * 0.6
                    ceiling: dashboard.centerY - dashboard.waveHalf
                    floor: dashboard.centerY + dashboard.waveHalf
                }
            }
        }
    }

    Item {
        id: content
        anchors.fill: parent

        Gauge {
            x: dashboard.placeX(dashboard.look.processorX, width)
            y: dashboard.bodyTop + dashboard.look.top
            name: Hardware.cpuName || "CPU"
            chipName: "cpu"
            chipText: "CPU"
            load: Hardware.cpuLoad
            temperature: Hardware.cpuTemperature
            isShown: dashboard.isContentShown
            enterDelay: dashboard.revealDelay(dashboard.look.processorX)
        }

        Gauge {
            x: dashboard.placeX(dashboard.look.processorX, width)
            y: dashboard.bodyTop + dashboard.look.top + dashboard.look.gauge.blockHeight + dashboard.look.gauge.blockGap
            name: Hardware.hasGpu ? Hardware.gpuName : "NO GPU"
            chipName: "gpu"
            chipText: "GPU"
            isKnown: Hardware.hasGpu
            load: Hardware.gpuLoad
            temperature: Hardware.gpuTemperature
            isShown: dashboard.isContentShown
            enterDelay: dashboard.revealDelay(dashboard.look.processorX) + Motion.pill.elementStagger
        }

        Memory {
            x: dashboard.placeX(dashboard.look.memoryX, width)
            y: dashboard.bodyTop + dashboard.look.top
            label: "RAM"
            glyph: "memory"
            used: Hardware.memoryUsed
            total: Hardware.memoryTotal
            isShown: dashboard.isContentShown
            enterDelay: dashboard.revealDelay(dashboard.look.memoryX)
        }

        Memory {
            x: dashboard.placeX(dashboard.look.memoryX, width)
            y: dashboard.bodyTop + dashboard.look.top + dashboard.look.memory.rowHeight
            label: "VRAM"
            glyph: "card"
            used: Hardware.videoMemoryUsed
            total: Hardware.videoMemoryTotal
            isShown: dashboard.isContentShown
            enterDelay: dashboard.revealDelay(dashboard.look.memoryX) + Motion.pill.elementStagger
        }

        Memory {
            x: dashboard.placeX(dashboard.look.memoryX, width)
            y: dashboard.bodyTop + dashboard.look.top + dashboard.look.memory.rowHeight * 2
            label: dashboard.disk ? "DISK " + dashboard.disk.mount : "DISK"
            glyph: "disk"
            used: dashboard.disk?.used ?? 0
            total: dashboard.disk?.total ?? 0
            pageCount: Hardware.disks.length
            page: dashboard.diskPage
            isShown: dashboard.isContentShown
            enterDelay: dashboard.revealDelay(dashboard.look.memoryX) + Motion.pill.elementStagger * 2
            onPaged: dashboard.diskPage = (dashboard.diskPage + 1) % Hardware.disks.length
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

    ParallelAnimation {
        id: enter

        ScriptAction {
            script: {
                dashboard.clock = 0
                dashboard.surge = 1
            }
        }
        NumberAnimation {
            target: dashboard
            property: "dim"
            to: 1
            duration: Motion.dashboard.dim
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: dashboard
            property: "reach"
            from: 0
            to: 1
            duration: Motion.dashboard.pour
            easing.type: Easing.OutBack
            easing.overshoot: Motion.dashboard.pourOvershoot
        }
        NumberAnimation {
            target: dashboard
            property: "swell"
            from: dashboard.look.swellFrom
            to: 1
            duration: Motion.dashboard.swell
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            NumberAnimation {
                target: dashboard
                property: "crest"
                from: 0
                to: 1
                duration: Motion.dashboard.crestRise
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: dashboard
                property: "crest"
                to: -0.3
                duration: Motion.dashboard.crestFall
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: dashboard
                property: "crest"
                to: 0
                duration: Motion.dashboard.crestSettle
                easing.type: Easing.OutQuad
            }
        }
        NumberAnimation {
            target: dashboard
            property: "surge"
            from: 1
            to: 0
            duration: Motion.dashboard.rippleDecay
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            PauseAnimation { duration: Motion.dashboard.contentDelay }
            ScriptAction { script: dashboard.isContentShown = true }
        }
        SequentialAnimation {
            PauseAnimation { duration: Motion.dashboard.bubbleDelay }
            ScriptAction { script: dashboard.isBubbling = true }
        }
    }

    SequentialAnimation {
        id: leave

        ScriptAction {
            script: {
                dashboard.isContentShown = false
                dashboard.isBubbling = false
            }
        }
        PauseAnimation { duration: Motion.dashboard.leaveHold }
        ParallelAnimation {
            NumberAnimation {
                target: dashboard
                property: "reach"
                to: 0
                duration: Motion.dashboard.leave
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: dashboard
                property: "swell"
                to: dashboard.look.swellFrom
                duration: Motion.dashboard.leave
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: dashboard
                property: "crest"
                to: -dashboard.look.recede
                duration: Motion.dashboard.leave
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: dashboard
                property: "surge"
                to: 0.5
                duration: Motion.dashboard.leave
                easing.type: Easing.OutQuad
            }
            SequentialAnimation {
                PauseAnimation { duration: Motion.dashboard.leave / 3 }
                NumberAnimation {
                    target: dashboard
                    property: "dim"
                    to: 0
                    duration: Motion.dashboard.dimOut
                    easing.type: Easing.InQuad
                }
            }
        }
        ScriptAction { script: dashboard.crest = 0 }
    }
}
