pragma Singleton
import QtQuick
QtObject {
    property bool isWatching: false
    property var images: []
    readonly property string folder: "/home/user/Pictures/Wallpapers"
}
