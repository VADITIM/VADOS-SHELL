pragma Singleton
import QtQuick
import Quickshell
import "../utils/Builtins.js" as Catalogue

Singleton {
    id: builtins

    property var opened: []
    readonly property var apps: Catalogue.apps

    function isOpen(key) {
        return opened.indexOf(key) >= 0
    }

    function open(key) {
        opened = Catalogue.opened(opened, key)
    }

    function close(key) {
        opened = Catalogue.closed(opened, key)
    }

    function toggle(key) {
        opened = Catalogue.toggled(opened, key)
    }
}
