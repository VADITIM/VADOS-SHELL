import QtQuick
import qs.config
import qs.components
import "../../utils/Tint.js" as Tint

Item {
    id: card

    property var app: null
    property bool isSelected: false
    property bool isShown: false
    property int enterDelay: 0
    property bool isMirrored: false
    property real nameX: width
    property var shownApp: null
    property bool isSwapping: false
    property bool isSearching: false

    readonly property var look: Appearance.search
    readonly property bool isNamed: card.isShown && !card.isSwapping && card.shownApp !== null
    property real bloom: isNamed ? 1 : 0
    readonly property real nameWidth: Math.min(look.nameLimit, name.implicitWidth) + look.namePadding * 2
    readonly property real nameThickness: look.nameHeight * Math.max(0, Math.min(1, bloom * Motion.search.nameHeightLead))
    readonly property real nameSpan: bloom <= 0 ? 0 : Math.max(nameThickness, nameWidth * bloom)

    signal activated()
    signal menuRequested(point at)
    signal pointed()

    width: look.found
    height: look.found

    onAppChanged: {
        if ((app?.id ?? "") === (shownApp?.id ?? "") || content.presence <= 0)
            shownApp = app
        else
            isSwapping = true
    }
    Component.onCompleted: shownApp = app

    Behavior on bloom {
        SequentialAnimation {
            PauseAnimation { duration: Motion.pace(card.isNamed && frame.presence < 1 ? card.enterDelay : 0) }
            NumberAnimation {
                duration: Motion.pace(card.isNamed ? Motion.search.nameGrow : Motion.search.nameShrink)
                easing.type: card.isNamed ? Easing.OutBack : Easing.InQuad
            }
        }
    }

    Turn {
        id: frame
        anchors.fill: parent
        isShown: card.isShown
        enterDelay: card.enterDelay
        enterDuration: Motion.search.tileEnter
        enterEasing: Easing.OutBack
        leaveWindow: 0

        Press {
            target: frame
            isPressed: area.pressed
            depth: Motion.press.card
        }

        Squircle {
            readonly property bool isTinted: foundIcon.tint.length > 0 && card.shownApp !== null
            anchors.fill: parent
            color: isTinted ? foundIcon.tint : Appearance.color.wash
            shade: isTinted ? Tint.nudge(foundIcon.tint, card.look.foundShade) : Appearance.color.wash
            strokeWidth: card.look.ringStroke
            strokeColor: card.isSelected ? Appearance.color.accent : Appearance.color.hairline

            Behavior on strokeColor {
                ColorAnimation {
                    duration: Motion.pace(Motion.hoverIn)
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.search.swap)
                }
            }

            Behavior on shade {
                ColorAnimation {
                    duration: Motion.pace(Motion.search.swap)
                }
            }
        }

        Turn {
            id: content
            anchors.fill: parent
            isShown: card.isShown && !card.isSwapping
            enterDelay: frame.presence < 1 ? card.enterDelay : 0
            enterDuration: Motion.search.swap
            leaveDuration: Motion.search.swap
            leaveWindow: 0
            onDeparted: {
                if (card.isSwapping) {
                    card.shownApp = card.app
                    card.isSwapping = false
                }
            }

            AppIcon {
                id: foundIcon
                anchors.centerIn: parent
                size: card.look.foundIcon
                isSampled: true
                app: card.shownApp
                visible: card.shownApp !== null
            }

            Text {
                anchors.centerIn: parent
                text: "NO MATCH"
                visible: card.isSearching && card.shownApp === null
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }

    Item {
        id: tag

        readonly property real reach: card.nameX - card.width / 2

        x: card.isMirrored ? card.width / 2 - width : card.width / 2
        y: (card.height - height) / 2
        width: reach + card.nameWidth
        height: card.look.nameHeight

        Rectangle {
            x: card.isMirrored ? card.nameWidth : card.width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, tag.reach - card.width / 2)
            height: card.look.tether
            opacity: Math.max(0, Math.min(1, card.bloom))
            color: card.isSelected ? Appearance.color.accent : Appearance.color.hairline
        }

        Item {
            id: pill
            x: card.isMirrored ? card.nameWidth - width : tag.reach
            anchors.verticalCenter: parent.verticalCenter
            width: card.nameSpan
            height: card.nameThickness
            visible: width > 0.5
            clip: true

            Text {
                id: name
                x: (card.isMirrored ? -pill.x : 0) + card.look.namePadding
                anchors.verticalCenter: parent.verticalCenter
                width: card.nameWidth - card.look.namePadding * 2
                elide: Text.ElideRight
                text: card.shownApp?.name ?? ""
                color: card.isSelected ? Appearance.color.accent : Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: card.look.cardName
                font.bold: true

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.hoverIn)
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: card.pointed()
                onClicked: mouse => mouse.button === Qt.RightButton ? card.menuRequested(mapToItem(null, mouse.x, mouse.y)) : card.activated()
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.shownApp !== null
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: card.pointed()
        onClicked: mouse => mouse.button === Qt.RightButton ? card.menuRequested(mapToItem(null, mouse.x, mouse.y)) : card.activated()
    }
}
