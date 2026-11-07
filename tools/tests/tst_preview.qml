import QtQuick
import QtTest

TestCase {
    name: "Preview"

    function test_wholeShellLoadsWithoutWarnings() {
        failOnWarning(/.*/)
        const component = Qt.createComponent(Qt.resolvedUrl("../preview/play.qml"))
        compare(component.status, Component.Ready, component.errorString())
        const window = component.createObject(null)
        verify(window !== null)
        wait(800)
        window.destroy()
    }
}
