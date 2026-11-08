pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property var supervisors: []

    function enroll(supervisor) {
        if (supervisors.indexOf(supervisor) < 0)
            supervisors = supervisors.concat([supervisor])
    }

    function release(supervisor) {
        supervisors = supervisors.filter(entry => entry !== supervisor)
    }
}
