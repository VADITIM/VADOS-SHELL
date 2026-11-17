import QtQuick
import QtQuick.Effects
import QtQml.Models

Rectangle {
    id: root

    property var users: []
    property var sessions: []
    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    readonly property var user: users[userIndex] ?? null
    readonly property var session: sessions[sessionIndex] ?? null
    readonly property string previousMark: "previous.vados"
    readonly property bool isPrevious: Qt.application.domain === previousMark

    function step(index, count, by) {
        return count > 0 ? (index + by + count) % count : 0
    }

    function listed(list, index, object) {
        const next = list.slice()
        next[index] = object
        return next
    }

    width: 1920
    height: 1080
    color: look.tokens.color.ground

    Look {
        id: look

        settings: config
        isLeaving: root.isPrevious
    }

    Instantiator {
        model: userModel
        onObjectAdded: (index, object) => root.users = root.listed(root.users, index, object)

        delegate: QtObject {
            required property string name
            required property string realName
            required property string icon
        }
    }

    Instantiator {
        model: sessionModel
        onObjectAdded: (index, object) => root.sessions = root.listed(root.sessions, index, object)

        delegate: QtObject {
            required property string name
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            login.fail("Wrong password")
        }

        function onInformationMessage(message) {
            login.message = message
        }
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        source: look.background === "" ? "" : look.background.startsWith("/") ? "file://" + look.background : look.background
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width
        sourceSize.height: height
        asynchronous: true
        visible: look.isLite && status === Image.Ready
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: !look.isLite && wallpaper.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: look.tokens.login.blur
    }

    Rectangle {
        anchors.fill: parent
        visible: wallpaper.status === Image.Ready
        color: look.tokens.color.shadow
        opacity: look.tokens.login.dim
    }

    Bubbles {
        anchors.fill: parent
        look: look
    }

    Column {
        id: middle

        anchors.centerIn: parent
        spacing: look.tokens.login.gap * 2

        Drop {
            anchors.horizontalCenter: parent.horizontalCenter
            look: look
            order: 0

            Clock {
                look: look
            }
        }

        Drop {
            anchors.horizontalCenter: parent.horizontalCenter
            look: look
            order: 1
            onIsArrivedChanged: profile.ripple()

            Profile {
                id: profile

                look: look
                name: root.user ? (root.user.realName || root.user.name) : sddm.hostName
                picture: root.user ? root.user.icon : ""
                canSwitch: root.users.length > 1
                onStepped: step => root.userIndex = root.step(root.userIndex, root.users.length, step)
            }
        }

        Drop {
            id: loginDrop

            anchors.horizontalCenter: parent.horizontalCenter
            look: look
            order: 2

            Login {
                id: login

                look: look
                isSpread: loginDrop.isShown
                isCapsLock: keyboard.capsLock
                onSubmitted: password => sddm.login(root.user ? root.user.name : "", password, root.sessionIndex)
            }
        }

        Drop {
            anchors.horizontalCenter: parent.horizontalCenter
            look: look
            order: 4

            Pill {
                look: look
                label: "SESSION  " + (root.session ? root.session.name.toUpperCase() : "")
                visible: root.sessions.length > 0
                onTapped: root.sessionIndex = root.step(root.sessionIndex, root.sessions.length, 1)
                Keys.onRightPressed: root.sessionIndex = root.step(root.sessionIndex, root.sessions.length, 1)
                Keys.onLeftPressed: root.sessionIndex = root.step(root.sessionIndex, root.sessions.length, -1)
            }
        }
    }

    Drop {
        anchors.right: middle.left
        anchors.rightMargin: look.tokens.login.gap * 2
        anchors.verticalCenter: middle.verticalCenter
        look: look
        order: 3

        Column {
            spacing: look.tokens.login.gap / 2

            Pill {
                width: look.tokens.login.power
                look: look
                label: "SUSPEND"
                visible: sddm.canSuspend
                onTapped: sddm.suspend()
            }

            Armed {
                width: look.tokens.login.power
                look: look
                title: "RESTART"
                visible: sddm.canReboot
                onConfirmed: sddm.reboot()
            }

            Armed {
                width: look.tokens.login.power
                look: look
                title: "SHUT DOWN"
                visible: sddm.canPowerOff
                onConfirmed: sddm.powerOff()
            }
        }
    }

    Drop {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: look.tokens.login.gap * 2
        look: look
        order: 5

        Pill {
            look: look
            label: "PREVIOUS"
            onTapped: Qt.application.domain = root.previousMark
        }
    }

    Loader {
        id: previous

        anchors.fill: parent
        active: root.isPrevious
        focus: root.isPrevious
        source: "qrc:/theme/Main.qml"
        opacity: status === Loader.Ready ? 1 : 0
        onLoaded: previous.forceActiveFocus()

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: look.pace(look.tokens.motion.leave)
                }

                NumberAnimation {
                    duration: look.pace(look.tokens.motion.arrival)
                }
            }
        }
    }

    Component.onCompleted: login.field.forceActiveFocus()
}
