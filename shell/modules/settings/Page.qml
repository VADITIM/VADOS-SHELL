import QtQuick
import qs.config

Item {
    id: page

    property string pageKey
    property string shownKey
    property bool isContentShown: false
    property bool isLingering: false
    property bool isMirrored: false
    property bool isSettled: false
    property int longest: 0
    readonly property bool isPage: true
    readonly property bool isShown: isContentShown && shownKey === pageKey
    default property alias body: holder.data

    visible: isShown || isLingering

    function gather(parentItem, found) {
        for (const child of parentItem.children) {
            if (child.isPiece === true)
                found.push(child)
            gather(child, found)
        }
    }

    function arrange() {
        const found = []
        gather(holder, found)
        let card = -1
        let stripe = -1
        let group = { lead: 0, pieces: [] }
        const groups = [group]
        for (const piece of found) {
            if (piece.role === "stripe") {
                stripe++
                piece.enterDelay = stripe * Motion.settings.stripeStagger
            } else if (piece.role === "card") {
                card++
                piece.enterDelay = card * Motion.settings.cardStagger
                group = { lead: card * Motion.settings.cardStagger + Motion.settings.cardLead, pieces: [] }
                groups.push(group)
            } else {
                group.pieces.push(piece)
            }
            piece.isMirrored = Qt.binding(() => page.isMirrored)
            piece.isShown = Qt.binding(() => page.isShown && piece.isWanted)
        }
        let last = 0
        for (const entry of groups) {
            const stride = Math.min(Motion.settings.stagger, Motion.settings.spread / Math.max(1, entry.pieces.length))
            entry.pieces.forEach((piece, step) => {
                const delay = Math.round(entry.lead + step * stride)
                last = Math.max(last, delay)
                piece.enterDelay = Qt.binding(() => page.isSettled ? 0 : delay)
            })
        }
        longest = last
    }

    function enlist() {
        Qt.callLater(arrange)
    }

    onIsShownChanged: {
        isSettled = false
        if (isShown) {
            settle.restart()
            return
        }
        settle.stop()
        isLingering = true
        linger.restart()
    }
    Component.onCompleted: arrange()

    Item {
        id: holder
        anchors.fill: parent
    }

    Timer {
        id: settle
        interval: page.longest + 1
        onTriggered: page.isSettled = true
    }

    Timer {
        id: linger
        interval: Motion.settings.pageSwap + Motion.settings.stagger
        onTriggered: page.isLingering = false
    }
}
