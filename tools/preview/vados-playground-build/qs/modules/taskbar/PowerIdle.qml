import QtQuick
import qs.config
import qs.services
import qs.components

IdlePill {
    id: powerIdle

    property string armedAction: ""

    idleKey: "power"
    glyphName: "power"
    onIsExpandedChanged: armedAction = ""

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

    Row {
        height: Appearance.taskbar.idleSize
        spacing: 2

        Turn {
            anchors.verticalCenter: parent.verticalCenter
            isShown: powerIdle.isUnfolded
            enterDelay: 0
            enterDuration: Motion.stateDuration
            enterEasing: Easing.OutBack
            leaveWindow: 0

            GlyphButton {
                glyphName: "lock"
                onClicked: Power.lock()
            }
        }

        Turn {
            anchors.verticalCenter: parent.verticalCenter
            isShown: powerIdle.isUnfolded
            enterDelay: Motion.pill.elementStagger
            enterDuration: Motion.stateDuration
            enterEasing: Easing.OutBack
            leaveWindow: 0

            GlyphButton {
                glyphName: "moon"
                onClicked: Power.suspend()
            }
        }

        Turn {
            anchors.verticalCenter: parent.verticalCenter
            isShown: powerIdle.isUnfolded
            enterDelay: 2 * Motion.pill.elementStagger
            enterDuration: Motion.stateDuration
            enterEasing: Easing.OutBack
            leaveWindow: 0

            GlyphButton {
                glyphName: "restart"
                isArmed: powerIdle.armedAction === "restart"
                onClicked: powerIdle.confirm("restart", Power.restart)
            }
        }

        Turn {
            anchors.verticalCenter: parent.verticalCenter
            isShown: powerIdle.isUnfolded
            enterDelay: 3 * Motion.pill.elementStagger
            enterDuration: Motion.stateDuration
            enterEasing: Easing.OutBack
            leaveWindow: 0

            GlyphButton {
                glyphName: "power"
                isArmed: powerIdle.armedAction === "shutdown"
                onClicked: powerIdle.confirm("shutdown", Power.shutdown)
            }
        }
    }
}
