import "../../utils/Geometry.js" as Geometry
import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: page

    property bool isShown: false
    property string current: ""
    property real screenAspect: 0.5625
    property real topEdge: 0
    property real bottomEdge: height
    property int target: 0
    property real position: 0
    property bool isSettled: true
    property real wheelTravel: 0
    property real roomWidth: width
    property real roomHeight: height
    property bool isEditing: false
    property bool isFramed: false
    property rect framedRect: Qt.rect(0, 0, 0, 0)
    property real framing: 0
    property string desktopPath: ""
    property string lockPath: ""
    property string sliceFrom: ""
    property real sliced: 1
    readonly property var look: Appearance.settings.wallpaper
    readonly property bool hasImages: Wallpapers.images.length > 0
    readonly property var entries: hasImages ? [""].concat(Wallpapers.images, [""]) : [""]
    readonly property int first: hasImages ? 1 : 0
    readonly property int last: entries.length - 1 - first
    readonly property int currentIndex: Math.max(first, Math.min(last, entries.indexOf(current)))
    readonly property real middle: (topEdge + bottomEdge) / 2
    readonly property real reachHeight: 2 * Math.min(middle, height - middle)
    readonly property real mainHeight: Math.max(0, Math.min(roomWidth * screenAspect, roomHeight - Appearance.settings.lock.footer, reachHeight))
    readonly property real mainWidth: mainHeight / screenAspect
    readonly property real mainLeft: (roomWidth - mainWidth) / 2
    readonly property real mainTop: middle - mainHeight / 2
    readonly property real nearHeight: mainHeight * look.near
    readonly property real spread: carousel.presence
    readonly property bool isOutside: current.length > 0 && entries.indexOf(current) < 0
    readonly property real shade: isEditing || isFramed ? 1 - Appearance.settings.widgets.wallpaperShade : 0
    readonly property rect mainRect: Qt.rect(Geometry.mix(mainLeft, framedRect.x, framing), Geometry.mix(mainTop, framedRect.y, framing), Geometry.mix(mainWidth, framedRect.width, framing), Geometry.mix(mainHeight, framedRect.height, framing))

    signal wallpaperRequested(string path)

    function offsetOf(index) {
        const gap = index - position;
        const distance = Math.min(Math.abs(gap), look.reach);
        if (distance === 0)
            return 0;
        return Math.sign(gap) * (look.reach - (look.reach - distance) * spread);
    }

    function frameAt(offset) {
        const distance = Math.min(Math.abs(offset), look.reach);
        const side = offset < 0 ? -1 : 1;
        const nearCenter = mainHeight / 2 - look.nearOverlap * nearHeight + nearHeight / 2;
        const outHeight = mainHeight * look.far;
        const outCenter = side < 0 ? middle - topEdge + outHeight / 2 : bottomEdge - middle + outHeight / 2;
        const heights = [mainHeight, nearHeight, outHeight];
        const centers = [0, nearCenter, outCenter];
        const lower = Math.min(Math.floor(distance), heights.length - 2);
        const share = distance - lower;
        const frameHeight = Geometry.mix(heights[lower], heights[lower + 1], share);
        const frameWidth = frameHeight / screenAspect;
        const centerY = middle + side * Geometry.mix(centers[lower], centers[lower + 1], share);
        return {
            "x": page.roomWidth / 2 - frameWidth / 2,
            "y": centerY - frameHeight / 2,
            "width": frameWidth,
            "height": frameHeight,
            "z": distance < 0.5 ? 0 : 10 - distance
        };
    }

    function go(index) {
        target = Math.max(first, Math.min(last, index));
        position = target;
        if (entries[target].length > 0 && entries[target] !== current)
            dwell.restart();
    }

    function step(direction) {
        go(target + direction);
    }

    function snap() {
        target = currentIndex;
        isSettled = false;
        position = target;
        isSettled = true;
    }

    function hitAt(pointX, pointY) {
        let best = -1;
        let bestZ = -1;
        for (let index = Math.max(0, Math.floor(position) - 2); index <= Math.min(entries.length - 1, Math.ceil(position) + 2); index++) {
            const frame = frameAt(offsetOf(index));
            if (pointX >= frame.x && pointX <= frame.x + frame.width && pointY >= frame.y && pointY <= frame.y + frame.height && frame.z > bestZ) {
                best = index;
                bestZ = frame.z;
            }
        }
        return best;
    }

    function sourceOf(path) {
        return path.length === 0 ? "" : path.startsWith("/") ? "file://" + path : path;
    }

    function pathOf(key) {
        return key === "lock" ? lockPath : desktopPath;
    }

    function switchTo(fromKey, toKey, isSliding) {
        sliceFrom = pathOf(fromKey);
        if (!isSliding || sliceFrom === pathOf(toKey)) {
            slice.stop();
            sliced = 1;
            return;
        }
        slice.restart();
    }

    function frame() {
        const goal = isFramed ? 1 : 0;
        if (!isShown || framing === goal)
            return;
        if (main.presence === 0) {
            morph.stop();
            framing = goal;
            return;
        }
        morph.to = goal;
        morph.restart();
    }

    function nameOf(path) {
        return path.slice(path.lastIndexOf("/") + 1);
    }

    onIsShownChanged: {
        Wallpapers.isWatching = isShown;
        if (isShown)
            snap();
        frame();
    }
    onIsFramedChanged: frame()
    onCurrentIndexChanged: {
        if (!dwell.running)
            snap();
    }

    Component.onDestruction: Wallpapers.isWatching = false

    Timer {
        id: dwell

        interval: Motion.settings.wallpaperDwell
        onTriggered: {
            if (page.entries[page.target].length > 0)
                page.wallpaperRequested(page.entries[page.target]);
        }
    }

    Turn {
        id: main

        isShown: page.isShown
        isFlipping: false
        isShaped: false
        enterDuration: Motion.settings.surfaceEnter
        enterEasing: Easing.OutCubic
        leaveWindow: 0
        leaveDuration: Motion.settings.innerLeave
        opacity: 1
        visible: false
    }

    Piece {
        id: carousel

        width: page.width
        height: page.height
        isFlipping: false
        isShown: page.isShown && !page.isFramed
        enterDuration: Motion.settings.carousel
        opacity: 1

        Item {
            anchors.fill: parent

            Repeater {
                model: page.entries.length

                Loader {
                    id: card

                    required property int index
                    readonly property real offset: page.offsetOf(index)
                    readonly property bool isMain: Math.abs(offset) < 0.5
                    readonly property var frame: page.frameAt(offset)
                    property real hidden: page.isEditing && !isMain ? 0 : 1

                    active: Math.abs(index - page.position) < page.look.reach
                    x: isMain ? page.mainRect.x : frame.x
                    y: isMain ? page.mainRect.y : frame.y
                    z: frame.z
                    width: isMain ? page.mainRect.width : frame.width
                    height: isMain ? page.mainRect.height : frame.height
                    opacity: hidden * Math.min(1, (isMain ? main.presence : carousel.presence) * carousel.look.fadeLead)
                    scale: isMain ? carousel.look.surface + (1 - carousel.look.surface) * main.presence : 1

                    Behavior on hidden {
                        NumberAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                        }
                    }

                    sourceComponent: Item {
                        id: face

                        readonly property string path: page.isOutside && card.index === page.currentIndex && page.target === page.currentIndex ? page.current : page.entries[card.index] ?? ""

                        Masked {
                            anchors.fill: parent

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.color.ground
                            }

                            Image {
                                anchors.fill: parent
                                visible: face.path.length > 0
                                source: visible ? page.sourceOf(face.path) : ""
                                sourceSize.width: page.look.previewWidth
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Glint {
                                anchors.fill: parent
                                label: "wallpaper glint"
                                look: page.look.glint
                                pace: Motion.settings.wallpaperGlint
                                isShown: main.presence > page.look.glintFrom && card.isMain && Math.abs(page.position - page.target) < 0.5
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.color.raised
                                opacity: card.isMain ? page.shade : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Motion.pace(Motion.stateDuration)
                                    }
                                }
                            }

                            mask: Rectangle {
                                anchors.fill: parent
                                radius: page.look.corner
                            }
                        }

                        Item {
                            anchors.centerIn: parent
                            visible: face.path.length === 0
                            width: page.look.plus
                            height: page.look.plus
                            scale: Math.sqrt(card.height / Math.max(1, page.mainHeight))

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: page.look.plusStroke
                                radius: height / 2
                                color: Appearance.color.textMuted
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: page.look.plusStroke
                                height: parent.height
                                radius: width / 2
                                color: Appearance.color.textMuted
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: page.look.corner
                            color: "transparent"
                            border.width: page.look.ring
                            visible: !page.isFramed
                            border.color: card.isMain ? Appearance.color.hairline : Qt.alpha(Appearance.color.text, page.look.ringShade)
                        }
                    }
                }
            }

            Masked {
                x: page.mainRect.x
                y: page.mainRect.y
                z: 20
                width: page.mainRect.width
                height: page.mainRect.height
                visible: page.sliced < 1 && page.sliceFrom.length > 0
                opacity: Math.min(1, main.presence * carousel.look.fadeLead)
                scale: carousel.look.surface + (1 - carousel.look.surface) * main.presence

                mask: Rectangle {
                    anchors.fill: parent
                    radius: page.look.corner
                }

                Item {
                    x: page.mainRect.width * page.sliced
                    width: page.mainRect.width - x
                    height: page.mainRect.height
                    clip: true

                    Image {
                        x: -parent.x
                        width: page.mainRect.width
                        height: page.mainRect.height
                        source: page.sourceOf(page.sliceFrom)
                        sourceSize.width: page.look.previewWidth
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Appearance.color.raised
                    opacity: page.shade
                }
            }
        }

        Gesture {
            id: gesture

            anchors.fill: parent
            enabled: !page.isFramed
            isHorizontal: false
            onTapped: mouse => {
                const index = page.hitAt(mouse.x, mouse.y);
                if (index < 0 || (page.isEditing && index !== page.target))
                    return;
                if (page.entries[index].length === 0)
                    Wallpapers.reveal();
                else
                    page.go(index);
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    page.wheelTravel += event.angleDelta.y;
                    if (Math.abs(page.wheelTravel) < Motion.settings.wheelNotch)
                        return;

                    page.step(page.wheelTravel < 0 ? 1 : -1);
                    page.wheelTravel = 0;
                }
            }
        }
    }

    NumberAnimation {
        id: morph

        target: page
        property: "framing"
        duration: Motion.pace(Motion.settings.surfaceEnter)
        easing.type: Easing.InOutCubic
        paused: Motion.isHeld && running
    }

    NumberAnimation {
        id: slice

        target: page
        property: "sliced"
        from: 0
        to: 1
        duration: Motion.pace(Motion.settings.wallpaperSlice)
        easing.type: Easing.InOutCubic
        paused: Motion.isHeld && running
    }

    Behavior on position {
        enabled: page.isSettled

        NumberAnimation {
            duration: Motion.pace(Motion.settings.carousel)
            easing.type: Easing.OutCubic
        }
    }
}
