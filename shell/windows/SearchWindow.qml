import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.state
import qs.modules.search

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isOpen: Visibilities.searchScreen === screenName

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    visible: search.isPresent
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vados-search"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    Search {
        id: search
        anchors.fill: parent
        isOpen: window.isOpen
        favoriteIds: Config.data.search.favorites
        profileName: Config.data.profile.name
        profilePicture: Config.data.profile.picture
        parts: Visibilities.taskbarParts[window.screenName] ?? []
        isMirrored: Config.data.taskbar.side === "right"
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: Visibilities.placeVisitor(window.screenName, visitor)
        onCloseRequested: Visibilities.closeSearch()
        onLanded: Visibilities.returnTaskbar(window.screenName)
        onFavoriteToggled: appId => Config.toggleFavorite(appId)
    }
}
