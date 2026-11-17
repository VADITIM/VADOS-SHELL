import QtQuick
import qs.config
import qs.components

Item {
    id: wallpaper

    property string source: ""
    property int front: 0

    component Slot: Turn {
        id: slot

        property string path: ""
        required property int slotIndex
        readonly property bool isFront: wallpaper.front === slotIndex
        readonly property bool isReady: path.length > 0 && picture.status === Image.Ready

        anchors.fill: parent
        z: isFront ? 1 : 0
        isShown: isFront && isReady
        isFlipping: false
        enterDuration: Motion.wallpaper.fade
        enterEasing: Easing.InOutQuad
        leaveWindow: 0
        leaveDelay: Motion.wallpaper.fade
        leaveDuration: 0
        opacity: presence

        onIsReadyChanged: if (isReady && path === wallpaper.source) wallpaper.front = slotIndex

        Image {
            id: picture
            anchors.fill: parent
            source: slot.path.length === 0 ? "" : slot.path.startsWith("/") ? "file://" + slot.path : slot.path
            sourceSize: Qt.size(wallpaper.width, wallpaper.height)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
        }
    }

    function place(path) {
        const shown = front === 0 ? first : second
        const back = front === 0 ? second : first
        if (shown.path === path)
            return
        if (path.length === 0) {
            shown.path = ""
            back.path = ""
            return
        }
        back.path = path
        if (back.isReady)
            front = back.slotIndex
    }

    onSourceChanged: place(source)
    Component.onCompleted: place(source)

    Slot {
        id: first
        slotIndex: 0
    }

    Slot {
        id: second
        slotIndex: 1
    }
}
