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
    readonly property var rows: Controls.sectionRows(Audio.outputs, Audio.inputs, Audio.streams)
    readonly property string layout: rows.map(entry => entry.key).join("|")
    readonly property var armed: rows.find(entry => entry.key === armedKey) ?? null

    onLayoutChanged: order = rows.map(entry => entry.key)
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
        width: parent.width
        height: Appearance.extension.header

        Turn {
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

        TypedText {
            anchors.verticalCenter: parent.verticalCenter
            x: Appearance.extension.glyph + 10
            width: Math.min(fullWidth, buttons.x - x - 8)
            clip: true
            isShown: page.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            target: page.armed !== null ? "ROUTE TO..." : "AUDIO"
            color: Appearance.color.text
            font.family: Appearance.font.sans
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
                    label: Audio.isMuted ? "UNMUTE" : "MUTE"
                    onClicked: Audio.toggleMute()
                }
            }
        }
    }

    Turn {
        id: volumeTurn
        y: header.height
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
            hasSteps: true
            onMoved: value => Audio.setVolume(value)
        }
    }

    ListView {
        id: list
        y: header.height + volumeTurn.height + Appearance.extension.headerGap
        width: parent.width
        height: parent.height - y
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
