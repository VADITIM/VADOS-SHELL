pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string searchScreen: ""
    property string settingsScreen: ""
    property string dashboardScreen: ""
    property string taskbarAwayScreen: ""
    property var settingsOrigins: ({})
    property var taskbarParts: ({})
    property var visitors: ({})

    signal taskbarGathering(string screenName)

    function isOverlayOn(screenName) {
        return searchScreen === screenName || settingsScreen === screenName || dashboardScreen === screenName
    }

    function gatherTaskbar(screenName) {
        taskbarGathering(screenName)
        taskbarAwayScreen = screenName
    }

    function toggleSearch(screenName) {
        if (searchScreen.length > 0) {
            searchScreen = ""
            return
        }
        settingsScreen = ""
        dashboardScreen = ""
        gatherTaskbar(screenName)
        searchScreen = screenName
    }

    function closeSearch() {
        searchScreen = ""
    }

    function toggleSettings(screenName) {
        if (settingsScreen.length > 0) {
            settingsScreen = ""
            return
        }
        searchScreen = ""
        dashboardScreen = ""
        gatherTaskbar(screenName)
        settingsScreen = screenName
    }

    function closeSettings() {
        settingsScreen = ""
    }

    function toggleDashboard(screenName) {
        if (dashboardScreen.length > 0) {
            dashboardScreen = ""
            return
        }
        searchScreen = ""
        settingsScreen = ""
        gatherTaskbar(screenName)
        dashboardScreen = screenName
    }

    function closeDashboard() {
        dashboardScreen = ""
    }

    function returnTaskbar(screenName) {
        if (taskbarAwayScreen === screenName && !isOverlayOn(screenName))
            taskbarAwayScreen = ""
    }

    function placeSettingsOrigin(screenName, origin) {
        const origins = Object.assign({}, settingsOrigins)
        origins[screenName] = origin
        settingsOrigins = origins
    }

    function placeVisitor(screenName, visitor) {
        const placed = Object.assign({}, visitors)
        placed[screenName] = visitor
        visitors = placed
    }

    function placeTaskbarParts(screenName, parts) {
        const placed = Object.assign({}, taskbarParts)
        placed[screenName] = parts
        taskbarParts = placed
    }
}
