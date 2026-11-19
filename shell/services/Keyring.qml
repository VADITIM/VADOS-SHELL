pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../utils/Prompts.js" as Prompts
import "../utils/Log.js" as Log

Singleton {
    id: keyring

    readonly property bool isEnabled: Config.data.prompts.enabled
    property bool isServing: false
    property var request: null

    function answer(isContinue, password, isChoiceChosen) {
        if (!request || !helper.running)
            return
        helper.write(JSON.stringify(Prompts.keyringReply(request, isContinue, password, isChoiceChosen)) + "\n")
        request = null
    }

    function cancel() {
        answer(false, "", false)
    }

    function receive(line) {
        let event = null
        try {
            event = JSON.parse(line)
        } catch (error) {
            Log.warn("keyring", "keyring.py said something unreadable; ignored")
            return
        }
        if (event.kind === "ready") {
            isServing = true
            Log.info("keyring", "serving as the keyring prompter")
        } else if (event.kind === "lost") {
            isServing = false
            Log.warn("keyring", "another keyring prompter owns the name; gcr-prompter keeps asking")
        } else if (event.kind === "close") {
            if (request && request.id === event.id)
                request = null
        } else {
            request = Prompts.fromKeyring(event)
            Log.info("keyring", "asked for a " + event.kind + " (prompt " + event.id + ")")
        }
    }

    Process {
        id: helper
        command: ["python3", Quickshell.shellPath("scripts/keyring.py")]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => keyring.receive(line)
        }
        onRunningChanged: {
            if (!running) {
                keyring.isServing = false
                keyring.request = null
            }
        }
    }

    Supervisor {
        name: "keyring"
        process: helper
        isActive: keyring.isEnabled
    }
}
