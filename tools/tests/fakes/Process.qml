import QtQuick

QtObject {
    property list<string> command
    property bool running: false
    property var processId: null
    property string workingDirectory: ""
    property var environment: ({})
    property bool clearEnvironment: false
    property bool stdinEnabled: false
    property QtObject stdout: null
    property QtObject stderr: null

    signal started()
    signal exited(int exitCode, int exitStatus)

    function startDetached() {}

    function write(data) {}

    onRunningChanged: if (running) started()
}
