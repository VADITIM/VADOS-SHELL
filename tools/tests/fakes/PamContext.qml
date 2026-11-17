import QtQuick

QtObject {
    id: context

    property bool active: false
    property string config: "login"
    property string configDirectory: "/etc/pam.d"
    property string user: ""
    property string message: ""
    property bool messageIsError: false
    property bool responseRequired: false
    property bool responseVisible: false
    property string accepted: "secret"
    property bool canStart: true
    property bool isAnswering: true
    property int responses: 0

    signal completed(int result)
    signal error(int error)
    signal pamMessage()

    function start() {
        if (!canStart || active)
            return false
        active = true
        message = "Password: "
        messageIsError = false
        responseRequired = true
        Qt.callLater(() => context.pamMessage())
        return true
    }

    function respond(response) {
        responseRequired = false
        responses += 1
        if (!isAnswering)
            return
        const result = response === accepted ? 0 : 1
        Qt.callLater(() => {
            context.active = false
            context.completed(result)
        })
    }

    function abort() {
        active = false
        responseRequired = false
    }
}
