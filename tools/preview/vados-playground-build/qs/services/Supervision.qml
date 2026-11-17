pragma Singleton
import QtQuick
QtObject {
    property var supervisors: []
    function enroll(supervisor) {}
    function release(supervisor) {}
}
