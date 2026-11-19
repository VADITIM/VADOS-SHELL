import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: login

    property Item host: null
    property bool isShown: false
    property bool isLogOutArmed: false
    readonly property var look: Appearance.lock
    readonly property int passwordLength: host?.passwordLength ?? 0
    readonly property bool isChecking: host?.isChecking ?? false
    readonly property string message: host?.message ?? ""
    readonly property bool isMessageError: host?.isMessageError ?? false
    readonly property color fieldColor: isMessageError && passwordLength === 0 ? Appearance.color.danger
        : passwordLength > 0 || isChecking ? Appearance.color.accent
        : Appearance.color.hairline

    anchors.fill: parent
    onPasswordLengthChanged: tick.restart()
    onIsMessageErrorChanged: if (isMessageError) tick.restart()

    Timer {
        id: disarm
        interval: Motion.search.profileDisarm
        onTriggered: login.isLogOutArmed = false
    }

    Timer {
        id: tick
        interval: Motion.press.down
    }

    Press {
        target: field
        isPressed: tick.running
        depth: Motion.lock.keyTick
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - login.look.padding * 2
        spacing: login.look.rowGap

        TypedText {
            target: "PASSWORD"
            isShown: login.isShown
            color: Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }

        Turn {
            id: field
            width: parent.width
            height: login.look.fieldHeight
            isShown: login.isShown
            enterEasing: Easing.OutBack

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "transparent"
                border.width: login.look.caret
                border.color: login.fieldColor

                Behavior on border.color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: login.look.dotGap

                Repeater {
                    model: Math.min(login.passwordLength, login.look.dotLimit)

                    Turn {
                        anchors.verticalCenter: parent.verticalCenter
                        isShown: true
                        isFlipping: false
                        enterDuration: Motion.lock.dot
                        enterEasing: Easing.OutBack

                        Rectangle {
                            width: login.look.dot
                            height: login.look.dot
                            radius: width / 2
                            color: login.isChecking ? Appearance.color.textMuted : Appearance.color.text
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !login.isChecking && login.passwordLength > 0
                    width: login.look.caret
                    height: login.look.caretHeight
                    color: Appearance.color.accent
                }
            }

            TypedText {
                anchors.centerIn: parent
                target: login.isChecking ? "CHECKING" : "TYPE AND PRESS ENTER"
                isShown: login.isShown && login.passwordLength === 0
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }

        TypedText {
            width: parent.width
            target: login.message.toUpperCase()
            isShown: login.isShown && login.message.length > 0
            elide: Text.ElideRight
            color: login.isMessageError ? Appearance.color.danger : Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Turn {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: login.look.padding
        isShown: login.isShown
        enterEasing: Easing.OutBack

        GlyphButton {
            glyphName: "logout"
            label: login.isLogOutArmed ? "CONFIRM" : "LOG OUT"
            color: Appearance.color.powerColors["logout"]
            isArmed: login.isLogOutArmed
            onClicked: {
                if (login.isLogOutArmed) {
                    login.isLogOutArmed = false
                    Power.logOut()
                    return
                }
                login.isLogOutArmed = true
                disarm.restart()
            }
        }
    }
}
