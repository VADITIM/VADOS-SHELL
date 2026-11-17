pragma Singleton
import QtQuick
QtObject {
    property bool covered: false
    function isCovered(name, isHolding) { return covered }
}
