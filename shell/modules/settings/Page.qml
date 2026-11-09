import QtQuick
import qs.config

Item {
    id: page

    property string pageKey
    property string shownKey
    property bool isContentShown: false
    property bool isLingering: false
    readonly property bool isShown: isContentShown && shownKey === pageKey
    default property alias body: holder.data

    visible: isShown || isLingering

    function gather(parentItem, found) {
        for (const child of parentItem.children) {
            if (child.isPiece === true)
                found.push(child)
            else
                gather(child, found)
        }
    }

    function arrange() {
        const found = []
        gather(holder, found)
        found.forEach((piece, index) => {
            piece.enterDelay = index * Motion.settings.stagger
            piece.isShown = Qt.binding(() => page.isShown)
        })
    }

    onIsShownChanged: {
        if (isShown)
            return
        isLingering = true
        linger.restart()
    }
    Component.onCompleted: arrange()

    Item {
        id: holder
        anchors.fill: parent
    }

    Timer {
        id: linger
        interval: Motion.settings.pageSwap + Motion.settings.stagger
        onTriggered: page.isLingering = false
    }
}
