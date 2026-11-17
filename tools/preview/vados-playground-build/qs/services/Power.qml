pragma Singleton
import QtQuick
QtObject {
    function lock() { Lock.lock() }
    function suspend() { console.log("power: suspend") }
    function restart() { console.log("power: restart") }
    function shutdown() { console.log("power: shutdown") }
}
