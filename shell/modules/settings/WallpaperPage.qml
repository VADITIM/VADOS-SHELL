import "../../utils/Geometry.js" as Geometry
import QtQuick
import qs.components
import qs.config
import qs.services

Item {
    id: page

    property bool isShown: false
    property string current: ""
    property string folder: ""
    property real screenAspect: 0.5625
    property real topEdge: 0
    property real bottomEdge: height
    property int target: 0
    property real position: 0
    property real dragFrom: 0
    property bool isSettled: true
    property real wheelTravel: 0
    readonly property var look: Appearance.settings.wallpaper
    readonly property var entries: [""].concat(Wallpapers.images)
    readonly property int currentIndex: Math.max(0, entries.indexOf(current))
    readonly property real stackShare: (1 - look.nearOverlap) * look.near
    readonly property real middle: (topEdge + bottomEdge) / 2
    readonly property real reachHeight: 2 * Math.min(middle, height - middle)
    readonly property real mainHeight: Math.max(0, Math.min(width * screenAspect, reachHeight / (1 + 2 * stackShare)))
    readonly property real mainWidth: mainHeight / screenAspect
    readonly property real mainTop: middle - mainHeight / 2
    readonly property real nearHeight: mainHeight * look.near
    readonly property real spread: carousel.presence

    signal wallpaperRequested(string path)
    signal folderRequested(string folder)

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
            "x": (width - frameWidth) / 2,
            "y": centerY - frameHeight / 2,
            "width": frameWidth,
            "height": frameHeight,
            "z": distance < 0.5 ? 0 : 10 - distance
        };
    }

    function go(index) {
        target = Math.max(0, Math.min(entries.length - 1, index));
        position = target;
        if (entries[target] !== current)
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
            const frame = frameAt((index - position) * spread);
            if (pointX >= frame.x && pointX <= frame.x + frame.width && pointY >= frame.y && pointY <= frame.y + frame.height && frame.z > bestZ) {
                best = index;
                bestZ = frame.z;
            }
        }
        return best;
    }

    function nameOf(path) {
        return path.length === 0 ? "NONE" : path.slice(path.lastIndexOf("/") + 1);
    }

    onIsShownChanged: {
        Wallpapers.isWatching = isShown;
        if (isShown)
            snap();
    }
    onCurrentIndexChanged: {
        if (!dwell.running && !gesture.isDragging) {
            snap();
        }
    }
    Component.onDestruction: Wallpapers.isWatching = false

    Timer {
        id: dwell

        interval: Motion.settings.wallpaperDwell
        onTriggered: page.wallpaperRequested(page.entries[page.target])
    }

    Piece {
        id: carousel

        width: page.width
        height: page.height
        isFlipping: false
        enterDuration: Motion.settings.carousel

        Item {
            anchors.fill: parent
            opacity: Math.min(1, carousel.presence * carousel.look.fadeLead)

            Repeater {
                model: page.entries.length

                Loader {
                    id: card

                    required property int index
                    readonly property real offset: (index - page.position) * page.spread
                    readonly property var frame: page.frameAt(offset)

                    active: Math.abs(index - page.position) < page.look.reach
                    x: frame.x
                    y: frame.y
                    z: frame.z
                    width: frame.width
                    height: frame.height

                    sourceComponent: Item {
                        id: face

                        readonly property string path: page.entries[card.index] ?? ""

                        Masked {
                            anchors.fill: parent

                            Rectangle {
                                anchors.fill: parent
                                color: Appearance.color.ground
                            }

                            Image {
                                anchors.fill: parent
                                visible: face.path.length > 0
                                source: visible ? "file://" + face.path : ""
                                sourceSize.width: page.look.previewWidth
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            mask: Rectangle {
                                anchors.fill: parent
                                radius: page.look.corner
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: face.path.length === 0
                            scale: Math.sqrt(card.height / Math.max(1, page.mainHeight))
                            text: "NONE"
                            color: Appearance.color.text
                            font.family: Appearance.font.mono
                            font.pixelSize: Appearance.settings.section.title
                            font.letterSpacing: Appearance.settings.section.titleSpacing
                            font.bold: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: page.look.corner
                            color: "transparent"
                            border.width: page.look.ring
                            border.color: Math.abs(card.offset) < 0.5 ? Appearance.color.hairline : Qt.alpha(Appearance.color.text, page.look.ringShade)
                        }
                    }
                }
            }
        }

        Gesture {
            id: gesture

            anchors.fill: parent
            isHorizontal: false
            onPressed: page.dragFrom = page.position
            onMoved: (travelX, travelY) => {
                return page.position = Math.max(0, Math.min(page.entries.length - 1, page.dragFrom - travelY / Math.max(1, page.nearHeight)));
            }
            onThrown: (travelX, travelY, velocityX, velocityY) => {
                return page.go(Math.round(page.position - velocityY * Motion.settings.fling / Math.max(1, page.nearHeight)));
            }
            onTapped: mouse => {
                const index = page.hitAt(mouse.x, mouse.y);
                if (index >= 0)
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

    Piece {
        role: "label"
        x: (page.width - page.mainWidth) / 2
        y: page.mainTop + page.mainHeight + page.look.captionGap

        Column {
            spacing: Appearance.unit.small

            Text {
                text: page.nameOf(page.entries[page.target] ?? "")
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: page.look.captionName
                font.bold: true
            }

            Text {
                text: (page.target + 1) + " / " + page.entries.length
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: page.look.captionCount
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }

    TextField {
        x: (page.width - page.mainWidth) / 2
        y: page.mainTop - page.look.captionGap - height
        label: "FOLDER"
        placeholder: Wallpapers.folder
        value: page.folder
        fieldWidth: Math.min(page.look.fieldWidth, (page.mainWidth - page.mainWidth * page.look.near) / 2 - page.look.captionGap)
        onEdited: value => {
            return page.folderRequested(value);
        }
    }

    Behavior on position {
        enabled: page.isSettled && !gesture.isDragging

        NumberAnimation {
            duration: Motion.pace(Motion.settings.carousel)
            easing.type: Easing.OutCubic
        }
    }
}
