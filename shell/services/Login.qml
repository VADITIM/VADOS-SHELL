pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Log.js" as Log

Singleton {
    id: login

    property bool isWatching: false
    property var current: null
    property string problem: ""
    readonly property bool isKnown: current !== null
    readonly property bool canChoose: isKnown && current.hasSddm === true && current.hasTheme === true
    readonly property bool isVados: isKnown && current.current === "vados"
    readonly property string mainTheme: isKnown && current.main !== "vados" ? current.main : ""
    readonly property bool isBusy: stager.running || worker.running

    function refresh() {
        reader.running = true
    }

    function request(choice) {
        if (isBusy || !canChoose || (choice === "vados") === isVados)
            return
        problem = ""
        if (choice === "vados")
            stager.running = true
        else
            worker.begin("main", "", "", "")
    }

    onIsWatchingChanged: {
        if (isWatching)
            refresh()
    }

    Process {
        id: reader
        command: ["python3", Quickshell.shellPath("scripts/login.py"), "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    login.current = JSON.parse(text)
                } catch (error) {
                    Log.warn("login", "login.py status gave no readable answer; the login screen option stays hidden")
                }
            }
        }
    }

    Process {
        id: stager
        command: ["python3", Quickshell.shellPath("scripts/login.py"), "stage"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const staged = JSON.parse(text)
                    worker.begin("vados", staged.folder, staged.picture, staged.user)
                } catch (error) {
                    login.problem = "failed"
                    Log.warn("login", "login.py stage gave no readable answer; the login screen is unchanged")
                }
            }
        }
    }

    Process {
        id: worker

        function begin(choice, folder, picture, user) {
            command = ["pkexec", "/usr/bin/python3", Quickshell.shellPath("scripts/login.py"), "apply", choice, folder, picture, user]
            running = true
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    Log.warn("login", text.trim().split("\n").join("; "))
            }
        }
        onExited: code => {
            if (code !== 0) {
                login.problem = code === 126 ? "cancelled" : code === 127 ? "agent" : "failed"
                Log.warn("login", `login.py apply exited with code ${code}; the login screen is unchanged`)
            }
            login.refresh()
        }
    }
}
