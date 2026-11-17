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
    readonly property bool isHeader: modelData.indexOf("header-") === 0
    readonly property bool isStream: entry?.kind === "stream"
    readonly property bool isArmed: isStream && armedKey === modelData
    readonly property bool isHighlighted: isArmed || entry?.isDefault === true

    signal chosen(var entry)
    signal volumeChanged(var entry, real value)

    width: ListView.view.width
    height: (isHeader ? Appearance.extension.header - 10 : Appearance.extension.row) + Appearance.extension.rowGap

    Component.onCompleted: {
        if (isSettled)
            turn.snap(1)
    }

    Turn {
        id: turn
        width: row.width
        height: row.height - Appearance.extension.rowGap
        isShown: row.isShown && row.entry !== null || row.isShown && row.isHeader
        enterDelay: Math.min(row.index, 8) * Motion.reveal.stagger

        Press {
            target: face
            isPressed: area.pressed
        }

        Item {
            id: face
            anchors.fill: parent

            Text {
                visible: row.isHeader
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.bottom: parent.bottom
                text: row.isHeader ? row.modelData.substring(7).toUpperCase() : ""
                color: Appearance.color.textMuted
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.chip
                font.letterSpacing: Appearance.font.labelSpacing
                font.bold: true
            }

            Item {
                anchors.fill: parent
                visible: !row.isHeader && row.entry !== null

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
                    width: parent.width - x - (row.isStream ? Appearance.extension.trackWidth + Appearance.extension.rowPadding * 2 : Appearance.extension.percentWidth + Appearance.extension.rowPadding)
                    elide: Text.ElideRight
                    text: (row.entry?.label ?? "").toUpperCase()
                    color: row.isHighlighted || rowHover.hovered ? Appearance.color.text : Appearance.color.textBody
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
                    anchors.right: parent.right
                    anchors.rightMargin: Appearance.extension.rowPadding
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.isStream
                    value: row.entry?.volume ?? 0
                    isMuted: row.entry?.isMuted ?? false
                    onMoved: value => row.volumeChanged(row.entry, value)
                }
            }
        }
    }
}
