import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Geometry.js" as Geometry

Item {
    id: profile

    property bool isWanted: false
    property bool isMirrored: false
    property Item liquidParent: null
    property real centerX: 0
    property real centerY: 0
    property real buttonX: 0
    property real homeX: 0
    property real homeY: 0
    property real edgeY: 0
    property real apexY: 0
    property real riseX: 0
    property real riseY: 0
    property bool isComing: false
    property bool isOut: false
    property bool hasButtons: false
    property point heldPoint: Qt.point(0, 0)
    property real heldSize: 0
    property string name: ""
    property string picture: ""
    property int selected: -1
    property string armedAction: ""
    property bool isHurried: false

    readonly property var look: Appearance.search.profile
    readonly property var actions: [
        { key: "lock", glyph: "lock", isGuarded: false },
        { key: "suspend", glyph: "moon", isGuarded: false },
        { key: "restart", glyph: "restart", isGuarded: true },
        { key: "shutdown", glyph: "power", isGuarded: true }
    ]
    readonly property int count: actions.length + 1
    readonly property bool isLanded: isComing && arrival.isLanded
    readonly property real rate: isHurried ? Motion.search.profileHurry : 1
    readonly property real elapsed: isOut ? thrower.share * thrower.span * rate : arrival.share * arrival.span
    readonly property real blobFlight: isOut ? shareAt(elapsed) : 0
    readonly property real restSize: isOut ? heldSize * flightScale(blobFlight) : isComing ? Geometry.mix(look.enterFrom, look.blob, shareAt(elapsed)) : 0
    readonly property real blobSize: restSize * (1 + swell.swell)
    readonly property bool isActive: isComing || (isOut && !thrower.isLanded)
    readonly property bool isFlying: isOut ? !thrower.isLanded : isComing && arrival.share < 1
    readonly property point blobPoint: pointAt(elapsed)
    readonly property point trailPoint: pointAt(Math.max(0, elapsed - Motion.search.profileTrail))
    readonly property real speed: Math.hypot(blobPoint.x - trailPoint.x, blobPoint.y - trailPoint.y) / Motion.search.profileTrail
    readonly property real heading: Geometry.headingOf(trailPoint.x, trailPoint.y, blobPoint.x, blobPoint.y)
    readonly property real stretch: isFlying ? Geometry.stretchOf(speed, look.stretch, look.stretchLimit) : -look.squash * swell.swell
    readonly property int gatherSpan: Motion.search.profileGather + Motion.search.profileThrowStagger * (actions.length - 1)
    readonly property real splash: isLanded ? Geometry.clampUnit(swell.time / Motion.search.profileSplash) : 1
    readonly property real columnHeight: actions.length * look.button + (actions.length - 1) * look.buttonGap

    signal profileRequested()
    signal pointed(int index)
    signal released(int index)

    function edgeX(localX, itemWidth) {
        return isMirrored ? width - localX - itemWidth : localX
    }

    function pieceShare(order) {
        if (!isOut)
            return 0
        return Geometry.smooth(Geometry.clampUnit((elapsed - order * Motion.search.profileThrowStagger) / Motion.search.profileGather))
    }

    function shareAt(time) {
        if (isOut) {
            const local = Geometry.clampUnit(time / Motion.search.profileThrow)
            return local * local
        }
        return Geometry.surge(Geometry.clampUnit(time / Motion.search.profileEnter), Motion.search.profileSurge, Motion.search.profileTurn)
    }

    function pointAt(time) {
        if (isOut)
            return flightPoint(heldPoint.x, heldPoint.y, shareAt(time))
        return Geometry.arcAt(Qt.point(homeX, homeY), Qt.point(riseX, riseY), Qt.point(centerX, centerY), shareAt(time))
    }

    function flightScale(share) {
        return Geometry.mix(1, look.throwEnd, share)
    }

    function flightPoint(fromX, fromY, share) {
        const arc = 1 - look.throwSlide - look.throwExit
        const turnY = homeY - look.throwTurn
        if (share < arc)
            return Geometry.arcAt(Qt.point(fromX, fromY), Qt.point(homeX, apexY), Qt.point(homeX, edgeY), share / arc)
        if (share < 1 - look.throwExit)
            return Qt.point(homeX, Geometry.mix(edgeY, turnY, (share - arc) / look.throwSlide))
        return Geometry.arcAt(Qt.point(homeX, turnY), Qt.point(homeX, homeY), Qt.point(-look.throwPast, homeY), (share - 1 + look.throwExit) / look.throwExit)
    }

    function activate(index) {
        if (index === 0) {
            isHurried = true
            profileRequested()
            return
        }
        const action = actions[index - 1]
        if (!action)
            return
        if (action.isGuarded && armedAction !== action.key) {
            armedAction = action.key
            disarm.restart()
            return
        }
        armedAction = ""
        switch (action.key) {
        case "lock":
            Power.lock()
            break
        case "suspend":
            Power.suspend()
            break
        case "restart":
            Power.restart()
            break
        case "shutdown":
            Power.shutdown()
            break
        }
    }

    onIsWantedChanged: {
        armedAction = ""
        if (isWanted) {
            isHurried = false
            isOut = false
            isComing = true
            return
        }
        heldPoint = blobPoint
        heldSize = restSize
        hasButtons = arrival.share >= 1
        isOut = isComing
        isComing = false
    }

    Timer {
        id: disarm
        interval: Motion.search.profileDisarm
        onTriggered: profile.armedAction = ""
    }

    LiquidShape {
        parent: profile.liquidParent
        visible: profile.isActive
        width: profile.blobSize * (1 + profile.stretch)
        height: profile.blobSize / (1 + profile.stretch)
        x: profile.blobPoint.x - width / 2
        y: profile.blobPoint.y - height / 2
        rotation: profile.heading * 180 / Math.PI
    }

    Throw {
        id: thrower
        label: "profile throw"
        isThrown: profile.isOut
        span: Math.round(Math.max(profile.gatherSpan, Motion.search.profileThrow) / profile.rate)
        easing: Easing.Linear
    }

    Throw {
        id: arrival
        label: "profile arrival"
        isThrown: profile.isComing
        span: Motion.search.profileEnter
        easing: Easing.Linear
    }

    Gulp {
        id: swell
        label: "profile swell"
        isLanded: profile.isLanded
        amplitude: profile.look.swell
        span: Motion.search.profileSwell
    }

    Repeater {
        model: profile.look.splashCount

        Item {
            id: drop

            required property int index
            readonly property real angle: 2 * Math.PI * (index + 0.5) / profile.look.splashCount
            readonly property real reach: profile.blobSize / 2 + profile.look.splashReach * Math.sin(Math.PI * profile.splash)
            readonly property real size: profile.look.splashDrop * (1 - profile.splash)

            LiquidShape {
                parent: profile.liquidParent
                visible: drop.size > 0.5
                x: profile.centerX + Math.cos(drop.angle) * drop.reach - drop.size / 2
                y: profile.centerY + Math.sin(drop.angle) * drop.reach - drop.size / 2
                width: drop.size
                height: drop.size
            }
        }
    }

    Item {
        id: avatarSpot
        x: profile.edgeX(profile.centerX - width / 2, width)
        y: profile.centerY - height / 2
        width: profile.look.avatar
        height: width

        Turn {
            id: avatar
            anchors.fill: parent
            isShown: profile.isLanded
            enterDuration: Motion.search.profileContent
            enterEasing: Easing.OutBack
            leaveWindow: 0
            leaveDuration: Motion.search.profileShrink

            Press {
                target: avatar
                isPressed: avatarArea.pressed
                isRaised: avatarArea.containsMouse || profile.selected === 0
                depth: Motion.press.card
            }

            Masked {
                anchors.fill: parent
                visible: portrait.status === Image.Ready
                mask: Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "black"
                }

                Image {
                    id: portrait
                    anchors.fill: parent
                    source: profile.picture
                    sourceSize.width: avatarSpot.width * 2
                    sourceSize.height: avatarSpot.height * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Appearance.color.wash
                visible: portrait.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: (profile.name || "?").charAt(0).toUpperCase()
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Math.round(avatarSpot.width * profile.look.initialShare)
                    font.bold: true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: profile.look.ring
                border.color: profile.selected === 0 ? Appearance.color.accent : "transparent"

                Behavior on border.color {
                    ColorAnimation {
                        duration: Motion.pace(Motion.hoverIn)
                    }
                }
            }
        }

        MouseArea {
            id: avatarArea
            anchors.fill: parent
            enabled: profile.isLanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: profile.pointed(0)
            onContainsMouseChanged: if (!containsMouse) profile.released(0)
            onClicked: profile.activate(0)
        }
    }

    TypedText {
        id: nameText
        x: profile.edgeX(profile.centerX - width / 2, width)
        y: profile.centerY + profile.look.blob / 2 + profile.look.nameGap
        target: (profile.name || "PROFILE").toUpperCase()
        isShown: profile.isLanded
        holdsWidth: true
        horizontalAlignment: Text.AlignHCenter
        color: profile.selected === 0 || nameArea.containsMouse ? Appearance.color.accent : Appearance.color.text
        font.family: Appearance.font.mono
        font.pixelSize: profile.look.name
        font.bold: true
        font.letterSpacing: Appearance.font.labelSpacing

        Behavior on color {
            ColorAnimation {
                duration: Motion.pace(Motion.hoverIn)
            }
        }

        MouseArea {
            id: nameArea
            anchors.fill: parent
            anchors.margins: -profile.look.nameGap / 2
            enabled: profile.isLanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: profile.pointed(0)
            onContainsMouseChanged: if (!containsMouse) profile.released(0)
            onClicked: profile.activate(0)
        }
    }

    Repeater {
        model: profile.actions

        Item {
            id: button

            required property var modelData
            required property int index
            readonly property bool isArmed: profile.armedAction === modelData.key
            readonly property bool isSelected: profile.selected === index + 1
            readonly property real topY: profile.centerY - profile.columnHeight / 2 + index * (profile.look.button + profile.look.buttonGap)

            x: profile.edgeX(profile.buttonX - width / 2, width)
            y: topY
            width: profile.look.button
            height: width

            LiquidShape {
                readonly property real flight: profile.pieceShare(button.index)
                readonly property point center: profile.isOut ? Qt.point(Geometry.mix(profile.buttonX, profile.blobPoint.x, flight), Geometry.mix(button.topY + profile.look.button / 2, profile.blobPoint.y, flight)) : Qt.point(profile.buttonX, button.topY + profile.look.button / 2)
                readonly property real size: profile.look.button * (profile.isOut ? (profile.hasButtons && flight < 1 ? 1 : 0) : Math.max(0, face.presence))
                parent: profile.liquidParent
                visible: size > 0.5
                x: center.x - size / 2
                y: center.y - size / 2
                width: size
                height: size
            }

            Turn {
                id: face
                anchors.fill: parent
                isShown: profile.isLanded
                enterDelay: Motion.search.profileContent / 2 + button.index * Motion.search.profileStagger
                enterDuration: Motion.search.profileContent
                enterEasing: Easing.OutBack
                leaveWindow: 0
                leaveDuration: Motion.search.profileShrink

                Press {
                    target: face
                    isPressed: buttonArea.pressed
                    isRaised: buttonArea.containsMouse || button.isSelected
                    depth: Motion.press.button
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: button.isArmed ? Appearance.color.danger : Appearance.color.wash
                    opacity: button.isArmed ? profile.look.armedWash : buttonArea.containsMouse || button.isSelected ? 1 : 0
                    border.width: button.isSelected ? profile.look.ring : 0
                    border.color: Appearance.color.accent

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.pace(buttonArea.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Glyph {
                    anchors.centerIn: parent
                    width: profile.look.buttonGlyph
                    height: profile.look.buttonGlyph
                    name: button.modelData.glyph
                    color: button.isArmed ? Appearance.color.danger : button.isSelected ? Appearance.color.accent : Appearance.color.textBody
                }
            }

            MouseArea {
                id: buttonArea
                anchors.fill: parent
                enabled: profile.isLanded
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPositionChanged: profile.pointed(button.index + 1)
                onContainsMouseChanged: if (!containsMouse) profile.released(button.index + 1)
                onClicked: profile.activate(button.index + 1)
            }
        }
    }
}
