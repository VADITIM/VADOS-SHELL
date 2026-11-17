import QtQuick

Column {
    id: login

    required property var look
    property bool isSpread: false
    property bool isBusy: false
    property bool isCapsLock: false
    property bool isDraining: false
    property string message: ""
    property bool isFailure: false
    property int typed: 0
    property real shift: 0
    readonly property alias field: input

    signal submitted(string password)

    function fail(text) {
        isBusy = false
        isFailure = true
        message = text
        isDraining = true
        input.text = ""
        input.forceActiveFocus()
        draining.restart()
        shake.restart()
    }

    function submit() {
        if (isBusy)
            return
        isBusy = true
        isFailure = false
        message = ""
        submitted(input.text)
    }

    spacing: look.tokens.login.gap / 2

    Rectangle {
        id: body

        x: login.shift + (parent.width - width) / 2
        width: login.isSpread ? login.look.tokens.login.field : login.look.tokens.login.pill
        height: login.look.tokens.login.pill
        radius: height / 2
        color: Qt.rgba(login.look.tokens.color.panel.r, login.look.tokens.color.panel.g, login.look.tokens.color.panel.b, login.look.tokens.login.panelAlpha)
        border.width: login.look.tokens.login.ring
        border.color: login.isFailure ? login.look.tokens.color.danger : input.activeFocus ? login.look.accent : login.look.tokens.color.hairline

        Behavior on width {
            enabled: !login.look.isReduced

            SpringAnimation {
                spring: login.look.tokens.motion.spring
                damping: login.look.tokens.motion.damping
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: login.look.pace(login.look.tokens.motion.state)
            }
        }

        Item {
            id: well

            anchors.left: parent.left
            anchors.right: send.left
            anchors.leftMargin: login.look.tokens.login.padding
            anchors.rightMargin: login.look.tokens.login.gap / 2
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true
            opacity: login.isSpread ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: login.look.pace(login.look.tokens.motion.arrival)
                }
            }

            TextInput {
                id: input

                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: "transparent"
                selectByMouse: false
                cursorDelegate: Item {}
                font.pixelSize: login.look.tokens.font.body
                focus: true
                enabled: !login.isBusy
                onAccepted: login.submit()
                onTextChanged: {
                    if (login.isDraining)
                        return
                    login.typed = text.length
                    if (text.length > 0) {
                        login.isFailure = false
                        login.message = ""
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: login.typed === 0
                text: "PASSWORD"
                color: login.look.tokens.color.textFaint
                font.family: login.look.mono
                font.pixelSize: login.look.tokens.font.label
                font.letterSpacing: login.look.tokens.font.labelSpacing
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.min(0, well.width - width)
                spacing: login.look.tokens.login.dot

                Repeater {
                    model: login.typed

                    Rectangle {
                        width: login.look.tokens.login.dot
                        height: width
                        radius: width / 2
                        color: login.isFailure ? login.look.tokens.color.danger : login.look.accent
                        opacity: login.isDraining ? 0 : 1

                        transform: Translate {
                            y: login.isDraining ? login.look.tokens.login.dotFall : 0

                            Behavior on y {
                                NumberAnimation {
                                    duration: login.look.pace(login.look.tokens.motion.drain)
                                    easing.type: Easing.InQuad
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: login.look.pace(login.look.tokens.motion.drain)
                            }
                        }

                        NumberAnimation on scale {
                            from: 0
                            to: 1
                            duration: login.look.pace(login.look.tokens.motion.dotPop)
                            easing.type: Easing.OutBack
                        }
                    }
                }
            }
        }

        Rectangle {
            id: send

            anchors.right: parent.right
            anchors.rightMargin: (parent.height - height) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: login.look.tokens.login.button
            height: width
            radius: width / 2
            color: login.look.accent
            opacity: login.isBusy ? pulse.value : 1

            Text {
                anchors.centerIn: parent
                text: "→"
                color: login.look.tokens.color.panel
                font.family: login.look.mono
                font.pixelSize: login.look.tokens.font.body
                font.bold: true
            }

            TapHandler {
                onTapped: login.submit()
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: login.message !== "" ? login.message.toUpperCase() : login.isCapsLock ? "CAPS LOCK" : " "
        color: login.message !== "" ? login.look.tokens.color.danger : login.look.tokens.color.levelWarm
        font.family: login.look.mono
        font.pixelSize: login.look.tokens.font.chip
        font.letterSpacing: login.look.tokens.font.labelSpacing
    }

    Item {
        width: login.look.tokens.login.field
        height: 1
    }

    QtObject {
        id: pulse

        property real value: 1

        readonly property SequentialAnimation beat: SequentialAnimation {
            running: login.isBusy && !login.look.isReduced
            loops: Animation.Infinite
            onStopped: pulse.value = 1

            NumberAnimation {
                target: pulse
                property: "value"
                to: login.look.tokens.motion.pulseLow
                duration: login.look.tokens.motion.pulse
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: pulse
                property: "value"
                to: 1
                duration: login.look.tokens.motion.pulse
                easing.type: Easing.InOutSine
            }
        }
    }

    Timer {
        id: draining

        interval: login.look.pace(login.look.tokens.motion.drain) + 1
        onTriggered: {
            login.isDraining = false
            login.typed = input.text.length
        }
    }

    SequentialAnimation {
        id: shake

        NumberAnimation { target: login; property: "shift"; to: login.look.tokens.motion.shakeReach; duration: login.look.pace(login.look.tokens.motion.shake) }
        NumberAnimation { target: login; property: "shift"; to: -login.look.tokens.motion.shakeReach; duration: login.look.pace(login.look.tokens.motion.shake) }
        NumberAnimation { target: login; property: "shift"; to: login.look.tokens.motion.shakeReach / 2; duration: login.look.pace(login.look.tokens.motion.shake) }
        NumberAnimation { target: login; property: "shift"; to: 0; duration: login.look.pace(login.look.tokens.motion.shake) }
    }
}
