import QtQuick
import qs.config
import qs.components

Turn {
    readonly property bool isPiece: true

    enterEasing: Easing.OutBack
    leaveWindow: 0
    leaveDuration: Motion.settings.pageSwap
}
