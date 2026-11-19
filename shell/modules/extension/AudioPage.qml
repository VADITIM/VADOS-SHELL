import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Controls.js" as Controls

Item {
    id: page

    property bool isOpen: false
    property bool isShown: false
    property bool isSettled: false
    property string armedKey: ""
    property var order: []
    readonly property var armed: Controls.tabRows(Audio.outputs, Audio.inputs, Audio.streams, "stream").find(entry => entry.key === armedKey) ?? null
    readonly property string shownTab: armed !== null ? "output" : Audio.tab
    readonly property var rows: Controls.tabRows(Audio.outputs, Audio.inputs, Audio.streams, shownTab)
    readonly property string layout: rows.map(entry => entry.key).join("|")
    readonly property real footHeight: height - volumeTurn.y
    readonly property real listTop: Appearance.extension.tab + Appearance.extension.tabGap
    readonly property real area: height - footHeight - Appearance.extension.splitRoom - listTop

    onLayoutChanged: order = rows.map(entry => entry.key)
    onShownTabChanged: {
        if (!isShown)
            return
        isSettled = false
        settle.restart()
    }
    onArmedChanged: {
        if (armed === null)
            armedKey = ""
    }
    onIsShownChanged: {
        if (isShown)
            settle.restart()
        else
            isSettled = false
    }

    function choose(entry) {
        if (entry.kind === "stream")
            armedKey = armedKey === entry.key ? "" : entry.key
        else if (entry.kind === "output" && armed !== null) {
            Audio.route(armed, entry)
            armedKey = ""
        } else
            Audio.makeDefault(entry)
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
            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.extension.glyph
            height: Appearance.extension.glyph
            isShown: page.isShown

            Glyph {
                anchors.fill: parent
                name: Audio.isMuted ? "muted" : "speaker"
                level: Audio.volume
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
            target: page.armed !== null ? "ROUTE TO..." : "AUDIO"
            color: Appearance.color.text
            family: Appearance.font.sans
            pixelSize: Appearance.font.label
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
                    label: Audio.isMuted ? "UNMUTE" : "MUTE"
                    onClicked: Audio.toggleMute()
                }
            }
        }
    }

    Sprout {
        look: Appearance.extension.sprout
        pace: Motion.extension.sprout
        id: volumeTurn
        y: header.y - height
        width: parent.width
        height: volumeTrack.height
        isShown: page.isShown
        enterDelay: Motion.pill.elementStagger
        leaveWindow: 0

        Track {
            id: volumeTrack
            width: parent.width
            value: Audio.volume
            isMuted: Audio.isMuted
            isFilled: volumeTurn.presence > Appearance.extension.sprout.seed
            hasSteps: true
            onMoved: value => Audio.setVolume(value)
        }
    }

    Row {
        id: tabs
        width: parent.width
        height: Appearance.extension.tab

        Repeater {
            model: Controls.audioTabs

            Sprout {
                id: tabTurn
                required property var modelData
                required property int index
                readonly property bool isPicked: page.shownTab === modelData.key
                look: Appearance.extension.sprout
                pace: Motion.extension.sprout
                width: tabs.width / Controls.audioTabs.length
                height: tabs.height
                isShown: page.isShown
                enterDelay: index * Motion.extension.sprout.stagger

                Sweep {
                    anchors.fill: parent
                    isOn: tabHover.hovered && !tabTurn.isPicked
                    fill: Appearance.extension.hoverWash
                }

                Sweep {
                    anchors.fill: parent
                    isOn: tabTurn.isPicked
                }

                Text {
                    anchors.centerIn: parent
                    text: tabTurn.modelData.label
                    color: tabTurn.isPicked ? Appearance.color.accent : tabHover.hovered ? Appearance.color.text : Appearance.color.textMuted
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.chip
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                HoverHandler {
                    id: tabHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        page.armedKey = ""
                        Audio.pickTab(tabTurn.modelData.key)
                    }
                }
            }
        }
    }

    ListView {
        id: list
        y: page.listTop + (page.area - height) / 2
        width: parent.width
        height: Math.min(page.area, contentHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: page.order

        Drift {}

        delegate: AudioRow {
            rows: page.rows
            armedKey: page.armedKey
            isShown: page.isShown
            isSettled: page.isSettled
            onChosen: entry => page.choose(entry)
            onVolumeChanged: (entry, value) => Audio.setRowVolume(entry, value)
        }
    }
}
