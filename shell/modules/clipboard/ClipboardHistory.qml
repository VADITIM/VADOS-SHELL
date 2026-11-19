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
    property int first: 0
    property real shift: 0
    property real dragBase: 0
    property int thumbBase: 0
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
    readonly property var layout: Entries.layoutOf(ordered, look.imageSpan, look.lineChars)
    readonly property int boundary: Entries.pinnedBoundary(ordered)
    readonly property int poolSize: look.rows + 2
    readonly property int lastFirst: Math.max(0, layout.total - look.rows)
    readonly property int leadIndex: first > 0 ? Math.max(0, Entries.indexAtSlot(layout, first - 1)) : 0
    readonly property bool isContentShown: isBodyShown
    readonly property bool hasLoose: entries.some(entry => !entry.isPinned)
    readonly property var hoveredEntry: hover.hovered && hover.point.position.y >= list.y
        ? entryAt(slotAt(hover.point.position.y - list.y))
        : null

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
        return ordered[Entries.indexAtSlot(layout, first + slot)] ?? null
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

    function scrollTo(target) {
        scroll(Math.max(0, Math.min(lastFirst, target)) - first)
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
            if (!hover.hovered)
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
                } else if (history.hasVisited) {
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
                leaveDuration: Motion.clipboard.faceLeave
                leaveDelay: Motion.clipboard.leaveStagger * history.look.rows
                leaveWindow: 0
                flipAngle: 0
                spinAngle: Motion.clipboard.iconSpin
                enterDuration: Motion.clipboard.iconEnter
                enterEasing: Easing.OutBack

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

            LabelReveal {
                anchors.verticalCenter: parent.verticalCenter
                width: title.implicitWidth
                height: title.implicitHeight
                label: "clipboard title"
                isShown: history.isContentShown
                leaveDuration: Motion.clipboard.faceLeave
                barColor: Appearance.color.accent

                Text {
                    id: title
                    text: "CLIPBOARD"
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.sans
                    font.pixelSize: history.look.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }
        }

        Turn {
            anchors.right: trash.left
            anchors.rightMargin: history.look.iconGap
            y: history.look.padding + (history.look.header - height) / 2
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
                font.family: Appearance.font.sans
                font.pixelSize: history.look.label
                font.bold: true
            }
        }

        Turn {
            id: trash
            anchors.right: parent.right
            anchors.rightMargin: history.look.trashInset
            y: history.look.padding + (history.look.header - height) / 2
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
                property real touchpadTravel: 0
                onWheel: wheel => {
                    if (wheel.pixelDelta.y !== 0) {
                        touchpadTravel += wheel.pixelDelta.y
                        const steps = Math.trunc(touchpadTravel / history.pitch)
                        if (steps === 0)
                            return
                        touchpadTravel -= steps * history.pitch
                        history.scroll(-steps)
                        return
                    }
                    touchpadTravel = 0
                    if (wheel.angleDelta.y !== 0)
                        history.scroll(wheel.angleDelta.y > 0 ? -1 : 1)
                }
            }

            Rectangle {
                readonly property int slot: history.layout.starts[history.boundary] ?? 0
                x: history.look.rowRadius
                width: parent.width - history.look.rowRadius * 2
                height: history.look.divider
                radius: height / 2
                y: (slot - history.first) * history.pitch + history.shift - (history.look.rowGap + height) / 2
                visible: history.boundary > 0 && history.isContentShown
                color: history.look.dividerColor
            }

            Repeater {
                model: history.poolSize

                ClipboardRow {
                    required property int index
                    readonly property int entryIndex: history.leadIndex + (index - history.leadIndex % history.poolSize + history.poolSize) % history.poolSize
                    readonly property int startSlot: history.layout.starts[entryIndex] ?? history.layout.total
                    readonly property int span: history.layout.spans[entryIndex] ?? 1
                    width: list.width
                    height: span * history.pitch - history.look.rowGap
                    y: (startSlot - history.first) * history.pitch + history.shift
                    order: entryIndex - history.leadIndex
                    entry: history.ordered[entryIndex] ?? null
                    isShown: history.isContentShown
                    isMirrored: history.isMirrored
                    isHovered: entry !== null && history.hoveredEntry !== null && history.hoveredEntry.key === entry.key && history.isContentShown
                    slide: entry && entry.key === history.swipedKey ? history.slide : 0
                    onPinRequested: history.pinRequested(entry)
                }
            }
        }

        Rectangle {
            id: scrollbar
            readonly property bool isScrollable: history.lastFirst > 0
            readonly property real thumbHeight: Math.max(history.look.scrollMinimum, height * history.look.rows / Math.max(1, history.layout.total))
            readonly property real position: history.lastFirst > 0
                ? Math.max(0, Math.min(1, (history.first - history.shift / history.pitch) / history.lastFirst))
                : 0
            x: parent.width - history.look.scrollInset - width
            y: list.y
            width: history.look.scrollWidth
            height: list.height
            radius: width / 2
            color: Appearance.color.wash
            opacity: history.isContentShown && isScrollable ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(Motion.clipboard.scrollbar)
                }
            }

            Rectangle {
                width: parent.width
                height: scrollbar.thumbHeight
                y: scrollbar.position * (scrollbar.height - height)
                radius: width / 2
                color: Appearance.color.accent
            }
        }

        Gesture {
            x: scrollbar.x - history.look.scrollGrip
            y: scrollbar.y
            width: scrollbar.width + history.look.scrollGrip * 2
            height: scrollbar.height
            enabled: history.isContentShown && scrollbar.isScrollable
            isHorizontal: false
            cursorShape: Qt.PointingHandCursor
            onCrossed: history.thumbBase = history.first
            onMoved: (travelX, travelY) => {
                const reach = scrollbar.height - scrollbar.thumbHeight
                history.scrollTo(history.thumbBase + Math.round(travelY / reach * history.lastFirst))
            }
        }
    }
}
