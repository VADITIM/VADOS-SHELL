import QtQuick
import qs.config
import qs.components

Turn {
    property string pageKey
    property string shownKey
    property bool isContentShown: false

    isShown: isContentShown && shownKey === pageKey
    visible: presence > 0.001
    enterDuration: Motion.pill.element
    enterEasing: Easing.OutBack
    leaveWindow: 0
    leaveDuration: Motion.settings.pageSwap
}
