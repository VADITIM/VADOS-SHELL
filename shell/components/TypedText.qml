import QtQuick
import qs.config

Text {
    id: typed

    property string target
    property bool isShown: true
    property string shown: ""
    property int characterInterval: Motion.type.character
    property int untypeInterval: Motion.type.untype
    property bool holdsWidth: false
    property real nextStep: 0
    readonly property real fullWidth: measure.implicitWidth

    text: shown
    textFormat: Text.PlainText
    width: holdsWidth ? fullWidth : implicitWidth
    height: measure.implicitHeight

    function advance() {
        const wanted = isShown ? target : ""
        if (shown === wanted)
            return 0
        if (!wanted.startsWith(shown)) {
            shown = shown.slice(0, -1)
            return untypeInterval
        }
        shown = wanted.slice(0, shown.length + 1)
        return characterInterval
    }

    function step() {
        const now = Date.now()
        while (now >= nextStep) {
            const spent = advance()
            if (spent === 0) {
                typer.stop()
                return
            }
            nextStep += spent
        }
    }

    function restart() {
        if (typer.running)
            return
        nextStep = Date.now()
        typer.start()
    }

    function clear() {
        typer.stop()
        shown = ""
    }

    onTargetChanged: restart()
    onIsShownChanged: restart()
    Component.onCompleted: restart()

    Text {
        id: measure
        visible: false
        text: typed.target.length > 0 ? typed.target : " "
        textFormat: Text.PlainText
        font.family: typed.font.family
        font.pixelSize: typed.font.pixelSize
        font.bold: typed.font.bold
        font.letterSpacing: typed.font.letterSpacing
    }

    Timer {
        id: typer
        interval: 8
        repeat: true
        triggeredOnStart: true
        onTriggered: typed.step()
    }
}
