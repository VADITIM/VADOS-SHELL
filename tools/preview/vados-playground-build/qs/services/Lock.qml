pragma Singleton
import QtQuick
QtObject {
    readonly property bool canLock: true
    property bool isLocked: false
    property bool isSecure: isLocked
    property bool isChecking: false
    property string screenName: "play"
    property string message: ""
    property bool isMessageError: false
    property int failures: 0
    property bool isBlank: false
    readonly property int blankAfter: 60
    readonly property string status: !isLocked ? "unlocked" : isBlank ? "blank" : "locked"
    signal unlocked()
    function lock() { isLocked = true; return true }
    function submit(password) {
        if (!isLocked || password.length === 0)
            return
        if (password === "vados") {
            isLocked = false
            failures = 0
            message = ""
            unlocked()
            return
        }
        failures++
        message = "WRONG PASSWORD"
        isMessageError = true
    }
    function reportSecure(isConfirmed) {}
    function reportLost() { isLocked = false }
}
