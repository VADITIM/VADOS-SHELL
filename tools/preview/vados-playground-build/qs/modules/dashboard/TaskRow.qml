import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Processes.js" as ProcessTable

Item {
    id: row

    required property int index
    required property string key
    required property string name
    required property int count
    required property real cpu
    required property real cpuTime
    required property real memory
    required property real disk
    required property real network
    property var columns: []
    property var totals: ({})
    property real nameWidth: 0
    property bool hasIcons: false
    property real nameShift: hasIcons ? look.icon + look.iconGap : 0
    property bool isShown: false
    property bool isSelected: false
    property bool isMenuTarget: false
    readonly property var look: Appearance.dashboard.task
    readonly property var fields: ({ name: name, count: count, cpu: cpu, cpuTime: cpuTime, memory: memory, disk: disk, network: network })
    readonly property bool isOverflowing: label.implicitWidth > nameBox.width
    readonly property int enterDelay: Math.min(index, Motion.dashboard.taskStaggerRows) * Motion.dashboard.taskStagger
    readonly property bool isArrived: isShown && face.presence > 0

    signal picked()
    signal opened()
    signal menuRequested(real x, real y)

    height: hasIcons ? look.iconRow : look.row

    Behavior on height {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.taskMove)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on nameShift {
        NumberAnimation {
            duration: Motion.pace(Motion.dashboard.taskMove)
            easing.type: Easing.OutCubic
        }
    }

    Turn {
        id: face
        width: row.width
        height: row.height
        isShown: row.isShown
        isFlipping: false
        enterDelay: row.enterDelay
        enterDuration: Motion.notifications.rowEnter
        leaveDuration: Motion.notifications.rowLeave
        leaveWindow: 0

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: row.isSelected || row.isMenuTarget ? Qt.alpha(Appearance.color.accent, row.look.selection) : Appearance.color.wash
            opacity: (row.isSelected || row.isMenuTarget || area.containsMouse ? 1 : 0) * Math.min(1, face.presence)

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                    easing.type: Easing.OutQuad
                }
            }
        }

        Turn {
            x: row.look.cellPadding
            anchors.verticalCenter: parent.verticalCenter
            width: row.look.icon
            height: row.look.icon
            isShown: row.isArrived && row.hasIcons
            flipAngle: 0
            spinAngle: Motion.notifications.iconSpin
            enterDelay: Motion.dashboard.taskCellStagger
            enterDuration: Motion.notifications.iconEnter
            enterEasing: Easing.OutBack
            leaveDuration: Motion.notifications.rowLeave
            leaveWindow: 0

            Image {
                id: icon
                anchors.fill: parent
                sourceSize: Qt.size(row.look.icon * 2, row.look.icon * 2)
                source: row.hasIcons ? Toplevels.findIcon(row.name) : ""
                smooth: true
                mipmap: true
                asynchronous: true
            }

            Glyph {
                anchors.fill: parent
                visible: icon.status !== Image.Ready
                name: "app"
                color: Appearance.color.textMuted
            }
        }

        LabelReveal {
            id: nameBox
            label: "task row name"
            x: row.look.cellPadding + row.nameShift
            y: (row.height - height) / 2
            width: row.nameWidth - row.look.cellPadding * 2 - row.nameShift
            height: label.implicitHeight
            sweepWidth: Math.min(label.implicitWidth, width)
            isShown: row.isArrived
            leaveDuration: Motion.notifications.rowLeave
            barColor: Appearance.color.accent

            Text {
                id: label
                visible: !row.isOverflowing
                text: row.name
                color: row.isSelected ? Appearance.color.accent : Appearance.color.textBody
                font.family: Appearance.font.mono
                font.pixelSize: row.look.font.name
            }

            Masked {
                width: nameBox.width
                height: nameBox.height
                visible: row.isOverflowing
                mask: Rectangle {
                    width: nameBox.width
                    height: nameBox.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "white" }
                        GradientStop { position: Math.max(0, 1 - row.look.fade / Math.max(1, nameBox.width)); color: "white" }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }

                Text {
                    text: label.text
                    color: label.color
                    font: label.font
                }
            }
        }

        Turn {
            visible: row.count > 1
            x: Math.min(nameBox.x + label.implicitWidth + row.look.cellPadding, row.nameWidth - width - row.look.cellPadding)
            anchors.verticalCenter: parent.verticalCenter
            isShown: row.isArrived
            flipAngle: 0
            spinAngle: Motion.notifications.iconSpin
            enterDelay: Motion.dashboard.taskCellStagger
            enterDuration: Motion.notifications.iconEnter
            enterEasing: Easing.OutBack
            leaveDuration: Motion.notifications.rowLeave
            leaveWindow: 0

            Text {
                text: row.count
                color: Appearance.color.accent
                font.family: Appearance.font.mono
                font.pixelSize: row.look.font.count
            }
        }

        Repeater {
            model: row.columns.slice(1)

            Item {
                id: cell

                required property var modelData
                required property int index
                readonly property real share: ProcessTable.share(row.fields, modelData.key, row.totals)

                x: row.nameWidth + index * row.look.cell
                width: row.look.cell
                height: row.height

                Rectangle {
                    anchors.right: parent.right
                    y: 1
                    width: parent.width * cellTurn.presence
                    height: parent.height - 2
                    radius: Appearance.radius.small
                    color: Qt.alpha(Appearance.bandColor(cell.share, Appearance.dashboard.usageBands), row.look.heat * cell.share)
                }

                Turn {
                    id: cellTurn
                    anchors.right: parent.right
                    anchors.rightMargin: row.look.cellPadding
                    anchors.verticalCenter: parent.verticalCenter
                    isShown: row.isArrived
                    flipAngle: 0
                    enterDelay: (cell.index + 1) * Motion.dashboard.taskCellStagger
                    enterDuration: Motion.notifications.rowEnter
                    enterEasing: Easing.OutBack
                    leaveDuration: Motion.notifications.rowLeave
                    leaveWindow: 0

                    Text {
                        text: ProcessTable.cell(row.fields, cell.modelData.key)
                        color: Appearance.color.textBody
                        font.family: Appearance.font.mono
                        font.pixelSize: row.look.font.cell
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            row.picked()
            if (mouse.button === Qt.RightButton)
                row.menuRequested(mouse.x, mouse.y)
        }
        onDoubleClicked: row.opened()
    }
}
