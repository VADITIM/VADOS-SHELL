import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: powerIdle

    property string armedAction: ""
    property string floodAction: "shutdown"
    readonly property bool isConfirming: armedAction.length > 0
    readonly property var glyphs: ({ "lock": "lock", "suspend": "moon", "restart": "restart", "logout": "logout", "shutdown": "power" })
    readonly property string shownAction: isConfirming ? armedAction : "shutdown"

    idleKey: "power"
    glyphName: glyphs[shownAction] ?? "power"
    expandedGlyphColor: Appearance.color.powerColors[shownAction] ?? Appearance.color.powerColors["shutdown"]
    isGlyphAction: true
    glyphHoverName: "SHUT DOWN"
    isNaming: !isConfirming
    isFlooded: isConfirming
    floodColor: Appearance.color.powerColors[floodAction] ?? Appearance.color.powerColors["shutdown"]
    onIsExpandedChanged: armedAction = ""
    onArmedActionChanged: if (armedAction.length > 0) floodAction = armedAction
    onActivated: isConfirming ? confirm(armedAction, runOf(armedAction)) : confirm("shutdown", Power.shutdown)

    function runOf(action) {
        switch (action) {
        case "restart":
            return Power.restart
        case "logout":
            return Power.logOut
        default:
            return Power.shutdown
        }
    }

    function confirm(action, run) {
        if (armedAction === action) {
            armedAction = ""
            run()
            return
        }
        armedAction = action
        disarm.restart()
    }

    Timer {
        id: disarm
        interval: 2400
        onTriggered: powerIdle.armedAction = ""
    }

    Item {
        width: actions.width
        height: Appearance.taskbar.idleSize

        Row {
            id: actions
            height: parent.height
            spacing: 2

            Turn {
                anchors.verticalCenter: parent.verticalCenter
                isShown: powerIdle.isUnfolded && !powerIdle.isConfirming
                enterDelay: 0
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    glyphName: "lock"
                    hoverName: "LOCK"
                    color: Appearance.color.powerColors["lock"]
                    onClicked: Power.lock()
                }
            }

            Turn {
                anchors.verticalCenter: parent.verticalCenter
                isShown: powerIdle.isUnfolded && !powerIdle.isConfirming
                enterDelay: Motion.pill.elementStagger
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    glyphName: "moon"
                    hoverName: "SLEEP"
                    color: Appearance.color.powerColors["suspend"]
                    onClicked: Power.suspend()
                }
            }

            Turn {
                anchors.verticalCenter: parent.verticalCenter
                isShown: powerIdle.isUnfolded && !powerIdle.isConfirming
                enterDelay: 2 * Motion.pill.elementStagger
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    glyphName: "restart"
                    hoverName: "RESTART"
                    color: Appearance.color.powerColors["restart"]
                    onClicked: powerIdle.confirm("restart", Power.restart)
                }
            }

            Turn {
                anchors.verticalCenter: parent.verticalCenter
                isShown: powerIdle.isUnfolded && !powerIdle.isConfirming
                enterDelay: 3 * Motion.pill.elementStagger
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    glyphName: "logout"
                    hoverName: "LOG OUT"
                    color: Appearance.color.powerColors["logout"]
                    onClicked: powerIdle.confirm("logout", Power.logOut)
                }
            }
        }

        ScrambleText {
            id: confirmText
            anchors.centerIn: parent
            label: "power confirm"
            target: "CONFIRM"
            isShown: powerIdle.isUnfolded && powerIdle.isConfirming
            color: Appearance.color.text
        }

        MouseArea {
            anchors.fill: parent
            visible: powerIdle.isConfirming
            cursorShape: Qt.PointingHandCursor
            onClicked: powerIdle.confirm(powerIdle.armedAction, powerIdle.runOf(powerIdle.armedAction))
        }
    }
}
