pragma Singleton
import QtQuick
QtObject {
    property var items: [{ id: "network", title: "Network", icon: "" }, { id: "steam", title: "Steam", icon: "" }, { id: "keepassxc", title: "KeePassXC", icon: "" }]
    property var opened: []
    function open(item, window, x, y) { opened = opened.concat([item.id]) }
    function openMenu(item, window, x, y) { opened = opened.concat([item.id + " menu"]) }
}
