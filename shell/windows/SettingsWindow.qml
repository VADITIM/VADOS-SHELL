import QtQuick
import Quickshell
import qs.config
import qs.state
import qs.services
import qs.modules.settings
import qs.modules.lock

OverlayWindow {
    id: window

    overlayKey: "settings"
    isPresent: settings.isPresent
    phase: settings.phase

    function choosePicture() {
        const screenName = window.screenName
        if (!FileChooser.choose("Profile picture", "picture", files => {
            if (files.length > 0)
                Config.setProfilePicture("file://" + files[0])
            Overlays.open("settings", screenName)
        }))
            return
        window.requestClose()
    }

    Binding {
        target: GitHub
        property: "isActive"
        value: true
        when: window.isPresent
        restoreMode: Binding.RestoreValue
    }

    Binding {
        target: Compositor
        property: "isWatchingOutputs"
        value: settings.isDisplaysShown
    }

    Binding {
        target: Boot
        property: "isWatching"
        value: settings.isServicesShown
    }

    Binding {
        target: Login
        property: "isWatching"
        value: settings.isServicesShown
    }

    Connections {
        target: Boot

        function onApplied(isSplash, isPlymouth) {
            Config.setBootSplash(isSplash)
            Config.setBootPlymouth(isPlymouth)
        }
    }

    LockPreviews {
        id: lockPreviews
    }

    Settings {
        id: settings
        anchors.fill: parent
        isOpen: window.isOpen
        widgetPreviews: lockPreviews.byKey
        openingTab: Overlays.pageOf("settings")
        parts: window.parts
        shouldStream: window.shouldStream
        isMirrored: Config.data.taskbar.side === "right"
        canHandOff: window.canHandOff
        isHandingOver: window.isHandingOver
        hasCircle: window.hasCircle
        onVisitorChanged: window.placeVisitor(visitor)
        onIsCarryingChanged: window.carry(isCarrying)
        accent: Appearance.color.accent
        taskbarSide: Config.data.taskbar.side
        taskbarOverlap: Config.data.taskbar.overlap
        taskbarOrder: Config.data.taskbar.order
        taskbarHidden: Config.data.taskbar.hidden
        taskbarGather: Config.data.taskbar.gather
        windowMode: Config.data.desktop.mode
        canSwitchMode: Confinement.canConfine
        isReducedMotion: Config.data.motion.reduced
        burstStyle: Config.data.motion.burst
        isQuiet: Config.data.attention.doNotDisturb
        canLimitCharge: Battery.canLimit
        isChargeLimited: Config.data.battery.limit
        screenshotFolder: Config.data.capture.screenshots
        recordingFolder: Config.data.capture.recordings
        defaultScreenshots: Capture.defaultScreenshots
        defaultRecordings: Capture.defaultRecordings
        onFolderRequested: (kind, folder) => kind === "screenshots" ? Config.setScreenshotFolder(folder) : Config.setRecordingFolder(folder)
        profileName: Config.data.profile.name
        profileSecondName: Config.data.profile.secondName
        profilePicture: Config.data.profile.picture
        profileGithub: Config.data.profile.github
        profileFavorites: Config.data.profile.favorites
        isMediaPlayerOn: Config.data.services.mediaPlayer
        isDashboardWeatherOn: Config.data.dashboard.weather
        isNotificationsOn: Config.data.notifications.enabled
        isPromptsOn: Config.data.prompts.enabled
        lockLayout: Config.data.lock.layout
        lockWallpaper: Config.data.lock.wallpaper
        lockBlankAfter: Config.data.lock.blankAfter
        wallpaper: Config.data.wallpaper.path
        wallpaperFolder: Config.data.wallpaper.folder
        widgetsLayout: Config.data.widgets.layout
        keyboardLayouts: Config.data.keyboard.layouts
        widgetScreens: Array.from(Quickshell.screens, screen => ({ name: screen.name, width: screen.width, height: screen.height }))
        widgetScreen: window.screenName
        onWidgetsLayoutRequested: entries => Config.setWidgetsLayout(entries)
        canConfigureDisplays: Compositor.capabilities.outputConfiguration
        outputs: Compositor.outputs
        outputTrial: Compositor.outputTrial
        outputTrialLeft: Compositor.outputTrialLeft
        onOutputsRequested: layout => Compositor.applyOutputs(layout)
        onOutputsKept: Compositor.keepOutputs()
        onOutputsReverted: Compositor.revertOutputs()
        onWallpaperRequested: path => {
            Config.setWallpaper(path)
            Compositor.setBackground(path)
        }
        onWallpaperFolderRequested: folder => Config.setWallpaperFolder(folder)
        onChoiceStyleRequested: style => Config.setChoiceStyle(style)
        onPillToneRequested: tone => Config.setPillTone(tone)
        onChoiceColorRequested: (style, value) => style === "pill" ? Config.setChoicePill(value) : Config.setChoiceOutline(value)
        onLockLayoutRequested: entries => Config.setLockLayout(entries)
        onLockWallpaperRequested: value => Config.setLockWallpaper(value)
        onLockBlankAfterRequested: seconds => Config.setLockBlankAfter(seconds)
        onKeyboardLayoutsRequested: entries => {
            Config.setKeyboardLayouts(entries)
            Compositor.applyKeyboardLayouts(entries)
        }
        onFontRequested: family => {
            Config.setSystemFont(family)
            if (family.length > 0)
                SystemFont.apply(family)
            else
                SystemFont.restore()
        }
        onProfileRequested: (field, value) => ({
            name: Config.setProfileName,
            secondName: Config.setProfileSecondName,
            picture: Config.setProfilePicture,
            github: Config.setProfileGithub
        })[field](value)
        onPictureRequested: window.choosePicture()
        onFavoritesRequested: names => Config.setProfileFavorites(names)
        onMediaPlayerRequested: isOn => Config.setMediaPlayer(isOn)
        onDashboardWeatherRequested: isOn => Config.setDashboardWeather(isOn)
        onNotificationsRequested: isOn => Config.setNotificationsEnabled(isOn)
        onPromptsRequested: isOn => Config.setPromptsEnabled(isOn)
        onLoginRequested: choice => Login.request(choice)
        onBootRequested: (part, isOn) => Boot.request(part, isOn, "#" + Appearance.color.accent.toString().slice(-6))
        onCloseRequested: window.requestClose()
        onLanded: window.land()
        onAccentRequested: value => Config.setAccent(value.toString())
        onSideRequested: side => Config.setTaskbarSide(side)
        onOverlapRequested: overlap => Config.setTaskbarOverlap(overlap)
        onOrderRequested: order => Config.setTaskbarOrder(order)
        onHiddenRequested: hidden => Config.setTaskbarHidden(hidden)
        onGatherRequested: gather => Config.setTaskbarGather(gather)
        onModeRequested: mode => Config.setWindowMode(mode)
        onReducedMotionRequested: isReduced => Config.setReducedMotion(isReduced)
        onBurstStyleRequested: style => Config.setBurstStyle(style)
        onQuietRequested: isQuiet => Config.setDoNotDisturb(isQuiet)
        onChargeLimitRequested: isLimited => Config.setBatteryLimit(isLimited)
    }
}
