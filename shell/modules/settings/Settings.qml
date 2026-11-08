import QtQuick
import qs.config
import qs.components

FocusScope {
    id: settings

    property bool isOpen: false
    property rect origin: Qt.rect(0, 0, 0, 0)
    property var parts: []
    property color accent: Appearance.color.defaultAccent
    property string taskbarSide: "left"
    property string barStyle: "floating"
    property string windowMode: "canvas"
    property bool canSwitchMode: false
    property bool isReducedMotion: false
    property bool isQuiet: false
    property string tab: "appearance"
    property string shownTab: tab
    readonly property bool isPresent: isOpen || launch.isActive || rising.living > 0
    readonly property string phase: launch.phase
    readonly property bool isContentShown: launch.isOpened
    property real dim: isOpen ? 1 : 0

    readonly property var look: Appearance.settings
    readonly property var tabs: [
        { key: "appearance", label: "APPEARANCE", glyph: "drop" },
        { key: "taskbar", label: "TASKBAR", glyph: "style-floating" },
        { key: "system", label: "SYSTEM", glyph: "moon" }
    ].concat(canSwitchMode ? [{ key: "desktop", label: "DESKTOP", glyph: "mode-desktop" }] : [])
    readonly property var currentTab: tabs.find(entry => entry.key === tab) ?? tabs[0]

    readonly property bool isMirrored: taskbarSide === "right"
    readonly property rect edgeSeed: origin.width > 0
        ? origin
        : Qt.rect(Appearance.taskbar.margin, height / 2 - Appearance.taskbar.idleSize / 2, Appearance.taskbar.idleSize, Appearance.taskbar.idleSize)
    readonly property rect seed: isMirrored ? Qt.rect(width - edgeSeed.x - edgeSeed.width, edgeSeed.y, edgeSeed.width, edgeSeed.height) : edgeSeed

    readonly property real spanWidth: look.tabBar.width + look.tabBar.gap + look.width
    readonly property real panelX: Math.round((width - spanWidth) / 2) + look.tabBar.width + look.tabBar.gap
    readonly property real panelY: Math.round((height - look.height) / 2)
    readonly property real panelCenterY: panelY + look.height / 2

    signal closeRequested()
    signal landed()
    signal accentRequested(color value)
    signal sideRequested(string side)
    signal styleRequested(string style)
    signal modeRequested(string mode)
    signal reducedMotionRequested(bool isReduced)
    signal quietRequested(bool isQuiet)

    function pick(key) {
        if (key === tab)
            return
        tab = key
        jolt.kick()
    }

    function step(direction) {
        const index = tabs.findIndex(entry => entry.key === tab)
        pick(tabs[(index + direction + tabs.length) % tabs.length].key)
    }

    onTabsChanged: if (!tabs.some(entry => entry.key === tab)) tab = tabs[0].key
    onTabChanged: {
        shownTab = ""
        pageSwap.restart()
    }
    onIsOpenChanged: {
        jolt.settle()
        if (isOpen)
            forceActiveFocus()
    }

    Behavior on dim {
        SequentialAnimation {
            PauseAnimation { duration: Motion.pace(settings.isOpen ? Motion.settings.merge : 0) }
            NumberAnimation {
                duration: Motion.pace(settings.isOpen ? Motion.settings.dim : Motion.settings.dimOut)
                easing.type: settings.isOpen ? Easing.OutQuad : Easing.InQuad
            }
        }
    }

    Jolt {
        id: jolt
        amplitude: settings.look.jolt
        steps: Motion.settings.joltSteps
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)))
            closeRequested()
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
            step(1)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
            step(-1)
        else
            return
        event.accepted = true
    }

    Timer {
        id: pageSwap
        interval: Motion.settings.pageSwap
        onTriggered: settings.shownTab = settings.tab
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.color.shadow
        opacity: settings.dim * settings.look.dim
    }

    MouseArea {
        anchors.fill: parent
        enabled: settings.isOpen
        onClicked: settings.closeRequested()
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: launch.isActive
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: settings.look.melt
        opacity: launch.material

        Launch {
            id: launch
            parent: liquid.shapes
            look: settings.look
            pace: Motion.settings
            isShown: settings.isOpen
            parts: settings.parts
            isMirrored: settings.isMirrored
            isBare: settings.barStyle === "bare"
            seed: settings.seed
            panelX: settings.panelX
            panelY: settings.panelY
            budX: tabBar.x
            budY: tabBar.y + tabBar.height / 2
            budLength: tabBar.height
            jolt: jolt.value
            onLanded: settings.landed()
        }

        Rising {
            id: rising
            parent: liquid.shapes
            anchors.fill: parent
            isRunning: launch.isOpened
            fromX: settings.panelX + settings.look.radius
            toX: settings.panelX + settings.look.width - settings.look.radius
            ceiling: settings.panelY
            floor: settings.panelY + settings.look.height
        }
    }

    MouseArea {
        x: settings.panelX
        y: settings.panelY
        width: settings.look.width
        height: settings.look.height
        enabled: settings.isOpen
    }

    MouseArea {
        x: tabBar.x
        y: tabBar.y
        width: tabBar.width
        height: tabBar.height
        enabled: settings.isOpen
    }

    TabBar {
        id: tabBar
        x: settings.panelX - settings.look.tabBar.gap - width
        y: Math.round(settings.panelCenterY - height / 2)
        tabs: settings.tabs
        currentKey: settings.tab
        isShown: launch.isBudOut
        onPicked: key => settings.pick(key)
    }

    Item {
        id: panel
        x: settings.panelX
        y: settings.panelY
        width: settings.look.width
        height: settings.look.height

        Row {
            id: header
            x: settings.look.padding
            y: settings.look.padding
            spacing: settings.look.gap

            Turn {
                isShown: settings.isContentShown
                enterEasing: Easing.OutBack
                leaveWindow: 0

                Text {
                    text: "SETTINGS"
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }

            TypedText {
                target: settings.currentTab.label
                isShown: settings.isContentShown
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                color: Appearance.color.accent
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }

        Item {
            id: pageArea
            x: settings.look.padding
            y: header.y + header.height + settings.look.headerGap
            width: panel.width - settings.look.padding * 2
            height: panel.height - y - settings.look.padding

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "appearance"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown

                Row {
                    spacing: settings.look.headerGap

                    ColorWheel {
                        look: settings.look
                        color: settings.accent
                        onPicked: value => settings.accentRequested(value)
                    }

                    Column {
                        spacing: Appearance.unit.medium

                        Text {
                            text: "ACCENT"
                            color: Appearance.color.textMuted
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                        }

                        GlyphButton {
                            label: "RESET"
                            implicitHeight: settings.look.option
                            onClicked: settings.accentRequested(Appearance.color.defaultAccent)
                        }
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "taskbar"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown

                Column {
                    spacing: settings.look.headerGap

                    OptionGroup {
                        label: "SIDE"
                        options: ["left", "right"]
                        current: settings.taskbarSide
                        onPicked: option => settings.sideRequested(option)
                    }

                    OptionGroup {
                        label: "STYLE"
                        options: ["floating", "fused", "bare"]
                        current: settings.barStyle
                        onPicked: option => settings.styleRequested(option)
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "system"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown

                Column {
                    spacing: settings.look.headerGap

                    OptionGroup {
                        label: "MOTION"
                        options: ["full", "reduced"]
                        current: settings.isReducedMotion ? "reduced" : "full"
                        onPicked: option => settings.reducedMotionRequested(option === "reduced")
                    }

                    OptionGroup {
                        label: "NOTIFICATIONS"
                        options: ["open", "quiet"]
                        current: settings.isQuiet ? "quiet" : "open"
                        onPicked: option => settings.quietRequested(option === "quiet")
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "desktop"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown

                OptionGroup {
                    label: "WINDOW MODE"
                    options: ["canvas", "desktop"]
                    current: settings.windowMode
                    onPicked: option => settings.modeRequested(option)
                }
            }
        }
    }
}
