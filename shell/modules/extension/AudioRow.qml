import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: row

    required property string modelData
    required property int index
    property var rows: []
    property string armedKey: ""
    property bool isShown: false
    property bool isSettled: false
    readonly property var entry: rows.find(candidate => candidate.key === modelData) ?? null
    readonly property bool isStream: entry?.kind === "stream"
    readonly property bool isArmed: isStream && armedKey === modelData
    readonly property bool isHighlighted: isArmed || entry?.isDefault === true

    signal chosen(var entry)
    signal volumeChanged(var entry, real value)

    width: ListView.view.width
    height: Appearance.extension.row + Appearance.extension.rowGap

    Component.onCompleted: {
        if (isSettled)
            turn.snap(1)
    }

    Sprout {
        look: Appearance.extension.sprout
        pace: Motion.extension.sprout
        id: turn
        width: row.width
        height: row.height - Appearance.extension.rowGap
        isShown: row.isShown && row.entry !== null
        enterDelay: Math.min(row.index, 8) * Motion.extension.sprout.stagger

        Press {
            target: face
            isPressed: area.pressed
        }

        Item {
            id: face
            anchors.fill: parent

            Item {
                anchors.fill: parent
                visible: row.entry !== null

                Sweep {
                    anchors.fill: parent
                    isOn: rowHover.hovered
                    fill: Appearance.extension.hoverWash
                }

                Sweep {
                    anchors.fill: parent
                    isOn: row.isHighlighted
                }

                HoverHandler {
                    id: rowHover
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.chosen(row.entry)
                }

                Glyph {
                    x: Appearance.extension.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    width: Appearance.extension.glyph
                    height: Appearance.extension.glyph
                    visible: !row.isStream
                    name: row.entry?.kind === "input" ? "headset" : row.entry?.isMuted ? "muted" : "speaker"
                    level: row.entry?.volume ?? 0
                    color: row.isHighlighted ? Appearance.color.accent : rowHover.hovered ? Appearance.color.text : Appearance.color.textBody
                }

                Text {
                    x: row.isStream ? Appearance.extension.rowPadding : Appearance.extension.rowPadding * 2 + Appearance.extension.glyph
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.isStream ? Appearance.extension.streamName : parent.width - x - Appearance.extension.percentWidth - Appearance.extension.rowPadding
                    elide: Text.ElideRight
                    text: (row.entry?.label ?? "").toUpperCase()
                    color: row.isHighlighted || rowHover.hovered ? Appearance.color.text : Appearance.color.textBody

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.pace(Motion.stateDuration)
                            easing.type: Easing.OutQuad
                        }
                    }
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.extension.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !row.isStream
                    text: row.entry?.isMuted ? "MUTE" : Math.round((row.entry?.volume ?? 0) * 100) + "%"
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }

                Track {
                    width: parent.width - Appearance.extension.rowPadding * 3 - Appearance.extension.streamName
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.extension.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.isStream
                    isFilled: turn.presence > Appearance.extension.sprout.seed
                    value: row.entry?.volume ?? 0
                    isMuted: row.entry?.isMuted ?? false
                    onMoved: value => row.volumeChanged(row.entry, value)
                }
            }
        }
    }
}
