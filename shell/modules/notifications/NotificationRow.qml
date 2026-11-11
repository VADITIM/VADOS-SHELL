import QtQuick
import qs.config
import qs.components
import "../../utils/Alerts.js" as Sources
import "../../utils/Tint.js" as Tint

Turn {
    id: row

    required property var entry
    property bool isSelected: false
    property real slide: 0
    property bool isFollowing: false
    property bool isGone: false
    readonly property var look: Appearance.notifications
    readonly property var source: Sources.identify(entry.appName, entry.desktopEntry)
    property string iconTint: ""
    readonly property color tint: source.tint.length > 0 ? source.tint : iconTint.length > 0 ? iconTint : Appearance.color.accent
    readonly property color groupTint: Qt.alpha(tint, look.groupFade)
    readonly property string appLabel: (source.label.length > 0 ? source.label : entry.appName || "NOTIFICATION").toUpperCase()
    readonly property string groupLabel: Sources.clip(entry.summary, 28).toUpperCase()
    readonly property string message: Sources.clip(entry.body.length > 0 ? entry.body : entry.summary, 120)
    readonly property bool hasIcon: entry.icon.length > 0 && icon.status !== Image.Error
    readonly property bool isArrived: isShown && presence > 0

    signal activated()
    signal forgotten()
    signal pointed()

    height: look.row
    isFlipping: false
    enterDuration: Motion.notifications.rowEnter
    leaveDuration: Motion.notifications.rowLeave
    leaveWindow: 0

    Behavior on slide {
        enabled: !row.isFollowing

        NumberAnimation {
            duration: Motion.pace(Motion.notifications.settle)
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: face
        x: row.slide
        width: row.width
        height: row.height
        opacity: 1 - Math.min(1, Math.abs(row.slide) / Math.max(1, row.width))

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Appearance.color.wash
            opacity: (row.isSelected || gesture.containsMouse ? 1 : 0) * Math.min(1, row.presence)
        }

        Turn {
            id: badgeTurn
            x: (row.look.row - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: row.look.icon
            height: row.look.icon
            isShown: row.isArrived
            isFlipping: true
            flipAngle: 0
            spinAngle: Motion.notifications.iconSpin
            enterDuration: Motion.notifications.iconEnter
            enterEasing: Easing.OutBack
            leaveDuration: Motion.notifications.rowLeave
            leaveWindow: 0

            Rectangle {
                id: badge
                anchors.fill: parent
                radius: width / 2
                color: Appearance.color.wash
                clip: true

                Image {
                    id: icon
                    anchors.fill: parent
                    visible: row.hasIcon
                    source: row.entry.icon.length > 0 ? (row.entry.icon.startsWith("/") ? "file://" + row.entry.icon : row.entry.icon) : ""
                    sourceSize.width: row.look.icon
                    sourceSize.height: row.look.icon
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    onStatusChanged: if (status === Image.Ready) sampler.requestPaint()
                }

                Glyph {
                    anchors.centerIn: parent
                    visible: !row.hasIcon
                    width: row.look.icon / 2
                    height: width
                    name: row.source.glyph
                    color: row.tint
                }
            }
        }

        Item {
            id: lines
            x: badgeTurn.x + badgeTurn.width + row.look.iconGap
            width: face.width - x - row.look.row / 2
            height: app.height + row.look.lineGap + text.height
            anchors.verticalCenter: parent.verticalCenter

            LabelReveal {
                id: app
                label: "notification app"
                width: appText.implicitWidth
                height: appText.implicitHeight
                isShown: row.isArrived
                leaveDuration: Motion.notifications.rowLeave
                barColor: row.tint

                Text {
                    id: appText
                    text: row.appLabel
                    color: row.tint
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }

            LabelReveal {
                id: group
                anchors.right: parent.right
                label: "notification group"
                width: Math.min(groupText.implicitWidth, lines.width - app.width - row.look.iconGap)
                height: groupText.implicitHeight
                isShown: row.isArrived
                leaveDuration: Motion.notifications.rowLeave
                barColor: row.groupTint

                Text {
                    id: groupText
                    width: group.width
                    text: row.groupLabel
                    elide: Text.ElideRight
                    color: row.groupTint
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }
            }

            TypedText {
                id: text
                y: app.height + row.look.lineGap
                width: lines.width
                target: row.message
                isShown: row.isArrived
                characterInterval: Motion.notifications.typeCharacter
                untypeInterval: Motion.type.quickUntype
                leaveBudget: Motion.notifications.rowLeave
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.body
            }
        }
    }

    Canvas {
        id: sampler
        width: row.look.tint.sample
        height: row.look.tint.sample
        opacity: 0
        enabled: false
        onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)
            context.drawImage(icon, 0, 0, width, height)
            row.iconTint = Tint.dominant(context.getImageData(0, 0, width, height).data, row.look.tint)
        }
    }

    Gesture {
        id: gesture
        anchors.fill: parent
        enabled: row.isShown && !row.isGone
        isVertical: false
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.pointed()
        onCrossed: row.isFollowing = true
        onMoved: travelX => {
            if (row.isFollowing)
                row.slide = travelX
        }
        onThrown: (travelX, travelY, velocityX) => {
            row.isFollowing = false
            const isAway = Math.abs(travelX) >= Motion.alerts.swipe || Math.abs(velocityX) >= Motion.alerts.fling
            if (!isAway) {
                row.slide = 0
                return
            }
            row.isGone = true
            row.slide = Math.sign(travelX !== 0 ? travelX : velocityX) * row.width
            row.forgotten()
        }
        onTapped: row.activated()
    }
}
