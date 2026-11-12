import QtQuick
import qs.config
import qs.components
import qs.services
import "../../utils/Banner.js" as Banner
import "../../utils/Lock.js" as Lock

FocusScope {
    id: settings

    property bool isOpen: false
    property var parts: []
    property bool shouldStream: true
    property bool isMirrored: false
    property bool canHandOff: false
    property bool isHandingOver: false
    property bool hasCircle: false
    property color accent: Appearance.color.defaultAccent
    property string taskbarSide: "left"
    property string barStyle: "floating"
    property string taskbarGather: "merge"
    property string windowMode: "canvas"
    property bool canSwitchMode: false
    property bool isReducedMotion: false
    property string burstStyle: "static"
    property bool isQuiet: false
    property string screenshotFolder: ""
    property string recordingFolder: ""
    property string defaultScreenshots: ""
    property string defaultRecordings: ""
    property string profileName: ""
    property string profileSecondName: ""
    property string profilePicture: ""
    property string profileGithub: ""
    property real pillOpacity: 0.94
    property real pillBlur: 1
    property string pillColor: ""
    property bool isMediaPlayerOn: true
    property bool isNotificationsOn: false
    property var lockLayout: []
    property string lockWallpaper: ""
    property string pickedModule: ""
    property string openingTab: ""
    property string tab: "home"
    property string shownTab: tab
    property string subTab: ""
    property string shownSubTab: subTab
    readonly property bool isPresent: isOpen || burst.isActive || rising.living > 0
    readonly property string phase: burst.phase
    readonly property bool isContentShown: burst.isOpened
    readonly property var visitor: burst.visitor
    readonly property bool isCarrying: burst.isCarrying
    property real dim: isOpen ? 1 : 0

    readonly property var look: Appearance.settings
    readonly property var tabs: [
        { key: "user", label: "USER", glyph: "user" },
        { key: "settings", label: "SETTINGS", glyph: "settings" },
        { key: "customization", label: "CUSTOMIZATION", glyph: "brush" },
        { key: "advanced", label: "ADVANCED", glyph: "bolt" }
    ]
    readonly property var subTabsByTab: ({
        customization: [
            { key: "backgrounds", label: "BACKGROUNDS", glyph: "mode-canvas" },
            { key: "pills", label: "PILLS", glyph: "drop" },
            { key: "taskbar", label: "TASKBAR", glyph: "style-floating" },
            { key: "lock", label: "LOCK SCREEN", glyph: "lock" }
        ],
        advanced: [
            { key: "vados", label: "LINK TO VAD/OS", glyph: "bolt" },
            { key: "services", label: "SERVICES", glyph: "dots" }
        ]
    })
    readonly property var subTabs: subTabsByTab[tab] ?? []
    readonly property bool hasSubBar: subTabs.length > 0

    readonly property real rootX: Appearance.taskbar.margin
    readonly property real formWidth: Math.round(width * look.bodyShare * (1 - look.rightSpace) + look.endPadding)
    readonly property real navigationX: rootX + look.inset
    readonly property real subBarX: navigationX + look.navigation.width + look.navigation.gap
    property real contentX: (hasSubBar ? subBarX + look.navigation.width : navigationX + look.navigation.width) + look.contentGap
    readonly property real contentSpan: Math.max(0, formWidth - look.endPadding - (contentX - rootX))
    readonly property real centerY: Math.round(height / 2)
    readonly property bool isLockShown: isContentShown && shownTab === "customization" && shownSubTab === "lock"
    readonly property var lockRows: arrangeLockRows()
    readonly property real wave: waveTurn.presence
    readonly property real lockContentHeight: lockRows.length > 0 ? lockRows[lockRows.length - 1].y + lockRows[lockRows.length - 1].height : 0
    readonly property real lockX: rootX + formWidth - look.lock.cardWidth + look.lock.poke
    readonly property real lockY: content.y + pageArea.y

    signal closeRequested()
    signal landed()
    signal accentRequested(color value)
    signal sideRequested(string side)
    signal styleRequested(string style)
    signal gatherRequested(string gather)
    signal modeRequested(string mode)
    signal reducedMotionRequested(bool isReduced)
    signal burstStyleRequested(string style)
    signal quietRequested(bool isQuiet)
    signal folderRequested(string kind, string folder)
    signal profileRequested(string field, string value)
    signal pictureRequested()
    signal pillRequested(string field, var value)
    signal mediaPlayerRequested(bool isOn)
    signal notificationsRequested(bool isOn)
    signal lockLayoutRequested(var entries)
    signal lockWallpaperRequested(string value)

    function edgeX(localX, itemWidth) {
        return isMirrored ? width - localX - itemWidth : localX
    }

    function arrangeLockRows() {
        const result = []
        let top = 0
        let group = ""
        for (const entry of Lock.modules) {
            if (entry.group !== group) {
                group = entry.group
                result.push({ kind: "header", key: group, label: group, y: top, height: look.lock.headerHeight })
                top += look.lock.headerHeight
            }
            result.push({ kind: "module", key: entry.key, label: entry.label, y: top, height: look.lock.cardHeight })
            top += look.lock.cardHeight + look.lock.cardGap
        }
        return result
    }

    function waveDelay(row) {
        return Motion.settings.pageSwap + Math.round((lockY + row.y + row.height / 2) / height * Motion.settings.waveRun)
    }

    function pickModule(key) {
        pickedModule = pickedModule === key ? "" : key
    }

    function pick(key) {
        if (key === tab)
            return
        tab = key
    }

    function pickSub(key) {
        subTab = key
    }

    function step(direction) {
        const index = tabs.findIndex(entry => entry.key === tab)
        const from = index >= 0 ? index : direction > 0 ? -1 : tabs.length
        pick(tabs[(from + direction + tabs.length) % tabs.length].key)
    }

    function stepSub(direction) {
        if (!hasSubBar)
            return
        const index = subTabs.findIndex(entry => entry.key === subTab)
        pickSub(subTabs[(index + direction + subTabs.length) % subTabs.length].key)
    }

    onIsLockShownChanged: if (!isLockShown) pickedModule = ""
    onTabChanged: {
        const entries = subTabsByTab[tab] ?? []
        subTab = entries.length > 0 ? entries[0].key : ""
        shownTab = ""
        shownSubTab = ""
        pageSwap.restart()
    }
    onSubTabChanged: {
        shownSubTab = ""
        pageSwap.restart()
    }
    onIsOpenChanged: {
        if (!isOpen)
            return
        tab = openingTab.length > 0 ? openingTab : "home"
        forceActiveFocus()
    }
    Component.onCompleted: subTab = subTabs.length > 0 ? subTabs[0].key : ""

    Behavior on dim {
        NumberAnimation {
            duration: Motion.pace(settings.isOpen ? Motion.settings.dim : Motion.settings.dimOut)
            easing.type: settings.isOpen ? Easing.OutQuad : Easing.InQuad
        }
    }

    Behavior on contentX {
        NumberAnimation {
            duration: Motion.pace(Motion.settings.slide)
            easing.type: Easing.OutCubic
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape || (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)))
            closeRequested()
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
            step(1)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
            step(-1)
        else if (event.key === Qt.Key_Right)
            stepSub(isMirrored ? -1 : 1)
        else if (event.key === Qt.Key_Left)
            stepSub(isMirrored ? 1 : -1)
        else
            return
        event.accepted = true
    }

    Timer {
        id: pageSwap
        interval: Motion.settings.pageSwap
        onTriggered: {
            settings.shownTab = settings.tab
            settings.shownSubTab = settings.subTab
        }
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

    MouseArea {
        x: settings.edgeX(settings.rootX, width)
        width: settings.formWidth
        height: settings.height
        enabled: settings.isOpen
    }

    LiquidLayer {
        id: liquid
        anchors.fill: parent
        isShown: burst.isActive
        fill: Appearance.color.panel
        rim: Appearance.color.hairline
        fillAlpha: Appearance.color.panelAlpha
        melt: settings.look.melt

        Item {
            parent: liquid.shapes
            anchors.fill: parent
            transform: Upright {
                isMirrored: settings.isMirrored
                axis: liquid.width / 2
            }

            Burst {
                id: burst
                label: "settings burst"
                isShown: settings.isOpen
                parts: settings.parts
                shouldStream: settings.shouldStream
                rootX: settings.rootX
                seedX: settings.rootX + Appearance.taskbar.thickness / 2
                seedY: settings.centerY
                formWidth: settings.formWidth
                formHeight: settings.height
                leftCorner: settings.look.rootCorner
                rightCorner: settings.look.corner
                edgePad: settings.look.melt
                screenHeight: settings.height
                canHandOff: settings.canHandOff
                isHandingOver: settings.isHandingOver
                hasCircle: settings.hasCircle
                hasSteps: false
                onLanded: settings.landed()
            }

            Item {
                x: settings.lockX
                y: 0
                width: settings.look.lock.cardWidth
                height: settings.height
                clip: true

                LiquidShape {
                    readonly property real swell: Math.sin(Math.PI * settings.wave)
                    readonly property real span: settings.height * settings.look.lock.crest

                    visible: settings.isLockShown && settings.wave < 1
                    x: settings.look.lock.cardWidth - (settings.look.lock.poke + settings.look.melt) * settings.look.lock.swell * swell
                    y: settings.wave * (settings.height + span) - span
                    width: (settings.look.lock.poke + settings.look.melt) * settings.look.lock.swell * swell
                    height: span
                }

                Repeater {
                    model: settings.lockRows.filter(row => row.kind === "module")

                    Item {
                        id: bump

                        required property var modelData
                        required property int index
                        readonly property real reach: settings.look.lock.poke + settings.look.melt

                        Turn {
                            id: bumpTurn
                            isShown: settings.isLockShown
                            enterDelay: settings.waveDelay(bump.modelData)
                            enterEasing: Easing.OutBack
                            leaveWindow: 0
                            leaveDuration: Motion.settings.pageSwap
                        }

                        LiquidShape {
                            x: settings.look.lock.cardWidth - bump.reach
                            y: bump.modelData.y - lockView.contentY + settings.look.lock.cardHeight * (1 - Math.min(1, bumpTurn.presence)) / 2
                            width: bump.reach * Math.min(1, bumpTurn.presence)
                            height: settings.look.lock.cardHeight * Math.min(1, bumpTurn.presence)
                        }
                    }
                }
            }

            Rising {
                id: rising
                anchors.fill: parent
                isRunning: burst.isOpened
                fromX: burst.form.x - burst.form.width / 2 + settings.look.rootCorner
                toX: burst.form.x + burst.form.width / 2 - settings.look.corner * 0.6
                ceiling: burst.form.y - burst.form.height / 2
                floor: burst.form.y + burst.form.height / 2
            }
        }
    }

    Masked {
        x: settings.edgeX(settings.rootX, width)
        width: settings.formWidth
        height: settings.height
        visible: ascii.presence > 0.01

        mask: Rectangle {
            anchors.fill: parent
            radius: settings.look.corner
        }

        AsciiBackground {
            id: ascii
            anchors.fill: parent
            isShown: settings.isContentShown && settings.shownTab !== "home"
        }
    }

    TabBar {
        id: navigationBar
        x: settings.edgeX(settings.navigationX, width)
        y: Math.round(settings.centerY - height / 2)
        tabs: settings.tabs
        currentKey: settings.tab
        isShown: settings.isContentShown
        onPicked: key => settings.pick(key)
    }

    TabBar {
        id: subBar
        x: settings.edgeX(settings.subBarX, width)
        y: Math.round(settings.centerY - height / 2)
        tabs: settings.subTabs
        currentKey: settings.subTab
        isShown: settings.isContentShown && settings.hasSubBar
        fill: Appearance.color.defaultAccent
        onPicked: key => settings.pickSub(key)
    }

    Item {
        id: content
        x: settings.edgeX(settings.contentX, width)
        y: settings.look.top
        width: settings.contentSpan
        height: settings.height - settings.look.top * 2

        Item {
            id: pageArea
            width: content.width
            height: content.height - y

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "home"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown

                Item {
                    width: pageArea.width
                    height: pageArea.height

                    Piece {
                        id: bannerPiece
                        x: (pageArea.width - width) / 2
                        y: (pageArea.height - height - settings.look.home.gap - versionPiece.height) / 2
                        width: bannerText.implicitWidth
                        height: bannerText.implicitHeight

                        Text {
                            id: bannerText
                            text: Banner.art
                            textFormat: Text.PlainText
                            color: Appearance.color.text
                            font.family: Appearance.font.fixedMono
                            font.preferShaping: false
                            font.pixelSize: settings.look.home.bannerSize
                            lineHeight: settings.look.home.bannerLine
                        }
                    }

                    Piece {
                        id: versionPiece
                        x: (pageArea.width - width) / 2
                        y: bannerPiece.y + bannerPiece.height + settings.look.home.gap
                        width: versionText.implicitWidth
                        height: versionText.implicitHeight

                        Text {
                            id: versionText
                            text: Release.version
                            color: Appearance.color.textFaint
                            opacity: settings.look.home.versionShade
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                        }
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "user"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown

                ProfileEditor {
                    areaWidth: pageArea.width
                    areaHeight: pageArea.height
                    name: settings.profileName
                    secondName: settings.profileSecondName
                    picture: settings.profilePicture
                    github: settings.profileGithub
                    accent: settings.accent
                    onProfileRequested: (field, value) => settings.profileRequested(field, value)
                    onPictureRequested: settings.pictureRequested()
                    onAccentRequested: value => settings.accentRequested(value)
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "settings"
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
                        label: "BURST"
                        options: ["static", "procedural"]
                        current: settings.burstStyle
                        onPicked: option => settings.burstStyleRequested(option)
                    }

                    OptionGroup {
                        label: "TASKBAR GATHER"
                        options: ["merge", "shrink"]
                        current: settings.taskbarGather
                        onPicked: option => settings.gatherRequested(option)
                    }

                    OptionGroup {
                        label: "NOTIFICATIONS"
                        options: ["open", "quiet"]
                        current: settings.isQuiet ? "quiet" : "open"
                        onPicked: option => settings.quietRequested(option === "quiet")
                    }

                    OptionGroup {
                        visible: settings.canSwitchMode
                        label: "WINDOW MODE"
                        options: ["canvas", "desktop"]
                        current: settings.windowMode
                        onPicked: option => settings.modeRequested(option)
                    }

                    TextField {
                        label: "SCREENSHOTS FOLDER (EMPTY FOR DEFAULT)"
                        placeholder: settings.defaultScreenshots
                        value: settings.screenshotFolder
                        fieldWidth: settings.look.pathWidth
                        onEdited: value => settings.folderRequested("screenshots", value)
                    }

                    TextField {
                        label: "RECORDINGS FOLDER (EMPTY FOR DEFAULT)"
                        placeholder: settings.defaultRecordings
                        value: settings.recordingFolder
                        fieldWidth: settings.look.pathWidth
                        onEdited: value => settings.folderRequested("recordings", value)
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "backgrounds"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown

                Piece {
                    Text {
                        text: "NO BACKGROUND OPTIONS YET"
                        color: Appearance.color.textFaint
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "pills"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown

                Column {
                    spacing: Appearance.unit.medium

                    Fader {
                        label: "BLUR"
                        value: settings.pillBlur
                        trackWidth: settings.look.fieldWidth
                        onMoved: value => settings.pillRequested("blur", value)
                    }

                    Fader {
                        label: "OPACITY"
                        value: settings.pillOpacity
                        trackWidth: settings.look.fieldWidth
                        onMoved: value => settings.pillRequested("opacity", value)
                    }

                    TextField {
                        label: "COLOR (HEX, EMPTY FOR DEFAULT)"
                        placeholder: "HEX"
                        value: settings.pillColor
                        onEdited: value => settings.pillRequested("color", value)
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "taskbar"
                shownKey: settings.shownSubTab
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
                pageKey: "lock"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown

                LockEditor {
                    layout: settings.lockLayout
                    picked: settings.pickedModule
                    wallpaper: settings.lockWallpaper
                    areaWidth: pageArea.width
                    areaHeight: pageArea.height
                    onLayoutRequested: entries => settings.lockLayoutRequested(entries)
                    onPickRequested: key => settings.pickedModule = key
                    onWallpaperRequested: value => settings.lockWallpaperRequested(value)
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "vados"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown

                Piece {
                    Text {
                        text: "ENHANCE YOUR EXPERIENCE WITH THE VAD/OS FAMILY APPS"
                        color: Appearance.color.textFaint
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "services"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown

                Column {
                    spacing: settings.look.headerGap

                    OptionGroup {
                        label: "MEDIA PLAYER"
                        options: ["on", "off"]
                        current: settings.isMediaPlayerOn ? "on" : "off"
                        onPicked: option => settings.mediaPlayerRequested(option === "on")
                    }

                    OptionGroup {
                        label: "NOTIFICATION DAEMON"
                        options: ["on", "off"]
                        current: settings.isNotificationsOn ? "on" : "off"
                        onPicked: option => settings.notificationsRequested(option === "on")
                    }
                }
            }
        }
    }

    Turn {
        id: waveTurn
        isShown: settings.isLockShown
        enterDelay: Motion.settings.pageSwap
        enterDuration: Motion.settings.waveRun
        enterEasing: Easing.Linear
        leaveWindow: 0
        leaveDuration: Motion.settings.pageSwap
    }

    Flickable {
        id: lockView
        x: settings.edgeX(settings.lockX, width)
        y: 0
        width: settings.look.lock.cardWidth
        height: settings.height
        topMargin: settings.lockY
        bottomMargin: settings.look.top
        contentHeight: settings.lockContentHeight
        interactive: settings.isLockShown
        visible: settings.isLockShown || cardsLinger.running
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        Drift {}

        Timer {
            id: cardsLinger
            interval: Motion.settings.pageSwap + Motion.settings.stagger * Lock.modules.length
        }

        Connections {
            target: settings

            function onIsLockShownChanged() {
                if (!settings.isLockShown)
                    cardsLinger.restart()
            }
        }

        Repeater {
            model: settings.lockRows

            Turn {
                id: card

                required property var modelData
                required property int index
                readonly property bool isPicked: settings.pickedModule === modelData.key
                readonly property bool isPlaced: Lock.isPlaced(settings.lockLayout, modelData.key)

                y: modelData.y
                width: settings.look.lock.cardWidth
                height: modelData.height
                isShown: settings.isLockShown
                enterDelay: settings.waveDelay(modelData)
                enterEasing: Easing.OutBack
                leaveWindow: 0
                leaveDuration: Motion.settings.pageSwap

                Text {
                    visible: card.modelData.kind === "header"
                    anchors.verticalCenter: parent.verticalCenter
                    x: settings.look.fieldPadding
                    text: card.modelData.label
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }

                Item {
                    visible: card.modelData.kind === "module" && card.isPlaced
                    x: settings.look.lock.cardWidth - settings.look.lock.poke
                    width: settings.look.lock.poke
                    height: parent.height
                    clip: true

                    Rectangle {
                        x: settings.look.lock.poke - width
                        width: settings.look.lock.poke + settings.look.melt
                        height: parent.height
                        radius: width / 2
                        color: "transparent"
                        border.width: settings.look.lock.outline
                        border.color: Appearance.color.accent
                    }
                }

                Item {
                    visible: card.modelData.kind === "module"
                    anchors.fill: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: settings.look.fieldPadding
                        text: card.modelData.label
                        color: card.isPicked ? Appearance.color.accent : Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: settings.look.fieldPadding / 2
                        text: card.isPlaced ? "ON" : ""
                        color: Appearance.color.accent
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: settings.isLockShown
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settings.pickModule(card.modelData.key)
                    }
                }
            }
        }
    }
}
