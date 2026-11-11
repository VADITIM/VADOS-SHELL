import QtQuick
import qs.config
import qs.state
import qs.services
import qs.modules.settings

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

    Settings {
        id: settings
        anchors.fill: parent
        isOpen: window.isOpen
        parts: window.parts
        isMirrored: Config.data.taskbar.side === "right"
        canHandOff: window.canHandOff
        isHandingOver: window.isHandingOver
        hasCircle: window.hasCircle
        onVisitorChanged: window.placeVisitor(visitor)
        onIsCarryingChanged: window.carry(isCarrying)
        accent: Appearance.color.accent
        taskbarSide: Config.data.taskbar.side
        barStyle: Config.data.taskbar.style
        windowMode: Config.data.desktop.mode
        canSwitchMode: Confinement.canConfine
        isReducedMotion: Config.data.motion.reduced
        isQuiet: Config.data.attention.doNotDisturb
        profileName: Config.data.profile.name
        profileSecondName: Config.data.profile.secondName
        profilePicture: Config.data.profile.picture
        profileGithub: Config.data.profile.github
        pillOpacity: Config.data.pills.opacity
        pillBlur: Config.data.pills.blur
        pillColor: Config.data.pills.color
        isMediaPlayerOn: Config.data.services.mediaPlayer
        isNotificationsOn: Config.data.notifications.enabled
        lockLayout: Config.data.lock.layout
        lockWallpaper: Config.data.lock.wallpaper
        onLockLayoutRequested: entries => Config.setLockLayout(entries)
        onLockWallpaperRequested: value => Config.setLockWallpaper(value)
        onProfileRequested: (field, value) => ({
            name: Config.setProfileName,
            secondName: Config.setProfileSecondName,
            picture: Config.setProfilePicture,
            github: Config.setProfileGithub
        })[field](value)
        onPictureRequested: window.choosePicture()
        onPillRequested: (field, value) => ({
            opacity: Config.setPillOpacity,
            blur: Config.setPillBlur,
            color: Config.setPillColor
        })[field](value)
        onMediaPlayerRequested: isOn => Config.setMediaPlayer(isOn)
        onNotificationsRequested: isOn => Config.setNotificationsEnabled(isOn)
        onCloseRequested: window.requestClose()
        onLanded: window.land()
        onAccentRequested: value => Config.setAccent(value.toString())
        onSideRequested: side => Config.setTaskbarSide(side)
        onStyleRequested: style => Config.setTaskbarStyle(style)
        onModeRequested: mode => Config.setWindowMode(mode)
        onReducedMotionRequested: isReduced => Config.setReducedMotion(isReduced)
        onQuietRequested: isQuiet => Config.setDoNotDisturb(isQuiet)
    }
}
