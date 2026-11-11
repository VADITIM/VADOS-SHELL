import QtQuick
import qs.config
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
    property bool isShown: false
    property bool isSelected: false
    property bool isMenuTarget: false
    readonly property var look: Appearance.dashboard.task
    readonly property var fields: ({ name: name, count: count, cpu: cpu, cpuTime: cpuTime, memory: memory, disk: disk, network: network })
    readonly property bool isOverflowing: label.implicitWidth > nameBox.width

    signal picked()
    signal opened()
    signal menuRequested(real x, real y)

    height: look.row

    Turn {
        id: face
        width: row.width
        height: row.height
        isShown: row.isShown
        enterDelay: Math.min(row.index, Motion.dashboard.taskStaggerRows) * Motion.dashboard.taskStagger
        leaveWindow: 0

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: row.isSelected || row.isMenuTarget ? Qt.alpha(Appearance.color.accent, row.look.selection) : Appearance.color.wash
            opacity: row.isSelected || row.isMenuTarget || area.containsMouse ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                    easing.type: Easing.OutQuad
                }
            }
        }

        Item {
            id: nameBox
            x: row.look.cellPadding
            width: row.nameWidth - row.look.cellPadding * 2
            height: row.height
            clip: true

            Text {
                id: label
                visible: !row.isOverflowing
                anchors.verticalCenter: parent.verticalCenter
                text: row.name
                color: row.isSelected ? Appearance.color.accent : Appearance.color.textBody
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.body
            }

            Masked {
                anchors.fill: parent
                visible: row.isOverflowing
                mask: Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "white" }
                        GradientStop { position: Math.max(0, 1 - row.look.fade / Math.max(1, nameBox.width)); color: "white" }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: label.text
                    color: label.color
                    font: label.font
                }
            }
        }

        Text {
            visible: row.count > 1
            x: Math.min(nameBox.x + label.implicitWidth + row.look.cellPadding, row.nameWidth - width - row.look.cellPadding)
            anchors.verticalCenter: parent.verticalCenter
            text: row.count
            color: Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.chip
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
                    anchors.fill: parent
                    anchors.topMargin: 1
                    anchors.bottomMargin: 1
                    radius: Appearance.radius.small
                    color: Qt.alpha(Appearance.bandColor(cell.share, Appearance.dashboard.usageBands), row.look.heat * cell.share)
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: row.look.cellPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: ProcessTable.cell(row.fields, cell.modelData.key)
                    color: Appearance.color.textBody
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.chip
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
