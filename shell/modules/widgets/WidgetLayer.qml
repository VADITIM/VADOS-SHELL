import QtQuick
import qs.config
import qs.components
import "../../utils/Widgets.js" as Widgets
import "../../utils/Placement.js" as Placement
import "../../utils/Geometry.js" as Geometry

Item {
    id: widgetLayer

    property var layout: []
    property bool isCovered: false
    property bool isReady: false
    property string carried: ""
    property real carryX: 0
    property real carryY: 0
    property real carryFromX: 0
    property real carryFromY: 0
    readonly property var look: Appearance.widgets
    readonly property var grid: Widgets.gridOn(width, height, look)
    readonly property var origin: Widgets.originOn(width, height, grid, look)
    readonly property var placements: Placement.settle(layout, Widgets.widgets, grid)
    readonly property bool isLive: visible && !isCovered
    readonly property var zones: placements.map(placement => Widgets.rectOf(placement, origin, look))
    readonly property string pressedKey: gesture.pressed ? keyAt(gesture.pressPoint.x, gesture.pressPoint.y) : ""
    readonly property var landing: carried.length > 0 ? Widgets.landing(placements, grid, carried, Math.round((carryX - origin.x) / look.cell), Math.round((carryY - origin.y) / look.cell)) : null
    property real landingX: 0
    property real landingY: 0
    property real landingWidth: 0
    property real landingHeight: 0
    property int askers: 0
    readonly property bool wantsKeyboard: askers > 0

    signal layoutRequested(var entries)

    function placementOf(key) {
        return placements.find(placement => placement.key === key) ?? null
    }

    function keyAt(x, y) {
        const hit = placements.find(placement => {
            const rect = Widgets.rectOf(placement, origin, look)
            return x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height
        })
        return hit ? hit.key : ""
    }

    function holderOf(key) {
        for (let index = 0; index < holders.count; index++) {
            const holder = holders.itemAt(index)
            if (holder && holder.modelData.key === key)
                return holder
        }
        return null
    }

    function stopTyping() {
        for (let index = 0; index < holders.count; index++) {
            const holder = holders.itemAt(index)
            if (holder && holder.isTyping)
                holder.finish()
        }
    }

    function tap(x, y) {
        const holder = holderOf(keyAt(x, y))
        if (holder && holder.takesText)
            holder.edit(x, y)
        else
            stopTyping()
    }

    function pickUp(key, travelX, travelY) {
        stopTyping()
        const placement = placementOf(key)
        if (!placement)
            return
        const rect = Widgets.rectOf(placement, origin, look)
        carryFromX = rect.x
        carryFromY = rect.y
        carry(rect, travelX, travelY)
        carried = key
    }

    function carry(rect, travelX, travelY) {
        carryX = Math.max(0, Math.min(width - rect.width, carryFromX + travelX))
        carryY = Math.max(0, Math.min(height - rect.height, carryFromY + travelY))
    }

    function follow(travelX, travelY) {
        const placement = placementOf(carried)
        if (placement)
            carry(Widgets.rectOf(placement, origin, look), travelX, travelY)
    }

    function drop(velocityX, velocityY) {
        const key = carried
        if (!key)
            return
        const column = Math.round((carryX + velocityX * Motion.widgets.fling - origin.x) / look.cell)
        const row = Math.round((carryY + velocityY * Motion.widgets.fling - origin.y) / look.cell)
        carried = ""
        layoutRequested(Widgets.moved(placements, grid, key, column, row))
    }

    onLandingChanged: {
        if (!landing)
            return
        const rect = Widgets.rectOf(landing, origin, look)
        landingX = rect.x
        landingY = rect.y
        landingWidth = rect.width
        landingHeight = rect.height
    }

    Component.onCompleted: isReady = true

    Behavior on landingX {
        enabled: mark.presence > 0
        NumberAnimation {
            duration: Motion.pace(Motion.widgets.follow)
            easing.type: Easing.OutCubic
        }
    }

    Behavior on landingY {
        enabled: mark.presence > 0
        NumberAnimation {
            duration: Motion.pace(Motion.widgets.follow)
            easing.type: Easing.OutCubic
        }
    }

    Turn {
        id: mark
        x: widgetLayer.landingX
        y: widgetLayer.landingY
        width: widgetLayer.landingWidth
        height: widgetLayer.landingHeight
        isShown: widgetLayer.landing !== null
        isFlipping: false
        enterDuration: Motion.widgets.follow
        leaveWindow: 0
        leaveDuration: Motion.widgets.follow

        Squircle {
            width: mark.width
            height: mark.height
            opacity: mark.presence
            scale: Geometry.mix(widgetLayer.look.markScale, 1, mark.presence)
            color: Qt.alpha(Appearance.color.accent, widgetLayer.look.markFill)
            strokeColor: Qt.alpha(Appearance.color.accent, widgetLayer.look.markAlpha)
            strokeWidth: widgetLayer.look.markStroke
            corner: widgetLayer.look.corner
        }
    }

    Repeater {
        id: holders
        model: Widgets.widgets

        Item {
            id: holder

            required property var modelData
            readonly property var placement: widgetLayer.placementOf(modelData.key)
            readonly property bool isPlaced: placement !== null
            readonly property var rect: isPlaced ? Widgets.rectOf(placement, widgetLayer.origin, widgetLayer.look) : null
            readonly property bool isCarried: widgetLayer.carried === modelData.key
            readonly property bool isRevealed: turn.isShown && turn.presence >= Motion.widgets.revealAt
            readonly property bool takesText: modelData.takesText === true
            readonly property bool isTyping: takesText && face.item !== null && face.item.isTyping === true
            readonly property bool asksKeyboard: takesText && isPlaced && (hover.hovered || isTyping)
            property real restX: 0
            property real restY: 0
            property bool isSettled: false

            function rest() {
                if (!rect)
                    return
                restX = rect.x
                restY = rect.y
                isSettled = true
            }

            function edit(x, y) {
                if (!takesText || !face.item || !isRevealed)
                    return
                const point = face.item.mapFromItem(widgetLayer, x, y)
                face.item.edit(point.x, point.y)
            }

            function finish() {
                if (face.item && face.item.finish)
                    face.item.finish()
            }

            function land() {
                isSettled = false
                restX = widgetLayer.carryX
                restY = widgetLayer.carryY
                isSettled = true
                Qt.callLater(rest)
            }

            x: isCarried ? widgetLayer.carryX : restX
            y: isCarried ? widgetLayer.carryY : restY
            z: isCarried ? 1 : isTyping ? 2 : 0
            width: modelData.columns * widgetLayer.look.cell - widgetLayer.look.gap
            height: modelData.rows * widgetLayer.look.cell - widgetLayer.look.gap

            onRectChanged: rest()
            onIsCarriedChanged: if (!isCarried) land()
            onAsksKeyboardChanged: widgetLayer.askers += asksKeyboard ? 1 : -1
            Component.onCompleted: rest()
            Component.onDestruction: if (asksKeyboard) widgetLayer.askers -= 1

            HoverHandler {
                id: hover
                enabled: holder.takesText
            }

            Behavior on restX {
                enabled: holder.isSettled
                NumberAnimation {
                    duration: Motion.pace(Motion.widgets.glide)
                    easing.type: Easing.OutBack
                }
            }

            Behavior on restY {
                enabled: holder.isSettled
                NumberAnimation {
                    duration: Motion.pace(Motion.widgets.glide)
                    easing.type: Easing.OutBack
                }
            }

            Turn {
                id: turn
                width: holder.width
                height: holder.height
                isShown: holder.isPlaced && widgetLayer.isReady
                enterDuration: Motion.widgets.pop
                enterWindow: Motion.widgets.popWindow
                enterEasing: Easing.OutBack
                leaveWindow: 0
                leaveDuration: Motion.widgets.leave
                onDeparted: holder.isSettled = false

                Item {
                    id: body
                    width: holder.width
                    height: holder.height

                    Press {
                        target: body
                        isPressed: widgetLayer.pressedKey === holder.modelData.key && !holder.isCarried
                        isRaised: holder.isCarried
                    }

                    Squircle {
                        anchors.fill: parent
                        color: Qt.alpha(Appearance.color.panel, Appearance.color.panelAlpha)
                        strokeColor: holder.isTyping ? Appearance.color.accent : Appearance.color.hairline
                        strokeWidth: holder.isTyping ? widgetLayer.look.noteFocusRing : widgetLayer.look.stroke
                        corner: widgetLayer.look.corner
                    }

                    Loader {
                        id: face
                        anchors.fill: parent
                        anchors.margins: widgetLayer.look.padding
                        active: holder.isPlaced || turn.presence > 0
                        source: Qt.resolvedUrl(holder.modelData.root + ".qml")
                        onLoaded: {
                            item.isShown = Qt.binding(() => holder.isRevealed)
                            item.isLive = Qt.binding(() => widgetLayer.isLive)
                        }
                    }
                }
            }
        }
    }

    Gesture {
        id: gesture
        anchors.fill: parent
        cursorShape: widgetLayer.carried.length > 0 ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onCrossed: (travelX, travelY) => {
            const key = widgetLayer.keyAt(pressPoint.x, pressPoint.y)
            if (key.length > 0)
                widgetLayer.pickUp(key, travelX, travelY)
        }
        onMoved: (travelX, travelY) => {
            if (widgetLayer.carried.length > 0)
                widgetLayer.follow(travelX, travelY)
        }
        onThrown: (travelX, travelY, velocityX, velocityY) => widgetLayer.drop(velocityX, velocityY)
        onTapped: widgetLayer.tap(pressPoint.x, pressPoint.y)
    }
}
