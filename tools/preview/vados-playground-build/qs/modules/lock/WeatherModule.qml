import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: weather

    property Item host: null
    property bool isShown: false
    readonly property var look: Appearance.lock

    anchors.fill: parent

    Row {
        anchors.centerIn: parent
        spacing: weather.look.padding

        Turn {
            anchors.verticalCenter: parent.verticalCenter
            isShown: weather.isShown
            enterEasing: Easing.OutBack

            Glyph {
                width: weather.look.weatherGlyph
                height: width
                name: "weather-" + Weather.kind
                color: Appearance.color.accent
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.unit.base

            TypedText {
                target: Weather.isReady ? Math.round(Weather.temperature) + "°" : "--"
                isShown: weather.isShown
                color: Appearance.color.text
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.degrees
            }

            TypedText {
                target: Weather.isReady ? "RAIN " + Math.round(Weather.rainChance * 100) + "%" : "WEATHER"
                isShown: weather.isShown
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }
    }
}
