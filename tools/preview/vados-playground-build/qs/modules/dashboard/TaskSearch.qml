import QtQuick
import qs.config
import qs.components
import "../../utils/Geometry.js" as Geometry

Item {
    id: search

    property bool isShown: false
    property bool isMirrored: false
    property string query: ""
    property Item shapes: null
    property Item target: null
    property real fromX: 0
    property real toX: 0
    property real floorY: 0
    readonly property var look: Appearance.dashboard.task
    readonly property bool isTyping: input.activeFocus
    readonly property real presence: turn.presence
    readonly property real flight: Geometry.clampUnit(presence / Motion.dashboard.taskSearchShot)
    readonly property real spread: Math.max(0, (presence - Motion.dashboard.taskSearchShot) / (1 - Motion.dashboard.taskSearchShot))
    readonly property real stretch: Math.sin(Math.PI * flight)
    readonly property real fullWidth: Math.max(look.search, (toX - fromX) * look.searchShare)
    readonly property real pillWidth: Geometry.mix(look.search, fullWidth, spread) * (1 - look.searchSquash * stretch)
    readonly property real pillHeight: look.search * (1 + look.searchStretch * stretch)
    readonly property real baseLeft: (fromX + toX) / 2 - pillWidth / 2
    readonly property real baseTop: Geometry.mix(floorY + look.searchGap, floorY - look.search, flight) - (pillHeight - look.search) / 2

    signal edited(string text)

    function begin(text) {
        edited(query + text)
        input.cursorPosition = input.length
        input.forceActiveFocus()
    }

    Turn {
        id: turn
        isShown: search.isShown
        isFlipping: false
        enterDelay: Motion.dashboard.taskSearchDelay
        enterDuration: Motion.dashboard.taskSearch
        enterEasing: Easing.OutBack
        leaveDuration: Motion.dashboard.taskTabLeave
        leaveWindow: 0
    }

    LiquidShape {
        parent: search.shapes
        visible: pill.visible
        x: search.baseLeft
        y: search.baseTop
        width: search.pillWidth
        height: search.pillHeight
    }

    Item {
        id: pill

        visible: search.presence > 0.01
        x: search.isMirrored ? search.width - search.baseLeft - width : search.baseLeft
        y: search.baseTop
        width: search.pillWidth
        height: search.pillHeight
        clip: true

        Accessible.role: Accessible.EditableText
        Accessible.name: "SEARCH PROCESSES"

        MouseArea {
            anchors.fill: parent
            enabled: search.isShown
            cursorShape: Qt.IBeamCursor
            onClicked: input.forceActiveFocus()
        }

        Item {
            id: face
            x: search.look.searchPadding
            width: search.fullWidth - search.look.searchPadding * 2
            anchors.verticalCenter: parent.verticalCenter
            height: search.look.search
            opacity: search.isShown ? Geometry.clampUnit(search.spread) : 0

            Glyph {
                id: lens
                anchors.verticalCenter: parent.verticalCenter
                width: search.look.searchGlyph
                height: search.look.searchGlyph
                name: "search"
                stroke: Appearance.dashboard.iconStroke * 24 / width
                color: search.isTyping || search.query.length > 0 ? Appearance.color.accent : Appearance.color.textMuted
                rotation: (1 - Geometry.clampUnit(search.spread)) * Motion.dashboard.taskTabSpin
            }

            Text {
                anchors.left: input.left
                anchors.verticalCenter: parent.verticalCenter
                visible: search.query.length === 0 && !search.isTyping
                text: "SEARCH"
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: search.look.font.label
                font.letterSpacing: Appearance.font.labelSpacing / 2
            }

            TextInput {
                id: input
                anchors.left: lens.right
                anchors.leftMargin: search.look.iconGap
                anchors.right: clear.visible ? clear.left : parent.right
                anchors.rightMargin: search.look.iconGap
                anchors.verticalCenter: parent.verticalCenter
                text: search.query
                clip: true
                enabled: search.isShown
                color: Appearance.color.text
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.mono
                font.pixelSize: search.look.font.search
                Keys.forwardTo: search.target ? [search.target] : []
                onTextEdited: search.edited(text)
            }

            GlyphButton {
                id: clear
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                height: implicitHeight
                visible: search.query.length > 0
                glyphName: "close"
                glyphSize: search.look.toggleGlyph
                color: Appearance.color.textMuted
                onClicked: search.edited("")
            }
        }
    }
}
