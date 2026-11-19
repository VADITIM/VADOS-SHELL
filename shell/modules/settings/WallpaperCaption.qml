import QtQuick
import qs.config
import qs.services

Item {
    id: caption

    required property var carousel
    property bool isLocking: false
    property string folder: ""
    property string lockWallpaper: ""
    readonly property bool isOutside: carousel.isOutside && carousel.target === carousel.currentIndex
    readonly property var look: Appearance.settings.wallpaper

    signal folderRequested(string folder)
    signal lockWallpaperRequested(string value)

    Piece {
        role: "label"
        x: caption.carousel.mainLeft
        y: caption.carousel.mainTop + caption.carousel.mainHeight + caption.look.captionGap

        Column {
            spacing: Appearance.unit.small

            Text {
                text: caption.carousel.nameOf(caption.isOutside ? caption.carousel.current : caption.carousel.entries[caption.carousel.target] ?? "")
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: caption.look.captionName
                font.bold: true
            }

            Text {
                text: caption.carousel.hasImages && !caption.isOutside ? (caption.carousel.target - caption.carousel.first + 1) + " / " + Wallpapers.images.length : ""
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: caption.look.captionCount
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }

    TextField {
        x: caption.carousel.mainLeft
        y: caption.carousel.mainTop - caption.look.captionGap - height
        label: caption.isLocking ? "WALLPAPER" : "FOLDER"
        actionLabel: "FIND"
        placeholder: caption.isLocking ? "IMAGE PATH" : Wallpapers.folder
        value: caption.isLocking ? caption.lockWallpaper : caption.folder
        fieldWidth: Math.min(caption.look.fieldWidth, (caption.carousel.mainWidth - caption.carousel.mainWidth * caption.look.near) / 2 - caption.look.captionGap)
        onEdited: value => caption.isLocking ? caption.lockWallpaperRequested(value) : caption.folderRequested(value)
        onActionTapped: Wallpapers.reveal(caption.isLocking && caption.lockWallpaper.startsWith("/") ? caption.lockWallpaper.slice(0, caption.lockWallpaper.lastIndexOf("/")) : "")
    }
}
