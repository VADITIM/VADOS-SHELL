import QtQuick
import qs.config
import qs.state
import qs.modules.search

OverlayWindow {
    id: window

    overlayKey: "search"
    isPresent: search.isPresent
    phase: search.phase

    Search {
        id: search
        anchors.fill: parent
        isOpen: window.isOpen
        favoriteIds: Config.data.search.favorites
        hiddenIds: Config.data.search.hidden
        profileName: Config.data.profile.name
        profilePicture: Config.data.profile.picture
        parts: window.parts
        shouldStream: window.shouldStream
        isMirrored: Config.data.taskbar.side === "right"
        canHandOff: window.canHandOff
        isHandingOver: window.isHandingOver
        hasCircle: window.hasCircle
        onVisitorChanged: window.placeVisitor(visitor)
        onIsCarryingChanged: window.carry(isCarrying)
        onCloseRequested: window.requestClose()
        onLanded: window.land()
        onFavoriteToggled: appId => Config.toggleFavorite(appId)
        onHiddenToggled: appId => Config.toggleHidden(appId)
        onProfileRequested: Overlays.open("settings", window.screenName, "user")
    }
}
