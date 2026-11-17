pragma Singleton
import QtQuick
QtObject {
    property bool isWatching: false
    property var defaulted: []
    property var opened: []
    readonly property var rows: [
        { key: "files", label: "FILES", role: "FILE MANAGER", isInstalled: true, canBeDefault: true, isDefault: defaulted.indexOf("files") >= 0, icon: "" },
        { key: "gallery", label: "GALLERY", role: "IMAGES AND VIDEO", isInstalled: true, canBeDefault: true, isDefault: true, icon: "" },
        { key: "notes", label: "NOTES", role: "NOTES AND TEXT", isInstalled: false, canBeDefault: false, isDefault: false, icon: "" },
        { key: "terminal", label: "TERMINAL", role: "TERMINAL", isInstalled: false, canBeDefault: false, isDefault: false, icon: "" }
    ]
    function refresh() {}
    function makeDefault(key) { defaulted = defaulted.concat([key]) }
    function openReleases(key) { opened = opened.concat([key]) }
}
