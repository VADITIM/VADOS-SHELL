import QtQuick
import qs.config
import qs.components

Turn {
    id: piece

    readonly property bool isPiece: true
    property string role: "control"
    property bool isMirrored: false
    property bool isWanted: true
    property bool isCentered: false
    readonly property string motion: isFlipping ? role : "own"
    readonly property real reveal: motion === "own" ? 1 : presence
    readonly property real away: 1 - reveal
    readonly property var look: Appearance.settings.piece

    function enlist() {
        let holder = parent
        while (holder && holder.isPage !== true)
            holder = holder.parent
        if (holder)
            holder.enlist()
    }

    enterEasing: motion === "hint" ? Easing.OutQuad : motion === "label" || motion === "title" || motion === "surface" ? Easing.OutCubic : Easing.OutBack
    enterDuration: motion === "surface" ? Motion.settings.surfaceEnter : motion === "own" ? Motion.pill.element : Motion.settings.pieceEnter
    isShaped: false
    leaveWindow: 0
    leaveDelay: motion === "card" ? Motion.settings.cardLeaveDelay : motion === "title" ? Motion.settings.titleLeaveDelay : 0
    leaveDuration: motion === "card" ? Motion.settings.cardLeave : motion === "own" ? Motion.settings.pageSwap : Motion.settings.innerLeave
    opacity: motion === "own" ? (presence > 0 ? 1 : 0) : Math.min(1, reveal * look.fadeLead)
    transform: [
        Scale {
            readonly property real grown: piece.motion === "control" ? piece.look.pop + (1 - piece.look.pop) * piece.reveal : piece.motion === "surface" ? piece.look.surface + (1 - piece.look.surface) * piece.reveal : 1

            origin.x: piece.motion === "surface" || piece.isCentered ? piece.width / 2 : piece.isMirrored ? piece.width : 0
            origin.y: piece.height / 2
            xScale: piece.motion === "card" ? Math.max(0.001, piece.reveal) : grown
            yScale: piece.motion === "card" ? piece.look.squash + (1 - piece.look.squash) * piece.reveal : grown
        },
        Translate {
            x: piece.motion === "title" ? (piece.isMirrored ? 1 : -1) * piece.look.slide * piece.away : 0
            y: piece.motion === "label" ? piece.look.rise * piece.away : piece.motion === "hint" ? piece.look.hintRise * piece.away : 0
        }
    ]

    Component.onCompleted: enlist()
}
