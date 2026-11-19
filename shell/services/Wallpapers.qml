pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.config

Singleton {
    id: wallpapers

    property bool isWatching: false
    property var images: []
    readonly property string home: Quickshell.env("HOME") ?? ""
    readonly property string picturesFolder: Quickshell.env("XDG_PICTURES_DIR") || home + "/Pictures"
    readonly property string defaultFolder: picturesFolder + "/Wallpapers"
    readonly property string folder: Config.data.wallpaper.folder || defaultFolder

    function reveal(place) {
        Quickshell.execDetached(["xdg-open", place || folder])
    }

    function collect(listing) {
        const found = []
        for (let index = 0; index < listing.count; index++)
            found.push(listing.get(index, "filePath"))
        images = found
    }

    Instantiator {
        active: wallpapers.isWatching
        model: 1

        FolderListModel {
            id: listing
            folder: "file://" + wallpapers.folder
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
            caseSensitive: false
            showDirs: false
            sortField: FolderListModel.Name
            onStatusChanged: if (status === FolderListModel.Ready) wallpapers.collect(listing)
            onCountChanged: if (status === FolderListModel.Ready) wallpapers.collect(listing)
        }
    }
}
