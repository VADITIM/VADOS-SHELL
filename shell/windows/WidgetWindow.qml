import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.wallpaper
import qs.modules.widgets
import "../utils/Widgets.js" as Widgets

PanelWindow {
    id: window

    readonly property string screenName: screen?.name ?? ""
    readonly property bool isOverBackground: Compositor.capabilities.ownBackground
    readonly property bool isCovered: Compositor.activeWindow?.isFullscreen === true && Compositor.activeWindow.screen === screenName

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: isOverBackground ? WlrLayer.Bottom : WlrLayer.Background
    WlrLayershell.namespace: "vados-wallpaper"
    WlrLayershell.keyboardFocus: widgets.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"
    mask: Region {
        regions: zones.instances
    }

    Variants {
        id: zones
        model: widgets.zones

        Region {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: modelData.width
            height: modelData.height
        }
    }

    Wallpaper {
        anchors.fill: parent
        source: window.isOverBackground ? "" : Config.data.wallpaper.path
    }

    WidgetLayer {
        id: widgets
        anchors.fill: parent
        layout: Widgets.layoutOn(Config.data.widgets.layout, window.screenName)
        isCovered: window.isCovered
        onLayoutRequested: entries => Config.setWidgetsLayout(Widgets.withLayout(Config.data.widgets.layout, window.screenName, entries))
    }
}
