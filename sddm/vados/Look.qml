import QtQuick

QtObject {
    id: look

    property var settings: ({})
    property bool isLeaving: false
    readonly property Tokens tokens: Tokens {}
    readonly property color accent: String(settings.accent || "") !== "" ? settings.accent : tokens.color.defaultAccent
    readonly property bool isReduced: String(settings.reducedMotion) === "true"
    readonly property bool isLite: String(settings.quality) === "lite"
    readonly property string background: String(settings.background || "")
    readonly property var monoFallbacks: [tokens.font.mono, "DejaVu Sans Mono", "Liberation Mono", "Courier New"]
    readonly property string mono: monoFallbacks.find(name => Qt.fontFamilies().indexOf(name) >= 0) ?? tokens.font.mono

    function pace(duration) {
        return isReduced ? 0 : duration
    }
}
