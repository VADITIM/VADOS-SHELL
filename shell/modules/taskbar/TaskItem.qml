import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: task

    required property string appId
    required property bool isLeaving
    required property bool isGhost
    required property int index
    required property Item pill
    required property Item host

    readonly property real centre: (pill.tasks.count - 1) / 2
    readonly property real ringShare: centre > 0 ? Math.abs(index - centre) / centre : 1
    readonly property int openingDelay: Math.round(ringShare * pill.outerItemDelay)

    readonly property var group: host.arrangement.groupFor(appId)
    readonly property bool isActive: group ? group.windows.some(window => window.activated) : false
    readonly property int windowCount: group ? group.windows.length : 0
    readonly property bool isLiving: !isLeaving
    readonly property bool isHovered: hover.hovered && !isGhost && !isLeaving
    readonly property bool isPressed: host.pressedAppId === appId && !isGhost
    readonly property bool isAbsorbing: isGhost && !isLeaving && host.isCarrying && host.carryTarget === pill
    readonly property real shownRoom: isAbsorbing ? Math.min(room, host.carryCloseness) : room
    property real room: 0
    property bool isRoomSnapping: false

    width: Appearance.taskbar.thickness
    height: (Appearance.taskbar.item + Appearance.taskbar.itemGap) * shownRoom

    function freezeRoom() {
        isRoomSnapping = true
        room = shownRoom
        isRoomSnapping = false
    }

    Behavior on room {
        enabled: !task.isRoomSnapping
        NumberAnimation {
            duration: Motion.pace(Motion.stateDuration)
            easing.type: Easing.InOutCubic
        }
    }

    Component.onCompleted: room = isLeaving ? 0 : 1
    onIsLeavingChanged: room = isLeaving ? 0 : 1
    onShownRoomChanged: {
        if (shownRoom <= 0 && isLeaving)
            Qt.callLater(() => host.arrangement.discard(pill.pillKey, appId))
    }
    onIsGhostChanged: {
        if (!isGhost)
            face.snap(1)
    }
    onIsHoveredChanged: host.hoverTask(task, isHovered)

    HoverHandler {
        id: hover
    }

    Turn {
        id: face
        anchors.centerIn: parent
        width: Appearance.taskbar.item
        height: Appearance.taskbar.item
        isShown: task.pill.areItemsShown && !task.isLeaving && task.shownRoom > 0.6
        enterDelay: task.pill.isSpreading ? task.openingDelay : 0

        Press {
            target: face
            isPressed: task.isPressed
            isRaised: task.isHovered
            depth: Motion.press.task
        }

        Item {
            anchors.fill: parent
            opacity: task.isGhost ? 0 : 1

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Appearance.color.wash
                opacity: task.isHovered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(task.isHovered ? Motion.hoverIn : Motion.hoverOut)
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Image {
                id: icon
                anchors.centerIn: parent
                width: Appearance.taskbar.icon
                height: Appearance.taskbar.icon
                sourceSize: Qt.size(64, 64)
                source: Toplevels.iconFor(task.appId)
                smooth: true
                mipmap: true
                asynchronous: true
                transform: Upright {
                    isMirrored: task.host.isMirrored
                    axis: icon.width / 2
                }
            }

            Glyph {
                anchors.centerIn: parent
                width: Appearance.taskbar.glyph
                height: Appearance.taskbar.glyph
                visible: icon.status !== Image.Ready
                name: "app"
                color: Appearance.color.textMuted
                transform: Upright {
                    isMirrored: task.host.isMirrored
                    axis: Appearance.taskbar.glyph / 2
                }
            }

            Rectangle {
                x: parent.width + ((Appearance.taskbar.thickness - Appearance.taskbar.item) / 2) - 2 - width
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: task.isActive ? 18 : task.windowCount > 1 ? 9 : 4
                radius: 1.5
                color: task.isActive ? Appearance.color.accent : Appearance.color.textFaint

                Behavior on height {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                        easing.type: Easing.OutBack
                    }
                }
            }
        }
    }
}
