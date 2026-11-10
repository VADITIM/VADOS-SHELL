import QtQuick
import qs.config
import qs.components
import "../../utils/Alerts.js" as Sources

Item {
    id: alerts

    required property bool isMirrored
    property var peek: null
    property rect body: Qt.rect(0, 0, 0, 0)
    property bool isBodyShown: false
    property var heldPeek: null
    property real slide: 0
    property bool isFollowing: false
    property bool isResetting: false

    readonly property bool isPeeking: peek !== null
    readonly property var lead: Sources.leadOf(heldPeek?.notifications ?? [])
    readonly property var source: Sources.identify(lead?.appName, lead?.desktopEntry)
    readonly property color tint: source.tint.length > 0 ? source.tint : Appearance.color.accent
    readonly property int count: heldPeek?.notifications?.length ?? 0
    readonly property size bodySize: Qt.size(Appearance.alerts.width, Appearance.alerts.height)
    readonly property bool isContentShown: isPeeking && isBodyShown
    readonly property real textLeft: Appearance.alerts.padding + Appearance.alerts.badge + Appearance.alerts.gap
    readonly property real textWidth: Math.max(0, body.width - textLeft - Appearance.alerts.padding)

    signal dismissRequested()
    signal openRequested(var notification)

    transform: Upright {
        isMirrored: alerts.isMirrored
        axis: alerts.width / 2
    }

    onPeekChanged: {
        if (!peek)
            return
        if (heldPeek === null || !isContentShown) {
            isResetting = true
            slide = 0
            isResetting = false
        }
        heldPeek = peek
    }

    Behavior on slide {
        enabled: !alerts.isFollowing && !alerts.isResetting

        NumberAnimation {
            duration: Motion.pace(Motion.alerts.settle)
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: content
        x: alerts.body.x
        y: alerts.body.y
        width: alerts.body.width
        height: alerts.body.height
        visible: alerts.heldPeek !== null && width > 1
        clip: true
        transform: Upright {
            isMirrored: alerts.isMirrored
            axis: content.width / 2
        }

        Item {
            id: face
            x: alerts.slide
            width: content.width
            height: content.height
            opacity: 1 - Math.min(1, Math.abs(alerts.slide) / Math.max(1, content.width))

            Turn {
                x: alerts.isMirrored ? face.width - Appearance.alerts.padding - Appearance.alerts.badge : Appearance.alerts.padding
                y: (face.height - Appearance.alerts.badge) / 2
                width: Appearance.alerts.badge
                height: Appearance.alerts.badge
                isShown: alerts.isContentShown
                enterDuration: Motion.alerts.faceEnter
                leaveDuration: Motion.alerts.faceLeave
                leaveWindow: 0

                Rectangle {
                    width: Appearance.alerts.badge
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: alerts.tint
                    border.width: Appearance.alerts.ring

                    Glyph {
                        anchors.centerIn: parent
                        width: Appearance.alerts.glyph
                        height: width
                        name: alerts.source.glyph
                        color: alerts.tint
                    }
                }
            }

            Column {
                x: alerts.isMirrored ? Appearance.alerts.padding : alerts.textLeft
                width: alerts.textWidth
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.alerts.lineGap

                Turn {
                    width: alerts.textWidth
                    height: label.height
                    isShown: alerts.isContentShown
                    enterDuration: Motion.alerts.faceEnter
                    leaveDuration: Motion.alerts.faceLeave
                    leaveWindow: 0

                    Text {
                        id: label
                        width: alerts.textWidth
                        horizontalAlignment: alerts.isMirrored ? Text.AlignRight : Text.AlignLeft
                        text: alerts.count > 1 ? alerts.source.label + "  +" + (alerts.count - 1) : alerts.source.label
                        color: alerts.tint
                        elide: Text.ElideRight
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                        font.capitalization: Font.AllUppercase
                    }
                }

                Turn {
                    width: alerts.textWidth
                    height: title.height
                    isShown: alerts.isContentShown
                    enterDuration: Motion.alerts.faceEnter
                    enterDelay: Motion.alerts.stagger
                    leaveDuration: Motion.alerts.faceLeave
                    leaveWindow: 0

                    TypedText {
                        id: title
                        width: alerts.textWidth
                        horizontalAlignment: alerts.isMirrored ? Text.AlignRight : Text.AlignLeft
                        target: Sources.clip(alerts.lead?.summary, Appearance.alerts.titleCharacters)
                        isShown: alerts.isContentShown
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        leaveBudget: Motion.alerts.faceLeave
                        elide: Text.ElideRight
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.body
                        font.bold: true
                    }
                }

                Turn {
                    width: alerts.textWidth
                    height: message.height
                    visible: message.target.length > 0
                    isShown: alerts.isContentShown
                    enterDuration: Motion.alerts.faceEnter
                    enterDelay: Motion.alerts.stagger * 2
                    leaveDuration: Motion.alerts.faceLeave
                    leaveWindow: 0

                    TypedText {
                        id: message
                        width: alerts.textWidth
                        horizontalAlignment: alerts.isMirrored ? Text.AlignRight : Text.AlignLeft
                        target: Sources.clip(alerts.lead?.body, Appearance.alerts.bodyCharacters)
                        isShown: alerts.isContentShown
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        leaveBudget: Motion.alerts.faceLeave
                        elide: Text.ElideRight
                        color: Appearance.color.textMuted
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.body
                    }
                }
            }
        }

        Gesture {
            anchors.fill: parent
            enabled: alerts.isContentShown
            isVertical: false
            cursorShape: Qt.PointingHandCursor
            onCrossed: alerts.isFollowing = true
            onMoved: travelX => {
                if (alerts.isFollowing)
                    alerts.slide = travelX
            }
            onThrown: (travelX, travelY, velocityX) => {
                alerts.isFollowing = false
                const isAway = Math.abs(travelX) >= Motion.alerts.swipe || Math.abs(velocityX) >= Motion.alerts.fling
                if (!isAway) {
                    alerts.slide = 0
                    return
                }
                alerts.slide = Math.sign(travelX !== 0 ? travelX : velocityX) * content.width
                alerts.dismissRequested()
            }
            onTapped: alerts.openRequested(alerts.lead)
        }
    }
}
