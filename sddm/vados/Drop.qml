import QtQuick

Item {
    id: drop

    required property var look
    required property int order
    property bool isArrived: false
    readonly property bool isShown: isArrived && !look.isLeaving
    default property alias content: holder.data

    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height

    Item {
        id: holder

        anchors.fill: parent
        opacity: drop.isShown ? 1 : 0
        scale: drop.isShown ? 1 : drop.look.tokens.motion.arrivalScale

        Behavior on opacity {
            NumberAnimation {
                duration: drop.look.pace(drop.isShown ? drop.look.tokens.motion.arrival : drop.look.tokens.motion.leave)
                easing.type: drop.isShown ? Easing.OutQuad : Easing.InQuad
            }
        }

        Behavior on scale {
            enabled: !drop.look.isReduced

            SpringAnimation {
                spring: drop.look.tokens.motion.spring
                damping: drop.look.tokens.motion.damping
            }
        }
    }

    Timer {
        interval: drop.look.pace(drop.look.tokens.motion.delay + drop.look.tokens.motion.stagger * drop.order) + 1
        running: true
        onTriggered: drop.isArrived = true
    }
}
