import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.state
import qs.modules.lock
import "../utils/Locking.js" as Locking

Scope {
    id: window

    property string draft: ""
    property var leaving: []
    readonly property var screenNames: Array.from(Quickshell.screens, screen => screen.name)
    readonly property string mainScreen: Locking.mainScreenOf(screenNames, Lock.screenName)
    readonly property var placements: Locking.layoutOf(Config.data.lock.layout)
    readonly property string background: Config.data.lock.wallpaper.length > 0 ? Config.data.lock.wallpaper : Config.data.wallpaper.path
    readonly property bool isMirrored: Config.data.taskbar.side === "right"

    function isPlaced(key) {
        return placements.some(placement => placement.key === key)
    }

    function press(event) {
        event.accepted = true
        if (Lock.isChecking)
            return
        const typed = Locking.typeInto(draft, event.key, event.text, event.modifiers)
        draft = typed.draft
        if (typed.password.length > 0)
            Lock.submit(typed.password)
    }

    function hold() {
        for (const key of Overlays.stack.slice())
            Overlays.close(key)
        ActivityState.closeClipboard()
        for (const screenName of screenNames)
            Overlays.holdTaskbar(screenName)
    }

    function finish(screenName) {
        Overlays.releaseTaskbar(screenName)
        leaving = leaving.filter(name => name !== screenName)
    }

    function finishAll() {
        for (const screenName of leaving.slice())
            finish(screenName)
    }

    Component.onCompleted: if (Lock.isLocked) hold()

    Connections {
        target: Lock

        function onIsLockedChanged() {
            if (!Lock.isLocked)
                return
            window.draft = ""
            window.leaving = []
            backstop.stop()
            window.hold()
        }

        function onUnlocked() {
            window.draft = ""
            window.leaving = window.screenNames.slice()
            backstop.restart()
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (Lock.isLocked)
                window.hold()
        }
    }

    Timer {
        id: backstop
        interval: Motion.lifecycle.stuck * 2
        onTriggered: window.finishAll()
    }

    Binding {
        target: Weather
        property: "isOnLock"
        value: Lock.isSecure && !Lock.isBlank && window.isPlaced("weather")
    }

    Binding {
        target: Hardware
        property: "isOnLock"
        value: Lock.isSecure && !Lock.isBlank && window.isPlaced("dashboard")
    }

    WlSessionLock {
        id: session
        locked: Lock.isLocked
        onLockedChanged: if (!locked) Lock.reportLost()
        onSecureChanged: Lock.reportSecure(secure)

        WlSessionLockSurface {
            id: surface

            readonly property string screenName: screen?.name ?? ""

            color: Appearance.color.shadow

            Item {
                id: keys
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => window.press(event)
                Component.onCompleted: forceActiveFocus()

                LockScreen {
                    anchors.fill: parent
                    isLocked: Lock.isLocked
                    isMain: surface.screenName === window.mainScreen
                    layout: Config.data.lock.layout
                    wallpaper: window.background
                    parts: Overlays.taskbarParts[surface.screenName] ?? []
                    origin: Overlays.taskbarOrigins[surface.screenName]?.power ?? null
                    isMirrored: window.isMirrored
                    passwordLength: window.draft.length
                    isChecking: Lock.isChecking
                    message: Lock.message
                    isMessageError: Lock.isMessageError
                    isBlank: Lock.isBlank
                    profileName: Config.data.profile.name
                    profilePicture: Config.data.profile.picture
                }
            }
        }
    }

    Variants {
        model: Array.from(Quickshell.screens).filter(screen => window.leaving.indexOf(screen.name) >= 0)

        PanelWindow {
            id: afterglow

            required property ShellScreen modelData
            readonly property string screenName: modelData.name

            screen: modelData
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "vados-unlock"
            color: "transparent"
            mask: Region {}

            LockLeave {
                anchors.fill: parent
                isMain: afterglow.screenName === window.mainScreen
                layout: Config.data.lock.layout
                parts: Overlays.taskbarParts[afterglow.screenName] ?? []
                isMirrored: window.isMirrored
                onSpilled: Overlays.releaseTaskbar(afterglow.screenName)
                onLanded: window.finish(afterglow.screenName)
            }
        }
    }
}
