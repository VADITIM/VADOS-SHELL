pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs.config
import "../utils/Prompts.js" as Prompts
import "../utils/Log.js" as Log

Singleton {
    id: polkit

    readonly property bool isEnabled: Config.data.prompts.enabled
    readonly property bool isRegistered: loader.item?.isRegistered ?? false
    readonly property var flow: loader.item?.flow ?? null
    property int attempt: 0
    property int version: 0
    readonly property var request: {
        version
        return Prompts.fromPolkit(flow, attempt)
    }

    function submit(password) {
        if (flow && flow.isResponseRequired)
            flow.submit(password)
    }

    function cancel() {
        if (flow && !flow.isCompleted)
            flow.cancelAuthenticationRequest()
    }

    onFlowChanged: {
        attempt = 0
        if (flow)
            Log.info("polkit", "asked for admin rights: " + flow.actionId)
    }
    onIsRegisteredChanged: {
        if (isRegistered)
            Log.info("polkit", "registered as the polkit agent")
        else if (isEnabled)
            Log.warn("polkit", "not registered as the polkit agent; is another agent (polkit-gnome, polkit-kde) still running?")
    }

    Connections {
        target: polkit.flow
        ignoreUnknownSignals: true

        function onIsResponseRequiredChanged() {
            polkit.version++
        }
        function onInputPromptChanged() {
            polkit.version++
        }
        function onResponseVisibleChanged() {
            polkit.version++
        }
        function onSupplementaryMessageChanged() {
            polkit.version++
        }
        function onIsCompletedChanged() {
            if (polkit.flow?.isCompleted)
                Log.info("polkit", polkit.flow.isSuccessful ? "authorized" : polkit.flow.isCancelled ? "cancelled" : "not authorized")
            polkit.version++
        }
        function onAuthenticationFailed() {
            polkit.attempt++
            polkit.version++
        }
    }

    LazyLoader {
        id: loader
        active: polkit.isEnabled

        PolkitAgent {}
    }
}
