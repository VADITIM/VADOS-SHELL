import QtQuick
import qs.config
import qs.components
import "../../utils/Clipboard.js" as Entries

Item {
    id: history

    required property bool isMirrored
    property var entries: []
    property rect body: Qt.rect(0, 0, 0, 0)
    property bool isBodyShown: false
    property bool isBumpHovered: false
    property int first: 0
    property real shift: 0
    property real dragBase: 0
    property bool isScrolling: false
    property bool isJumping: false
    property string swipedKey: ""
    property real slide: 0
    property bool isSwiping: false
    property bool isSliding: false
    property bool hasVisited: false

    readonly property var look: Appearance.clipboard
    readonly property size bodySize: Qt.size(look.width, look.height)
    readonly property var ordered: Entries.shown(entries, entries.length)
    readonly property real pitch: look.row + look.rowGap
    readonly property int lastFirst: Math.max(0, ordered.length - look.rows)
    readonly property bool isContentShown: isBodyShown
    readonly property bool hasLoose: entries.some(entry => !entry.isPinned)
    readonly property int hoveredSlot: hover.hovered && hover.point.position.y >= list.y
        ? Math.floor((hover.point.position.y - list.y - shift) / pitch)
        : -2

    signal pickRequested(var entry)
    signal pinRequested(var entry)
    signal removeRequested(var entry)
    signal clearRequested()
    signal closeRequested()

    transform: Upright {
        isMirrored: history.isMirrored
        axis: history.width / 2
    }

    function entryAt(slot) {
        return ordered[first + slot] ?? null
    }

    function slotAt(y) {
        return Math.floor((y - shift) / pitch)
    }

    function scroll(steps) {
        const target = Math.max(0, Math.min(lastFirst, first + steps))
        if (target === first)
            return
        isJumping = true
        shift += (target - first) * pitch
        first = target
        isJumping = false
        shift = 0
    }

    function follow(travelY) {
        let offset = dragBase + travelY
        while (offset < -pitch / 2 && first < lastFirst) {
            first += 1
            offset += pitch
            dragBase += pitch
        }
        while (offset > pitch / 2 && first > 0) {
            first -= 1
            offset -= pitch
            dragBase -= pitch
        }
        shift = Math.max(-pitch / 2, Math.min(pitch / 2, offset))
    }

    onEntriesChanged: {
        isSliding = true
        slide = 0
        swipedKey = ""
        isSliding = false
        first = Math.min(first, lastFirst)
    }
    onIsBodyShownChanged: {
        if (isBodyShown)
            return
        hasVisited = false
        linger.stop()
    }
    onIsBumpHoveredChanged: {
        if (isBumpHovered)
            linger.stop()
        else if (hasVisited && !hover.hovered)
            linger.restart()
    }

    Behavior on shift {
        enabled: !history.isScrolling && !history.isJumping

        NumberAnimation {
            duration: Motion.pace(Motion.clipboard.scroll)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on slide {
        enabled: !history.isSwiping && !history.isSliding

        NumberAnimation {
            duration: Motion.pace(Motion.clipboard.settle)
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: linger
        interval: Motion.clipboard.linger
        onTriggered: {
            if (!hover.hovered && !history.isBumpHovered)
                history.closeRequested()
        }
    }

    Item {
        id: content
        x: history.body.x
        y: history.body.y
        width: history.body.width
        height: history.body.height
        visible: width > 1 && (history.isBodyShown || badge.presence > 0)
        clip: true
        LayoutMirroring.enabled: history.isMirrored
        LayoutMirroring.childrenInherit: true
        transform: Upright {
            isMirrored: history.isMirrored
            axis: content.width / 2
        }

        HoverHandler {
            id: hover
            enabled: history.isContentShown
            onHoveredChanged: {
                if (hovered) {
                    history.hasVisited = true
                    linger.stop()
                } else if (history.hasVisited && !history.isBumpHovered) {
                    linger.restart()
                }
            }
        }

        Row {
            id: header
            anchors.left: parent.left
            anchors.leftMargin: history.look.padding
            y: history.look.padding
            height: history.look.header
            spacing: history.look.iconGap

            Turn {
                id: badge
                anchors.verticalCenter: parent.verticalCenter
                width: history.look.badge
                height: history.look.badge
                isShown: history.isContentShown
                enterDuration: Motion.clipboard.faceEnter
                leaveDuration: Motion.clipboard.faceLeave
                leaveDelay: Motion.clipboard.leaveStagger * history.look.rows
                leaveWindow: 0

                Rectangle {
                    width: history.look.badge
                    height: width
                    radius: width / 2
                    color: Appearance.color.wash

                    Glyph {
                        anchors.centerIn: parent
                        width: history.look.glyph
                        height: width
                        name: "clipboard"
                        color: Appearance.color.accent
                    }
                }
            }

            Turn {
                anchors.verticalCenter: parent.verticalCenter
                width: title.width
                height: title.height
                isShown: history.isContentShown
                enterDelay: Motion.clipboard.stagger
                enterDuration: Motion.clipboard.faceEnter
                leaveDuration: Motion.clipboard.faceLeave
                leaveWindow: 0

                TypedText {
                    id: title
                    target: "CLIPBOARD"
                    holdsWidth: true
                    isShown: history.isContentShown
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    leaveBudget: Motion.clipboard.faceLeave
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.mono
                    font.pixelSize: history.look.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }

            Turn {
                anchors.verticalCenter: parent.verticalCenter
                width: count.implicitWidth
                height: count.implicitHeight
                isShown: history.isContentShown
                enterDelay: Motion.clipboard.stagger * 2
                enterDuration: Motion.clipboard.faceEnter
                leaveDuration: Motion.clipboard.faceLeave
                leaveWindow: 0

                Text {
                    id: count
                    text: history.entries.length
                    color: Appearance.color.textFaint
                    font.family: Appearance.font.mono
                    font.pixelSize: history.look.label
                    font.bold: true
                }
            }

            Turn {
                id: trash
                anchors.verticalCenter: parent.verticalCenter
                width: history.look.action
                height: history.look.action
                isShown: history.isContentShown && history.hasLoose
                enterDelay: Motion.clipboard.stagger * 3
                enterDuration: Motion.clipboard.faceEnter
                leaveDuration: Motion.clipboard.faceLeave
                leaveWindow: 0

                GlyphButton {
                    anchors.fill: parent
                    glyphName: "trash"
                    glyphSize: history.look.actionGlyph
                    enabled: history.isContentShown && history.hasLoose
                    onClicked: history.clearRequested()
                }
            }
        }

        Item {
            id: list
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: history.look.padding
            anchors.rightMargin: history.look.padding
            y: history.look.padding + history.look.header + history.look.headerGap
            height: history.look.rows * history.look.row + (history.look.rows - 1) * history.look.rowGap
            clip: true

            Gesture {
                anchors.fill: parent
                enabled: history.isContentShown
                cursorShape: Qt.PointingHandCursor
                onCrossed: (travelX, travelY) => {
                    const entry = history.entryAt(history.slotAt(pressPoint.y))
                    if (Math.abs(travelX) > Math.abs(travelY) && entry) {
                        history.swipedKey = entry.key
                        history.isSwiping = true
                        return
                    }
                    history.dragBase = history.shift
                    history.isScrolling = true
                }
                onMoved: (travelX, travelY) => {
                    if (history.isSwiping)
                        history.slide = travelX
                    else if (history.isScrolling)
                        history.follow(travelY)
                }
                onThrown: (travelX, travelY, velocityX) => {
                    if (history.isSwiping) {
                        history.isSwiping = false
                        const isAway = Math.abs(travelX) >= Motion.clipboard.swipe || Math.abs(velocityX) >= Motion.clipboard.fling
                        const entry = history.ordered.find(candidate => candidate.key === history.swipedKey)
                        if (!isAway || !entry) {
                            history.slide = 0
                            return
                        }
                        history.slide = Math.sign(travelX !== 0 ? travelX : velocityX) * list.width
                        history.removeRequested(entry)
                        return
                    }
                    history.isScrolling = false
                    history.shift = 0
                }
                onTapped: mouse => {
                    const entry = history.entryAt(history.slotAt(mouse.y))
                    if (entry)
                        history.pickRequested(entry)
                }
                onWheel: wheel => {
                    if (wheel.angleDelta.y !== 0)
                        history.scroll(wheel.angleDelta.y > 0 ? -1 : 1)
                }
            }

            Repeater {
                model: history.look.rows + 2

                ClipboardRow {
                    required property int index
                    readonly property int slotIndex: index - 1
                    width: list.width
                    height: history.look.row
                    y: slotIndex * history.pitch + history.shift
                    slot: slotIndex
                    entry: history.entryAt(slotIndex)
                    isShown: history.isContentShown
                    isMirrored: history.isMirrored
                    isHovered: history.hoveredSlot === slotIndex && history.isContentShown
                    slide: entry && entry.key === history.swipedKey ? history.slide : 0
                    onPinRequested: history.pinRequested(entry)
                }
            }
        }
    }
}
