pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Keyboards.js" as KeyboardLayouts
import "../utils/Log.js" as Log

Singleton {
    id: keyboards

    property bool isWatching: false
    property var choices: []
    property var devices: []
    property var boards: []
    property var board: ({})
    property string boardPath: ""
    property bool isDenied: false
    property bool isAdmin: false
    property string problem: ""
    readonly property bool isBusy: reader.running || writer.running
    readonly property string rulesPath: "/usr/share/X11/xkb/rules/evdev.lst"

    function refresh() {
        deviceQuery.running = true
        boardQuery.running = true
        rules.reload()
    }

    function commandFor(verb, path, asAdmin, extra) {
        const command = ["python3", Quickshell.shellPath("scripts/keyboards.py"), verb, path].concat(extra)
        return asAdmin ? ["pkexec"].concat(command) : command
    }

    function readBoard(path, asAdmin) {
        if (isBusy || path.length === 0)
            return
        boardPath = path
        isAdmin = asAdmin
        problem = ""
        board = ({})
        reader.command = commandFor("read", path, asAdmin, [])
        reader.running = true
    }

    function writeKeys(changes) {
        if (isBusy || boardPath.length === 0 || changes.length === 0)
            return
        Log.info("keyboards", "writing " + changes.length + " keys to " + boardPath + (isAdmin ? " as admin" : ""))
        writer.command = commandFor("write", boardPath, isAdmin, [JSON.stringify(changes)])
        writer.running = true
    }

    function receive(text) {
        if (text.trim().length === 0)
            return
        try {
            board = JSON.parse(text)
        } catch (error) {
            problem = "THE KEYBOARD DID NOT ANSWER"
        }
    }

    onIsWatchingChanged: {
        if (isWatching)
            refresh()
    }

    FileView {
        id: rules
        path: keyboards.isWatching ? keyboards.rulesPath : ""
        printErrors: false
        onLoaded: keyboards.choices = KeyboardLayouts.parseRules(text())
        onLoadFailed: Log.warn("keyboards", "cannot read " + keyboards.rulesPath + ", no layouts to pick from")
    }

    Process {
        id: deviceQuery
        command: ["cat", "/proc/bus/input/devices"]
        stdout: StdioCollector {
            onStreamFinished: keyboards.devices = KeyboardLayouts.parseDevices(text)
        }
    }

    Process {
        id: boardQuery
        command: ["python3", Quickshell.shellPath("scripts/keyboards.py"), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    keyboards.boards = JSON.parse(text)
                } catch (error) {
                    keyboards.boards = []
                }
            }
        }
    }

    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: keyboards.receive(text)
        }
        stderr: StdioCollector {
            id: readError
        }
        onExited: code => {
            keyboards.isDenied = code === 3
            if (code !== 0) {
                keyboards.problem = code === 3 ? "NO ACCESS" : "THE KEYBOARD DID NOT ANSWER"
                Log.warn("keyboards", "reading " + keyboards.boardPath + " exited with code " + code + ": " + readError.text.trim())
                return
            }
        }
    }

    Process {
        id: writer
        stdout: StdioCollector {
            onStreamFinished: keyboards.receive(text)
        }
        stderr: StdioCollector {
            id: writeError
        }
        onExited: code => {
            if (code !== 0) {
                keyboards.problem = "THE KEYS WERE NOT WRITTEN"
                Log.warn("keyboards", "writing to " + keyboards.boardPath + " exited with code " + code + ": " + writeError.text.trim())
                return
            }
            Log.info("keyboards", writeError.text.trim())
        }
    }
}
