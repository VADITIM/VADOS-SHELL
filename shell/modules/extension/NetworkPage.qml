import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: page

    property bool isOpen: false
    property bool isShown: false
    property bool isSettled: false

    signal closeRequested()

    onIsOpenChanged: Network.isWatching = isOpen
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
        width: parent.width
        height: Appearance.extension.header

        Turn {
            id: headerGlyph
            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.extension.glyph
            height: Appearance.extension.glyph
            isShown: page.isShown

            Glyph {
                anchors.fill: parent
                name: "wifi"
                level: Network.isEnabled && Network.isConnected ? Math.max(0.1, Network.strength) : 0
                color: Appearance.color.accent
            }
        }

        TypedText {
            anchors.verticalCenter: parent.verticalCenter
            x: Appearance.extension.glyph + 10
            width: Math.min(fullWidth, buttons.x - x - 8)
            clip: true
            isShown: page.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            target: !Network.isEnabled ? "WIFI OFF" : Network.isConnected ? Network.ssid.toUpperCase() : "NO NETWORK"
            color: Network.isConnected ? Appearance.color.text : Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing
            font.bold: true
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

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

            Turn {
                isShown: page.isShown
                enterDelay: Motion.pill.elementStagger * 2
                enterDuration: Motion.stateDuration
                enterEasing: Easing.OutBack
                leaveWindow: 0

                GlyphButton {
                    glyphName: "close"
                    onClicked: page.closeRequested()
                }
            }
        }
    }

    ListView {
        id: list
        y: header.height + Appearance.extension.headerGap
        width: parent.width
        height: parent.height - y
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Network.isEnabled ? Network.networks : []

        delegate: NetworkRow {
            isShown: page.isShown
            isSettled: page.isSettled
        }
    }

    TypedText {
        x: 4
        y: list.y + 12
        isShown: page.isShown && Network.isEnabled && Network.networks.length === 0
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        target: "SCANNING"
        color: Appearance.color.textMuted
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
        font.bold: true
    }
}
