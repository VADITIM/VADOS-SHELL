import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: page

    property bool isOpen: false
    property bool isShown: false
    property bool isSettled: false
    property bool isNamingHidden: false
    readonly property bool isPrompting: isOpen && (Network.prompt !== null || isNamingHidden || (Network.joinResult === "wrong" && Network.joining.length > 0))
    readonly property bool isTyping: isPrompting
    readonly property real footHeight: height - (isPrompting && joinLoader.item !== null ? joinLoader.y : header.y)
    readonly property real area: height - footHeight - Appearance.extension.splitRoom
    readonly property string status: Network.joining.length > 0 && Network.prompt === null ? "JOINING " + Network.joining.toUpperCase() : Network.joinMessage.length > 0 && !isPrompting ? Network.joinMessage : ""

    onIsOpenChanged: {
        Network.isWatching = isOpen
        if (!isOpen) {
            isNamingHidden = false
            Network.settleJoin()
        }
    }
    onIsShownChanged: {
        if (isShown)
            settle.restart()
        else
            isSettled = false
    }

    Timer {
        id: settle
        interval: Motion.pill.element + Motion.reveal.stagger * 10
        onTriggered: page.isSettled = true
    }

    Item {
        id: header
        y: parent.height - height
        width: parent.width
        height: Appearance.extension.header

        Turn {
            flipAngle: 0
            spinAngle: Motion.extension.glyphSpin
            enterDuration: Motion.extension.glyphPop
            enterEasing: Easing.OutBack
            id: headerGlyph
            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.extension.glyph
            height: Appearance.extension.glyph
            isShown: page.isShown

            Glyph {
                anchors.fill: parent
                name: Network.isConnected ? "wifi" : Network.isEnabled ? "wifi-error" : "wifi-off"
                level: Network.isConnected ? Math.max(0.1, Network.strength) : 0
                color: Appearance.color.accent
            }
        }

        ScrambleText {
            label: "extension header"
            anchors.verticalCenter: parent.verticalCenter
            x: Appearance.extension.glyph + 10
            width: Math.min(implicitWidth, buttons.x - x - 8)
            clip: true
            isShown: page.isShown
            target: page.status.length > 0 ? page.status : !Network.isEnabled ? "WIFI OFF" : Network.isConnected ? Network.ssid.toUpperCase() : "NO NETWORK"
            color: Network.joinResult.length > 0 && Network.joinResult !== "connected" && page.status.length > 0 ? Appearance.color.danger : Network.isConnected || page.status.length > 0 ? Appearance.color.text : Appearance.color.textMuted

            Behavior on color {
                ColorAnimation {
                    duration: Motion.pace(Motion.stateDuration)
                    easing.type: Easing.OutQuad
                }
            }
            family: Appearance.font.sans
            pixelSize: Appearance.font.label
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Turn {
                visible: Network.isEnabled
                isShown: page.isShown && Network.isEnabled && !page.isPrompting
                enterDelay: Motion.pill.elementStagger
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    label: "OTHER"
                    onClicked: page.isNamingHidden = true
                }
            }

            Turn {
                isShown: page.isShown
                enterDelay: Motion.pill.elementStagger
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    label: Network.isEnabled ? "OFF" : "ON"
                    onClicked: Network.toggle()
                }
            }
        }
    }

    ListView {
        id: list
        y: (page.area - height) / 2
        width: parent.width
        height: Math.min(page.area, contentHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Network.isEnabled ? Network.networks : []

        Drift {}

        delegate: NetworkRow {
            isShown: page.isShown
            isSettled: page.isSettled
        }
    }

    TypedText {
        x: 4
        y: (page.area - height) / 2
        isShown: page.isShown && Network.isEnabled && Network.networks.length === 0
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        target: "SCANNING"
        color: Appearance.color.textMuted
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
        font.bold: true
    }

    Loader {
        id: joinLoader
        y: header.y - Appearance.extension.promptGap - height
        width: parent.width
        height: item !== null ? item.implicitHeight : 0
        active: page.isPrompting

        sourceComponent: JoinPrompt {
            ask: Network.prompt !== null ? Network.prompt.ask : page.isNamingHidden ? "name" : Network.asked
            ssid: Network.prompt !== null ? Network.prompt.ssid : Network.joining
            error: Network.joinResult === "wrong" ? Network.joinMessage : ""
            isShown: page.isShown
            onSubmitted: values => {
                if (ask === "name") {
                    page.isNamingHidden = false
                    Network.connectTo(values[0], true)
                } else
                    Network.answer(values)
            }
            onCanceled: {
                page.isNamingHidden = false
                Network.cancelJoin()
            }
        }
    }
}
