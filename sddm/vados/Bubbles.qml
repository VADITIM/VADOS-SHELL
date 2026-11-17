import QtQuick

Item {
    id: bubbles

    required property var look
    readonly property bool isRising: !look.isReduced && !look.isLeaving

    opacity: isRising ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: bubbles.look.tokens.motion.leave
        }
    }

    Repeater {
        model: bubbles.look.isReduced ? 0 : bubbles.look.tokens.login.bubbles

        Rectangle {
            id: bubble

            readonly property real lift: bubbles.look.tokens.motion.riseShortest + Math.random() * (bubbles.look.tokens.motion.riseLongest - bubbles.look.tokens.motion.riseShortest)

            x: Math.random() * bubbles.width
            y: bubbles.height
            width: bubbles.look.tokens.login.bubbleSmallest + Math.random() * (bubbles.look.tokens.login.bubbleLargest - bubbles.look.tokens.login.bubbleSmallest)
            height: width
            radius: width / 2
            color: bubbles.look.accent
            opacity: bubbles.look.tokens.login.bubbleOpacity

            SequentialAnimation on y {
                running: bubbles.isRising
                loops: Animation.Infinite

                PauseAnimation {
                    duration: Math.random() * bubble.lift
                }

                NumberAnimation {
                    from: bubbles.height + bubble.height
                    to: -bubble.height
                    duration: bubble.lift
                }
            }
        }
    }
}
