pragma Singleton
import QtQuick
import Quickshell
import "../utils/Prompts.js" as Prompts
import "../utils/Log.js" as Log

Singleton {
    id: passwords

    readonly property var request: Prompts.pick(Polkit.request, Keyring.request)

    function submit(password, isChoiceChosen) {
        if (!request)
            return
        if (request.source === "polkit")
            Polkit.submit(password)
        else
            Keyring.answer(true, password, isChoiceChosen)
    }

    function cancel(reason) {
        if (!request)
            return
        Log.info("prompt", "cancelled the " + request.source + " request: " + reason)
        if (request.source === "polkit")
            Polkit.cancel()
        else
            Keyring.cancel()
    }
}
