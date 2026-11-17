pragma Singleton
import QtQuick
QtObject {
    property bool isPicking: false
    property var asked: []
    function choose(title, kind, onChosen) { asked = asked.concat([kind]); onChosen([]); return true }
}
