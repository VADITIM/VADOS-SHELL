import QtQuick
import qs.config
import qs.components
import "../../utils/Arithmetic.js" as Arithmetic

Item {
    id: calculator

    property bool isShown: false
    property var entry: Arithmetic.empty
    property string heldKey: ""
    readonly property var look: Appearance.calculator
    readonly property bool isReady: isShown && display.shown.length > 0
    readonly property string failure: Arithmetic.failure(entry)
    readonly property string preview: Arithmetic.preview(entry)
    readonly property string caption: failure === "divide" ? "CANNOT DIVIDE BY ZERO" : entry.isDone ? Arithmetic.shown(entry.previous) + " =" : preview.length > 0 ? "= " + preview : ""
    readonly property var keys: [
        { label: "C", key: "clear", kind: "action" }, { label: "(", key: "(", kind: "action" }, { label: ")", key: ")", kind: "action" }, { label: "÷", key: "/", kind: "operator" },
        { label: "7", key: "7", kind: "digit" }, { label: "8", key: "8", kind: "digit" }, { label: "9", key: "9", kind: "digit" }, { label: "×", key: "*", kind: "operator" },
        { label: "4", key: "4", kind: "digit" }, { label: "5", key: "5", kind: "digit" }, { label: "6", key: "6", kind: "digit" }, { label: "−", key: "-", kind: "operator" },
        { label: "1", key: "1", kind: "digit" }, { label: "2", key: "2", kind: "digit" }, { label: "3", key: "3", kind: "digit" }, { label: "+", key: "+", kind: "operator" },
        { label: "%", key: "%", kind: "action" }, { label: "0", key: "0", kind: "digit" }, { label: ".", key: ".", kind: "digit" }, { label: "=", key: "equals", kind: "equals" }
    ]
    readonly property int rows: Math.ceil(keys.length / look.columns)

    function press(key) {
        entry = Arithmetic.press(entry, key)
    }

    function keyOfEvent(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            return "equals"
        if (event.key === Qt.Key_Backspace)
            return "back"
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Delete)
            return "clear"
        return Arithmetic.keyOf(event.text)
    }

    function enterDelayOf(index) {
        const column = index % look.columns
        const row = Math.floor(index / look.columns)
        const reach = Math.hypot(column - (look.columns - 1) / 2, row - (rows - 1) / 2)
        return Math.round(reach * Motion.calculator.stagger)
    }

    focus: true
    Keys.onPressed: event => {
        const key = keyOfEvent(event)
        if (key.length === 0)
            return
        event.accepted = true
        heldKey = key
        press(key)
    }
    Keys.onReleased: event => {
        if (!event.isAutoRepeat)
            heldKey = ""
    }

    Column {
        id: screen
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: calculator.look.padding
        spacing: calculator.look.lineGap

        TypedText {
            width: parent.width
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            target: calculator.caption
            isShown: calculator.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: calculator.failure.length > 0 ? Appearance.color.danger : Appearance.color.textMuted
            font.family: Appearance.font.mono
            font.pixelSize: calculator.look.line
        }

        TypedText {
            id: display
            width: parent.width
            horizontalAlignment: Text.AlignRight
            target: calculator.entry.expression.length > 0 ? Arithmetic.shown(calculator.entry.expression) : "0"
            isShown: calculator.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: calculator.look.displayFloor
            font.family: Appearance.font.mono
            font.pixelSize: calculator.look.display
            font.bold: true
        }
    }

    Grid {
        id: pad
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: screen.bottom
        anchors.bottom: parent.bottom
        anchors.margins: calculator.look.padding
        columns: calculator.look.columns
        spacing: calculator.look.gap

        Repeater {
            model: calculator.keys

            CalculatorKey {
                required property var modelData
                required property int index
                width: (pad.width - pad.spacing * (pad.columns - 1)) / pad.columns
                height: (pad.height - pad.spacing * (calculator.rows - 1)) / calculator.rows
                label: modelData.label
                kind: modelData.kind
                isShown: calculator.isShown
                isHeld: calculator.heldKey === modelData.key
                enterDelay: calculator.enterDelayOf(index)
                onTapped: {
                    calculator.forceActiveFocus()
                    calculator.press(modelData.key)
                }
            }
        }
    }
}
