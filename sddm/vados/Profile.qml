import QtQuick
import QtQuick.Effects

Column {
    id: profile

    required property var look
    property string name: ""
    property string picture: ""
    property bool canSwitch: false
    property real splash: 1
    property real squash: 1

    signal stepped(int step)

    function ripple() {
        if (look.isReduced)
            return
        rippling.restart()
    }

    onNameChanged: ripple()
    spacing: look.tokens.login.gap

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: profile.look.tokens.login.gap

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            look: profile.look
            label: "<"
            implicitHeight: profile.look.tokens.login.arrow
            visible: profile.canSwitch
            onTapped: profile.stepped(-1)
        }

        Rectangle {
            id: circle

            width: profile.look.tokens.login.profile
            height: width
            radius: width / 2
            scale: profile.squash
            color: profile.look.tokens.color.panel
            border.width: profile.look.tokens.login.ring
            border.color: profile.look.accent

            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width * (1 + (profile.look.tokens.login.splashReach - 1) * profile.splash)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: profile.look.tokens.login.ring
                border.color: profile.look.accent
                opacity: (1 - profile.splash) * profile.look.tokens.login.splashOpacity
                visible: profile.splash < 1
            }

            Text {
                anchors.centerIn: parent
                visible: picture.status !== Image.Ready
                text: profile.name.charAt(0).toUpperCase()
                color: profile.look.accent
                font.family: profile.look.mono
                font.pixelSize: profile.look.tokens.login.profile / 2
                font.bold: true
            }

            Image {
                id: picture

                anchors.fill: parent
                anchors.margins: profile.look.tokens.login.ring * 2
                source: profile.picture === "" ? "" : profile.picture.startsWith("/") ? "file://" + profile.picture : profile.picture
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: width
                sourceSize.height: height
                asynchronous: true
                visible: false
            }

            Rectangle {
                id: roundMask

                anchors.fill: picture
                radius: width / 2
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: picture
                source: picture
                visible: picture.status === Image.Ready
                maskEnabled: true
                maskSource: roundMask
            }
        }

        Pill {
            anchors.verticalCenter: parent.verticalCenter
            look: profile.look
            label: ">"
            implicitHeight: profile.look.tokens.login.arrow
            visible: profile.canSwitch
            onTapped: profile.stepped(1)
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: profile.name.toUpperCase()
        color: profile.look.tokens.color.text
        font.family: profile.look.mono
        font.pixelSize: profile.look.tokens.font.body
        font.letterSpacing: profile.look.tokens.font.labelSpacing
        font.bold: true
    }

    ParallelAnimation {
        id: rippling

        NumberAnimation {
            target: profile
            property: "splash"
            from: 0
            to: 1
            duration: profile.look.tokens.motion.splash
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            NumberAnimation {
                target: profile
                property: "squash"
                to: profile.look.tokens.login.squeeze
                duration: profile.look.tokens.motion.squash
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: profile
                property: "squash"
                to: 1
                duration: profile.look.tokens.motion.splash
                easing.type: Easing.OutElastic
            }
        }
    }
}
