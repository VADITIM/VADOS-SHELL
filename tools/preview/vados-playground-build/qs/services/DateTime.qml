pragma Singleton
import QtQuick
QtObject {
    property date now: new Date()
    readonly property string time: Qt.formatDateTime(now, "hh:mm:ss")
    readonly property string date: Qt.formatDateTime(now, "ddd dd MMM").toUpperCase()
    property Timer ticker: Timer { interval: 1000; running: true; repeat: true; onTriggered: now = new Date() }
}
