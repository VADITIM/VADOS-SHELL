pragma Singleton
import QtQuick
import VadosTest

QtObject {
    readonly property string home: "HOME_DIRECTORY"
    property var screens: [{ name: "play", width: 1600, height: 900 }]

    function env(name) {
        return name === "HOME" ? home : ""
    }

    function readFile(path) {
        return Disk.read(path)
    }

    function writeFile(path, text) {
        Disk.write(path, text)
    }

    function execDetached(command) {
        if (command[0] === "cp")
            writeFile(command[2], readFile(command[1]))
    }
}
