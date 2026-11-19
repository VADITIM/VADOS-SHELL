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
    property var veiled: []
    property var covered: []
    readonly property var screenNames: Array.from(Quickshell.screens, screen => screen.name)
    readonly property string mainScreen: Locking.mainScreenOf(screenNames, Lock.screenName)
    readonly property var placements: Locking.layoutOf(Config.data.lock.layout)
    readonly property string background: Config.data.lock.wallpaper.length > 0 ? Config.data.lock.wallpaper : Config.data.wallpaper.path
    readonly property bool isMirrored: Config.data.taskbar.side === "right"
    readonly property bool isVeiling: Lock.isLocking || Lock.isLocked

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

    function begin() {
        backstop.stop()
        covered = []
        veiled = screenNames.slice()
        hold()
    }

    function cover(screenName) {
        if (covered.indexOf(screenName) < 0)
            covered = covered.concat([screenName])
        if (Lock.isLocking && screenNames.every(name => covered.indexOf(name) >= 0))
            Lock.lock()
    }

    function placeVisitor(screenName, visitor) {
        Overlays.placeVisitor("lock", screenName, visitor)
        if (visitor && visitor.release > 0 && !window.isVeiling)
            Overlays.releaseTaskbar(screenName)
    }

    function finish(screenName) {
        Overlays.placeVisitor("lock", screenName, null)
        Overlays.releaseTaskbar(screenName)
        veiled = veiled.filter(name => name !== screenName)
        covered = covered.filter(name => name !== screenName)
    }

    function finishAll() {
        for (const screenName of veiled.slice())
            finish(screenName)
    }

    Component.onCompleted: {
        if (isVeiling)
            begin()
    }

    Connections {
        target: Lock

        function onIsLockingChanged() {
            if (!Lock.isLocking)
                return
            window.draft = ""
            window.begin()
        }

        function onIsLockedChanged() {
            if (Lock.isLocked && window.veiled.length === 0) {
                window.draft = ""
                window.begin()
            }
        }

        function onUnlocked() {
            window.draft = ""
            backstop.restart()
        }
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            if (!window.isVeiling)
                return
            window.hold()
            window.veiled = window.screenNames.slice()
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
        model: Quickshell.screens

        PanelWindow {
            id: veilWindow

            required property ShellScreen modelData
            readonly property string screenName: modelData.name
            readonly property bool isMain: screenName === window.mainScreen
            readonly property bool isVeiled: window.veiled.indexOf(screenName) >= 0
            property Region blocking: Region {
                item: veilArea
            }
            property Region passing: Region {}

            screen: modelData
            visible: isVeiled
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "vados-lock"
            color: "transparent"
            mask: Lock.isLocking ? blocking : passing

            Item {
                id: veilArea
                width: veilWindow.modelData.width
                height: veilWindow.modelData.height

                LockVeil {
                    anchors.fill: parent
                    isShown: window.isVeiling && veilWindow.isVeiled
                    isInstant: Lock.isLocked && !Lock.isLocking
                    isMain: veilWindow.isMain
                    layout: Config.data.lock.layout
                    wallpaper: window.background
                    parts: Overlays.taskbarParts[veilWindow.screenName] ?? []
                    groups: Overlays.taskbarGroups[veilWindow.screenName] ?? ({})
                    isMirrored: window.isMirrored
                    canHandOff: !Occupancy.isCovered(veilWindow.screenName, true)
                    onCovered: window.cover(veilWindow.screenName)
                    onVisitorChanged: window.placeVisitor(veilWindow.screenName, visitor)
                    onLanded: window.finish(veilWindow.screenName)
                }
            }
        }
    }
}
