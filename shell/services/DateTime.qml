pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property date now: clock.date
    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm:ss")
    readonly property string date: Qt.formatDateTime(clock.date, "ddd dd MMM").toUpperCase()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
