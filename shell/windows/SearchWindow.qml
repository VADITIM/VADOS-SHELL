import QtQuick
import qs.config
import qs.modules.search

OverlayWindow {
    id: window

    overlayKey: "search"
    isPresent: search.isPresent

    Search {
        id: search
        anchors.fill: parent
        isOpen: window.isOpen
        favoriteIds: Config.data.search.favorites
        profileName: Config.data.profile.name
        profilePicture: Config.data.profile.picture
        parts: window.parts
        isMirrored: Config.data.taskbar.side === "right"
        canHandOff: Config.data.taskbar.style !== "bare"
        onVisitorChanged: window.placeVisitor(visitor)
        onCloseRequested: window.requestClose()
        onLanded: window.land()
        onFavoriteToggled: appId => Config.toggleFavorite(appId)
    }
}
