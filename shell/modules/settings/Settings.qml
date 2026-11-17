import QtQuick
import qs.config
import qs.components
import qs.services
import "../../utils/Banner.js" as Banner
import "../../utils/Lock.js" as Lock
import "../../utils/Geometry.js" as Geometry
import "../../utils/Schema.js" as Schema

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
    property bool canLimitCharge: false
    property bool isChargeLimited: false
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
    property int lockBlankAfter: 60
    property string wallpaper: ""
    property string wallpaperFolder: ""
    property var widgetsLayout: []
    property var widgetScreens: []
    property string widgetScreen: ""
    property bool canConfigureDisplays: false
    property var outputs: []
    property var outputTrial: ({ phase: "idle" })
    property int outputTrialLeft: 0
    property real screenAspect:height > 0 && width > 0 ? height / width : 0.5625
    property string pickedModule: ""
    property var widgetPreviews: ({})
    property string openingTab: ""
    property string tab: "home"
    property string shownTab: tab
    property string subTab: ""
    property string shownSubTab: subTab
    readonly property bool isPresent: isOpen || burst.isActive || panelBurst.isActive || rising.living > 0
    readonly property string phase: burst.phase
    readonly property bool isContentShown: burst.isOpened
    readonly property var visitor: burst.visitor
    readonly property bool isCarrying: burst.isCarrying
    property real dim: isOpen ? 1 : 0

    readonly property var look: Appearance.settings
    readonly property var tabs: [
        {
            key: "user",
            label: "USER",
            glyph: "user"
        },
        {
            key: "settings",
            label: "SETTINGS",
            glyph: "settings"
        },
        {
            key: "customization",
            label: "CUSTOMIZATION",
            glyph: "brush"
        },
        {
            key: "advanced",
            label: "ADVANCED",
            glyph: "bolt"
        }
    ]
    readonly property var subTabsByTab: ({
            settings: canConfigureDisplays ? [
                {
                    key: "general",
                    label: "GENERAL",
                    glyph: "settings"
                },
                {
                    key: "displays",
                    label: "DISPLAYS",
                    glyph: "display"
                }
            ] : [],
            customization: [
                {
                    key: "wallpaper",
                    label: "WALLPAPER",
                    glyph: "mode-canvas"
                },
                {
                    key: "lock",
                    label: "LOCK SCREEN",
                    glyph: "lock"
                },
                {
                    key: "widgets",
                    label: "WIDGETS",
                    glyph: "grid"
                },
                {
                    key: "pills",
                    label: "PILLS",
                    glyph: "drop"
                },
                {
                    key: "taskbar",
                    label: "TASKBAR",
                    glyph: "style-floating"
                },
                {
                    key: "font",
                    label: "SYSTEM FONT",
                    glyph: "text"
                }
            ],
            advanced: [
                {
                    key: "vados",
                    label: "LINK TO VAD/OS",
                    glyph: "link"
                },
                {
                    key: "services",
                    label: "SERVICES",
                    glyph: "dots"
                }
            ]
        })
    readonly property var subTabs: subTabsByTab[tab] ?? []
    readonly property bool hasSubBar: subTabs.length > 0
    readonly property string shownLabel: tabs.find(entry => entry.key === shownTab)?.label ?? ""
    readonly property string shownSubLabel: (subTabsByTab[shownTab] ?? []).find(entry => entry.key === shownSubTab)?.label ?? ""

    readonly property real rootX: Appearance.taskbar.margin
    readonly property real formWidth: Math.round(width * look.bodyShare * (1 - look.rightSpace) + look.endPadding)
    readonly property real navigationX: rootX + look.inset
    readonly property real subBarX: navigationX + look.navigation.width + look.navigation.gap
    property real contentX: (hasSubBar ? subBarX + look.navigation.width : navigationX + look.navigation.width) + look.contentGap
    readonly property real contentSpan: Math.max(0, formWidth - look.endPadding - (contentX - rootX))
    readonly property real centerY: Math.round(height / 2)
    readonly property bool isLockShown: isContentShown && shownTab === "customization" && shownSubTab === "lock"
    readonly property bool isDisplaysShown: displaysHolder.isShown
    readonly property bool isWidgetsShown: isContentShown && shownTab === "customization" && shownSubTab === "widgets"
    readonly property bool isSideWanted: isContentShown && ((tab === "customization" && (subTab === "lock" || subTab === "widgets")) || (tab === "settings" && subTab === "displays"))
    readonly property var lockRows: arrangeLockRows()
    readonly property real lockContentHeight: lockRows.length > 0 ? lockRows[lockRows.length - 1].y + lockRows[lockRows.length - 1].height : 0
    readonly property var panel: look.lock
    readonly property real bodyRight: rootX + formWidth
    readonly property real panelWidth: Math.max(0, Math.min(panel.width, width - bodyRight - panel.bodyGap))
    readonly property real bodyHeight: Math.max(0, height - (look.top + look.headingHeight) * 2)
    readonly property real panelHeight: Math.max(0, height - panel.edgeGap * 2)
    readonly property real panelTop: Math.round((height - panelHeight) / 2)
    readonly property real lockCardWidth: Math.max(0, panelWidth - panel.padding * 2)
    readonly property real lockX: width - panelWidth + panel.padding
    readonly property real shotStart: burst.formRight - panel.shotInset
    readonly property real shotDistance: width + panel.shotSink - panel.shot / 2 - bodyRight + panel.shotInset
    readonly property bool isPanelWanted: isSideWanted && panelWidth > 0
    readonly property bool isPanelLanded: isPanelWanted && lockShot.isArrived && lockShot.width > shotDistance / 2
    readonly property real panelBodyLeft: width - (panelBurst.form.x + panelBurst.form.width / 2)
    readonly property real panelBodyRight: width - (panelBurst.form.x - panelBurst.form.width / 2)
    readonly property real panelBodyTop: panelBurst.form.y - panelBurst.form.height / 2
    readonly property real panelBodyBottom: panelBurst.form.y + panelBurst.form.height / 2
    readonly property real pageY: content.y + pageArea.y
    readonly property real lockY: panelTop + panel.padding

    signal closeRequested
    signal landed
    signal accentRequested(color value)
    signal sideRequested(string side)
    signal styleRequested(string style)
    signal gatherRequested(string gather)
    signal modeRequested(string mode)
    signal reducedMotionRequested(bool isReduced)
    signal burstStyleRequested(string style)
    signal quietRequested(bool isQuiet)
    signal chargeLimitRequested(bool isLimited)
    signal folderRequested(string kind, string folder)
    signal profileRequested(string field, string value)
    signal pictureRequested
    signal pillRequested(string field, var value)
    signal mediaPlayerRequested(bool isOn)
    signal notificationsRequested(bool isOn)
    signal lockLayoutRequested(var entries)
    signal lockWallpaperRequested(string value)
    signal lockBlankAfterRequested(int seconds)
    signal widgetsLayoutRequested(var entries)
    signal fontRequested(string family)
    signal choiceStyleRequested(string style)
    signal choiceColorRequested(string style, string value)
    signal wallpaperRequested(string path)
    signal wallpaperFolderRequested(string folder)
    signal outputsRequested(var layout)
    signal outputsKept
    signal outputsReverted

    function edgeX(localX, itemWidth) {
        return isMirrored ? width - localX - itemWidth : localX;
    }

    function arrangeLockRows() {
        const result = [];
        let top = 0;
        for (const entry of Lock.modules) {
            const realWidth = entry.columns * width / Lock.columns;
            const realHeight = entry.rows * height / Lock.rows;
            const cardHeight = realWidth > 0 ? Math.round(lockCardWidth * realHeight / realWidth) : 0;
            result.push({
                kind: "module",
                key: entry.key,
                label: entry.label,
                y: top,
                height: look.lock.captionHeight + cardHeight,
                cardHeight: cardHeight,
                realWidth: realWidth,
                realHeight: realHeight
            });
            top += look.lock.captionHeight + cardHeight + look.lock.cardGap;
        }
        return result;
    }


    function pickModule(key) {
        pickedModule = pickedModule === key ? "" : key;
    }

    function pick(key) {
        if (key === tab)
            return;
        tab = key;
    }

    function pickSub(key) {
        subTab = key;
    }

    function step(direction) {
        const index = tabs.findIndex(entry => entry.key === tab);
        const from = index >= 0 ? index : direction > 0 ? -1 : tabs.length;
        pick(tabs[(from + direction + tabs.length) % tabs.length].key);
    }

    function stepSub(direction) {
        if (!hasSubBar)
            return;
        const index = subTabs.findIndex(entry => entry.key === subTab);
        pickSub(subTabs[(index + direction + subTabs.length) % subTabs.length].key);
    }

    onIsLockShownChanged: if (!isLockShown)
        pickedModule = ""
    onTabChanged: {
        const entries = subTabsByTab[tab] ?? [];
        subTab = entries.length > 0 ? entries[0].key : "";
        shownTab = "";
        shownSubTab = "";
        pageSwap.restart();
    }
    onSubTabChanged: {
        shownSubTab = "";
        pageSwap.restart();
    }
    onIsOpenChanged: {
        if (!isOpen)
            return;
        tab = openingTab.length > 0 ? openingTab : "home";
        subTab = subTabs.length > 0 ? subTabs[0].key : "";
        forceActiveFocus();
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
            closeRequested();
        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
            step(1);
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
            step(-1);
        else if (event.key === Qt.Key_Right)
            stepSub(isMirrored ? -1 : 1);
        else if (event.key === Qt.Key_Left)
            stepSub(isMirrored ? 1 : -1);
        else if (shownSubTab === "wallpaper" && (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp))
            wallpaperPage.step(event.key === Qt.Key_PageDown ? 1 : -1);
        else if (isDisplaysShown && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
            displayEditor.confirm();
        else
            return;
        event.accepted = true;
    }

    Timer {
        id: pageSwap
        interval: Motion.settings.pageSwap
        onTriggered: {
            settings.shownTab = settings.tab;
            settings.shownSubTab = settings.subTab;
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

    Reshape {
        id: lockShot
        targetWidth: settings.isPanelWanted ? settings.shotDistance : 0
        targetHeight: targetWidth
        growDuration: Motion.pace(Motion.settings.lockShot)
        shrinkDuration: Motion.pace(Motion.settings.lockShotBack)
        shrinkDelay: Motion.pace(Math.round(Motion.burst.leaveHold + Motion.burst.leave * Motion.burst.leaveShrink))
        overshoot: Motion.settings.lockShotBounce
        arriveShare: Motion.settings.lockShotLand
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

            EdgeShot {
                anchors.fill: parent
                shotStart: settings.shotStart
                shotY: settings.centerY
                shotFrom: settings.panel.shotFrom
                shotSize: settings.panel.shot
                shotStretch: settings.panel.shotStretch
                shotSink: settings.panel.shotSink
                shotSquash: settings.panel.shotSquash
                travel: settings.shotDistance > 0 ? lockShot.width / settings.shotDistance : 0
                edgeX: liquid.width
                corner: settings.panel.corner
                fillet: settings.panel.fillet
            }

            Item {
                anchors.fill: parent
                transform: Scale {
                    origin.x: liquid.width / 2
                    xScale: -1
                }

                Burst {
                    id: panelBurst
                    label: "side panel burst"
                    isShown: settings.isPanelLanded
                    shouldStream: false
                    hasCircle: true
                    isHandingOver: true
                    hasSteps: false
                    ball: settings.panel.shot
                    leaveBall: settings.panel.shot
                    rootX: 0
                    seedX: settings.panel.shot / 2 - settings.panel.shotSink
                    seedY: settings.panelTop + settings.panelHeight / 2
                    formWidth: settings.panelWidth
                    formHeight: settings.panelHeight
                    leftCorner: settings.panel.fillet
                    rightCorner: settings.panel.corner
                    edgePad: settings.look.melt
                    screenHeight: settings.height
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
        anchors.fill: parent
        visible: ascii.presence > 0.01

        mask: Item {
            anchors.fill: parent

            Rectangle {
                x: settings.edgeX(settings.rootX, width)
                width: settings.formWidth
                height: settings.height
                radius: settings.look.corner
            }

            Rectangle {
                x: settings.edgeX(panelClip.clipLeft, width)
                y: panelClip.clipTop
                width: panelBurst.isActive ? Math.max(0, panelClip.clipRight - panelClip.clipLeft) + settings.panel.corner : 0
                height: panelClip.height
                radius: settings.panel.corner
            }
        }

        AsciiBackground {
            id: ascii
            anchors.fill: parent
            isShown: settings.isContentShown && settings.shownTab !== "home"
        }
    }

    Turn {
        x: settings.edgeX(settings.navigationX, width)
        y: settings.height - settings.look.clock.inset - height
        isShown: settings.isContentShown
        enterEasing: Easing.OutBack
        leaveWindow: 0

        Text {
            text: DateTime.time
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: settings.look.clock.size
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Turn {
        x: settings.edgeX(settings.rootX + settings.formWidth - settings.look.clock.inset - width, width)
        y: settings.height - settings.look.clock.inset - height
        isShown: settings.isContentShown
        enterEasing: Easing.OutBack
        leaveWindow: 0

        Text {
            text: Release.version
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.chip
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    TabBar {
        id: navigationBar
        x: settings.edgeX(settings.navigationX, width)
        y: Math.round(settings.centerY - height / 2)
        tabs: settings.tabs
        z: 3
        currentKey: settings.tab
        isShown: settings.isContentShown
        isMirrored: settings.isMirrored
        onPicked: key => settings.pick(key)
    }

    TabBar {
        id: subBar
        x: settings.edgeX(settings.subBarX, width)
        y: Math.round(settings.centerY - height / 2)
        tabs: settings.subTabs
        currentKey: settings.subTab
        z: 2
        isShown: settings.isContentShown && settings.hasSubBar
        isMirrored: settings.isMirrored
        fill: Appearance.color.wash
        ink: Appearance.color.text
        labelFill: Appearance.color.hairline
        glyphFlip: 0
        glyphSpin: Motion.settings.subSpin
        onPicked: key => settings.pickSub(key)
    }

    Item {
        id: content
        x: settings.edgeX(settings.contentX, width)
        y: settings.look.top
        width: settings.contentSpan
        height: settings.height - settings.look.top * 2

        Row {
            id: headingRow
            y: -settings.look.headingLift
            x: settings.edgeX(settings.navigationX, width) - content.x
            height: settings.look.headingHeight - settings.look.headingGap
            spacing: Appearance.unit.medium

            TypedText {
                anchors.bottom: parent.bottom
                target: settings.shownLabel
                isShown: settings.isContentShown
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                leaveBudget: Motion.settings.pageSwap
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: settings.look.heading
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }

            TypedText {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.unit.base / 2
                target: settings.shownSubLabel.length > 0 ? "/  " + settings.shownSubLabel : ""
                isShown: settings.isContentShown
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                leaveBudget: Motion.settings.pageSwap
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.body
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }

        Item {
            id: pageArea
            y: settings.look.headingHeight
            width: content.width
            height: content.height - y

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "home"
                shownKey: settings.shownTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                Item {
                    width: pageArea.width
                    height: pageArea.height

                    Piece {
                        id: bannerPiece
                        x: (pageArea.width - width) / 2
                        y: Math.round(settings.centerY - settings.pageY - height / 2)
                        width: bannerText.implicitWidth
                        height: bannerText.implicitHeight

                        Text {
                            id: bannerText
                            text: Banner.art
                            textFormat: Text.PlainText
                            color: Appearance.color.accent
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
                isMirrored: settings.isMirrored

                ProfileEditor {
                    areaWidth: pageArea.width
                    areaHeight: pageArea.height
                    name: settings.profileName
                    secondName: settings.profileSecondName
                    picture: settings.profilePicture
                    github: settings.profileGithub
                    onProfileRequested: (field, value) => settings.profileRequested(field, value)
                    onPictureRequested: settings.pictureRequested()
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "general"
                shownKey: settings.shownTab === "settings" && (settings.shownSubTab.length === 0 || settings.shownSubTab === "general") ? "general" : ""
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                Row {
                    spacing: settings.look.section.columnGap

                    Column {
                        spacing: settings.look.section.gap

                        Section {
                            title: "MOTION & ANIMATIONS"
                            icon: "animation"

                            OptionGroup {
                                label: "ANIMATIONS"
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
                        }

                        Section {
                            visible: settings.canSwitchMode
                            title: "WINDOW MODE"
                            icon: "window"

                            OptionGroup {
                                options: ["canvas", "desktop"]
                                current: settings.windowMode
                                onPicked: option => settings.modeRequested(option)
                            }
                        }

                        Section {
                            title: "NOTIFICATIONS"
                            icon: "bell"

                            OptionGroup {
                                options: ["open", "quiet"]
                                current: settings.isQuiet ? "quiet" : "open"
                                onPicked: option => settings.quietRequested(option === "quiet")
                            }
                        }

                        Section {
                            visible: settings.canLimitCharge
                            title: "BATTERY"
                            icon: "battery"

                            OptionGroup {
                                label: "CHARGE LIMIT"
                                options: ["full", "80%"]
                                current: settings.isChargeLimited ? "80%" : "full"
                                onPicked: option => settings.chargeLimitRequested(option === "80%")
                            }
                        }

                    }

                    Column {
                        spacing: settings.look.section.gap

                        Section {
                            title: "CAPTURE"
                            icon: "capture"

                            TextField {
                                label: "SCREENSHOTS FOLDER"
                                placeholder: settings.defaultScreenshots
                                value: settings.screenshotFolder
                                fieldWidth: settings.look.section.inner
                                onEdited: value => settings.folderRequested("screenshots", value)
                            }

                            TextField {
                                label: "RECORDINGS FOLDER"
                                placeholder: settings.defaultRecordings
                                value: settings.recordingFolder
                                fieldWidth: settings.look.section.inner
                                onEdited: value => settings.folderRequested("recordings", value)
                            }
                        }

                        SelectionPanel {
                            accent: settings.accent
                            onAccentRequested: value => settings.accentRequested(value)
                            onStyleRequested: style => settings.choiceStyleRequested(style)
                            onColorRequested: (style, value) => settings.choiceColorRequested(style, value)
                        }
                    }
                }
            }

            Page {
                id: displaysHolder
                width: pageArea.width
                height: pageArea.height
                pageKey: "displays"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                DisplayEditor {
                    id: displayEditor
                    outputs: settings.outputs
                    trial: settings.outputTrial
                    trialLeft: settings.outputTrialLeft
                    areaWidth: pageArea.width
                    areaHeight: settings.bodyHeight
                    side: displaySlot
                    onApplyRequested: layout => settings.outputsRequested(layout)
                    onKeepRequested: settings.outputsKept()
                    onRevertRequested: settings.outputsReverted()
                }
            }

            Page {
                id: wallpaperHolder
                width: pageArea.width
                height: pageArea.height
                pageKey: "wallpaper"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                WallpaperPage {
                    id: wallpaperPage
                    width: pageArea.width
                    height: pageArea.height
                    isShown: wallpaperHolder.isShown
                    current: settings.wallpaper
                    folder: settings.wallpaperFolder
                    screenAspect: settings.screenAspect
                    topEdge: -settings.pageY
                    bottomEdge: settings.height - settings.pageY
                    onWallpaperRequested: path => settings.wallpaperRequested(path)
                    onFolderRequested: folder => settings.wallpaperFolderRequested(folder)
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "pills"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                Flow {
                    width: pageArea.width
                    spacing: settings.look.section.columnGap

                    Section {
                        title: "GLASS"

                        Fader {
                            label: "BLUR"
                            value: settings.pillBlur
                            resetValue: Schema.fallbackOf("pills.blur")
                            trackWidth: settings.look.section.inner
                            onMoved: value => settings.pillRequested("blur", value)
                        }

                        Fader {
                            label: "OPACITY"
                            value: settings.pillOpacity
                            resetValue: Schema.fallbackOf("pills.opacity")
                            trackWidth: settings.look.section.inner
                            onMoved: value => settings.pillRequested("opacity", value)
                        }
                    }

                    Section {
                        title: "COLOUR"

                        TextField {
                            label: "HEX"
                            placeholder: "DEFAULT DARK"
                            value: settings.pillColor
                            fieldWidth: settings.look.section.inner
                            onEdited: value => settings.pillRequested("color", value)
                        }
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "taskbar"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                Flow {
                    width: pageArea.width
                    spacing: settings.look.section.columnGap

                    Section {
                        title: "PLACEMENT"

                        OptionGroup {
                            label: "SIDE"
                            options: ["left", "right"]
                            current: settings.taskbarSide
                            onPicked: option => settings.sideRequested(option)
                        }
                    }

                    Section {
                        title: "LOOK"

                        OptionGroup {
                            label: "STYLE"
                            options: ["floating", "fused", "bare"]
                            current: settings.barStyle
                            onPicked: option => settings.styleRequested(option)
                        }
                    }
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "lock"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                LockEditor {
                    layout: settings.lockLayout
                    picked: settings.pickedModule
                    wallpaper: settings.lockWallpaper
                    areaWidth: settings.contentSpan
                    areaHeight: settings.bodyHeight
                    screenAspect: settings.width > 0 ? settings.height / settings.width : 0
                    onLayoutRequested: entries => settings.lockLayoutRequested(entries)
                    onPickRequested: key => settings.pickedModule = key
                    onWallpaperRequested: value => settings.lockWallpaperRequested(value)
                    blankAfter: settings.lockBlankAfter
                    onBlankAfterRequested: seconds => settings.lockBlankAfterRequested(seconds)
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "widgets"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                WidgetEditor {
                    id: widgetEditor
                    layout: settings.widgetsLayout
                    screens: settings.widgetScreens
                    startScreen: settings.widgetScreen
                    wallpaper: settings.wallpaper
                    areaWidth: pageArea.width
                    areaHeight: settings.bodyHeight
                    side: widgetSlot
                    onLayoutRequested: entries => settings.widgetsLayoutRequested(entries)
                }
            }

            Page {
                id: familyHolder
                width: pageArea.width
                height: pageArea.height
                pageKey: "vados"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                FamilyPage {
                    width: pageArea.width
                    isShown: familyHolder.isShown
                }
            }

            Page {
                id: fontHolder
                width: pageArea.width
                height: pageArea.height
                pageKey: "font"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                FontPage {
                    width: pageArea.width
                    isShown: fontHolder.isShown
                    onFontRequested: family => settings.fontRequested(family)
                }
            }

            Page {
                width: pageArea.width
                height: pageArea.height
                pageKey: "services"
                shownKey: settings.shownSubTab
                isContentShown: settings.isContentShown
                isMirrored: settings.isMirrored

                Flow {
                    width: pageArea.width
                    spacing: settings.look.section.columnGap

                    Section {
                        title: "ACTIVITY PILL"

                        OptionGroup {
                            label: "MEDIA PLAYER"
                            options: ["on", "off"]
                            current: settings.isMediaPlayerOn ? "on" : "off"
                            onPicked: option => settings.mediaPlayerRequested(option === "on")
                        }
                    }

                    Section {
                        title: "SYSTEM ROLES"

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
    }

    Item {
        id: panelClip

        readonly property real clipTop: Math.max(settings.panelTop, settings.panelBodyTop)
        readonly property real clipBottom: Math.min(settings.panelTop + settings.panelHeight, settings.panelBodyBottom)
        readonly property real clipLeft: Math.max(settings.width - settings.panelWidth, settings.panelBodyLeft)
        readonly property real clipRight: Math.min(settings.width, settings.panelBodyRight)

        visible: panelBurst.isActive
        x: settings.isMirrored ? settings.width - clipRight : clipLeft
        y: clipTop
        width: Math.max(0, clipRight - clipLeft)
        height: Math.max(0, clipBottom - clipTop)
        clip: true

        MouseArea {
            anchors.fill: parent
        }
    }

    Flickable {
        id: sideView

        parent: panelClip
        x: settings.edgeX(settings.lockX, width) - panelClip.x
        y: settings.panelTop - panelClip.y
        width: settings.lockCardWidth
        height: settings.panelHeight
        topMargin: settings.panel.padding
        bottomMargin: settings.panel.padding
        contentHeight: settings.isWidgetsShown ? widgetEditor.sideHeight : settings.isDisplaysShown ? displayEditor.sideHeight : 0
        enabled: !settings.isLockShown
        interactive: panelBurst.isOpened && contentHeight > height - topMargin - bottomMargin
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        Drift {}

        Page {
            width: sideView.width
            height: sideView.height
            pageKey: "widgets"
            shownKey: settings.shownSubTab
            isContentShown: settings.isContentShown && panelBurst.isOpened
            isMirrored: settings.isMirrored

            Item {
                id: widgetSlot
                width: sideView.width
                height: sideView.height - sideView.topMargin - sideView.bottomMargin
            }
        }

        Page {
            width: sideView.width
            height: sideView.height
            pageKey: "displays"
            shownKey: settings.shownTab === "settings" ? settings.shownSubTab : ""
            isContentShown: settings.isContentShown && panelBurst.isOpened
            isMirrored: settings.isMirrored

            Item {
                id: displaySlot
                width: sideView.width
                height: sideView.height - sideView.topMargin - sideView.bottomMargin
            }
        }
    }

    Flickable {
        id: lockView
        parent: panelClip
        x: settings.edgeX(settings.lockX, width) - panelClip.x
        y: settings.panelTop + settings.panel.padding - panelClip.y
        width: settings.lockCardWidth
        height: settings.panelHeight - settings.panel.padding * 2
        contentHeight: settings.lockContentHeight
        enabled: settings.isLockShown
        interactive: panelBurst.isOpened
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        Drift {}

        Repeater {
            id: cards
            model: settings.lockRows

            Turn {
                id: card

                required property var modelData
                required property int index
                readonly property bool isPicked: settings.pickedModule === modelData.key
                readonly property bool isPlaced: Lock.isPlaced(settings.lockLayout, modelData.key)

                readonly property bool isOnScreen: modelData.y - lockView.contentY < lockView.height && modelData.y + modelData.height - lockView.contentY > 0

                y: modelData.y
                width: settings.lockCardWidth
                height: modelData.height
                isShown: panelBurst.isOpened && settings.isLockShown
                enterDelay: isOnScreen ? index * Motion.settings.stagger : 0
                enterDuration: isOnScreen ? Motion.pill.element : 0
                enterEasing: Easing.OutBack
                leaveWindow: 0
                leaveDuration: isOnScreen ? Motion.pill.leaveElement : 0

                Text {
                    visible: card.modelData.kind === "module"
                    x: settings.look.fieldPadding
                    height: settings.look.lock.captionHeight
                    verticalAlignment: Text.AlignVCenter
                    text: card.modelData.label
                    color: card.isPicked || card.isPlaced ? Appearance.color.accent : Appearance.color.textMuted
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.body
                    font.bold: true
                    font.letterSpacing: Appearance.font.labelSpacing
                }

                Item {
                    visible: card.modelData.kind === "module"
                    y: settings.look.lock.captionHeight
                    width: parent.width
                    height: card.modelData.cardHeight ?? 0
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.lock.corner * card.width / Math.max(1, card.modelData.realWidth ?? 1)
                        color: Appearance.color.raised
                    }

                    Loader {
                        id: preview
                        width: card.modelData.realWidth ?? 0
                        height: card.modelData.realHeight ?? 0
                        scale: width > 0 ? card.width / width : 1
                        transformOrigin: Item.TopLeft
                        active: card.modelData.kind === "module" && panelClip.visible
                        sourceComponent: settings.widgetPreviews[card.modelData.key] ?? null
                    }

                    Binding {
                        target: preview.item
                        property: "isShown"
                        value: card.presence >= settings.panel.contentAt && settings.isLockShown
                        when: preview.item !== null
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.lock.corner * card.width / Math.max(1, card.modelData.realWidth ?? 1)
                        color: "transparent"
                        border.width: card.isPicked ? settings.look.lock.outline * 2 : card.isPlaced ? settings.look.lock.outline : 1
                        border.color: card.isPicked || card.isPlaced ? Appearance.color.accent : Appearance.color.hairline
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
