import QtQuick
import qs.config
import qs.components

Item {
    id: tip

    required property Item host
    property Item task: null
    property bool isShown: false
    property real presence: 0
    readonly property string title: task ? host.titleFor(task.appId) : ""
    readonly property real anchorY: task && task.parent && task.pill
        ? task.pill.y + task.parent.y + task.y + task.height / 2
        : -1
    readonly property real reachRight: x + width * presence
    property real heldY: 0
    property bool isRetyping: false

    onTaskChanged: isRetyping = isShown && presence > 0.5

    onAnchorYChanged: {
        if (anchorY >= 0)
            heldY = anchorY
    }

    x: tip.host.inset + Appearance.taskbar.thickness + Appearance.taskbar.tipGap
    y: heldY - height / 2
    width: Math.max(height, Math.min(label.fullWidth, Appearance.taskbar.tipTextLimit) + 26)
    height: Appearance.taskbar.tipHeight
    visible: presence > 0.001

    Behavior on y {
        enabled: tip.presence > 0.5
        NumberAnimation {
            duration: Motion.pace(Motion.tip.follow)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on width {
        enabled: tip.presence > 0.5
        NumberAnimation {
            duration: Motion.pace(Motion.tip.resize)
            easing.type: Easing.OutCubic
        }
    }

    onIsShownChanged: {
        if (!isShown)
            isRetyping = false
        if (isShown) {
            leaving.stop()
            arriving.restart()
        } else {
            arriving.stop()
            leaving.restart()
        }
    }

    NumberAnimation {
        id: arriving
        target: tip
        property: "presence"
        to: 1
        duration: Motion.pace(Motion.tip.pop)
        easing.type: Easing.OutBack
    }

    SequentialAnimation {
        id: leaving
        NumberAnimation {
            target: tip
            property: "presence"
            to: 0
            duration: Motion.pace(Motion.pill.leaveElement)
            easing.type: Easing.InBack
        }
        ScriptAction { script: label.clear() }
    }

    LiquidShape {
        parent: tip.host.isBare ? tip.host.tipShapes : tip.host.liquidShapes
        x: tip.x
        y: tip.y
        width: tip.width
        height: tip.height
        scale: tip.presence
        transformOrigin: Item.Left
    }

    TypedText {
        id: label
        x: 13
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Appearance.taskbar.tipTextLimit)
        clip: true
        target: tip.title
        isShown: tip.isShown
        characterInterval: tip.isRetyping ? Motion.tip.retype : Motion.tip.character
        untypeInterval: tip.isRetyping ? Motion.tip.retypeUntype : Motion.tip.untype
        opacity: tip.presence
        color: Appearance.color.text
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.body
        transform: Upright {
            isMirrored: tip.host.isMirrored
            axis: tip.width / 2 - label.x
        }
    }
}
