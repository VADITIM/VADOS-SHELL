import QtQuick

IdlePill {
    idleKey: "settings"
    glyphName: "settings"
    canExpand: false
    onActivated: host.settingsRequested()
}
