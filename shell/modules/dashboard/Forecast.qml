import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: forecast

    property bool isShown: false
    property int enterDelay: 0
    property real stagger: 0
    readonly property var look: Appearance.dashboard.weather
    readonly property bool isPresent: now.presence > 0.5

    height: look.daysY + look.dayTile + Appearance.dashboard.font.label * 2

    function degrees(value) {
        return Weather.isReady ? Math.round(value) + "°" : "--°"
    }

    Turn {
        id: now
        width: forecast.width
        height: forecast.look.icon
        isShown: forecast.isShown
        enterDelay: forecast.enterDelay
        enterDuration: Motion.search.tileEnter

        Glyph {
            width: forecast.look.icon
            height: forecast.look.icon
            name: "weather-" + Weather.kind
            stroke: Appearance.dashboard.iconStroke * 24 / width
            color: Appearance.color.text
        }

        TypedText {
            id: temperature
            x: forecast.look.icon + forecast.look.iconGap
            y: (forecast.look.icon - height) / 2 - Appearance.dashboard.font.label
            target: forecast.degrees(Weather.temperature)
            isShown: forecast.isPresent
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.dashboard.font.degrees
        }

        Row {
            x: temperature.x
            y: temperature.y + temperature.height
            spacing: Appearance.unit.base

            TypedText {
                anchors.verticalCenter: parent.verticalCenter
                target: Weather.isReady ? Math.round(Weather.rainChance * 100) + "%" : "--%"
                isShown: forecast.isPresent
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.dashboard.font.label
            }

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                width: forecast.look.rain
                height: forecast.look.rain
                name: "umbrella"
                color: Appearance.color.textMuted
            }
        }
    }

    Row {
        y: forecast.look.daysY
        spacing: forecast.look.dayGap

        Repeater {
            model: Weather.isReady ? Weather.days : Weather.forecastDays

            Turn {
                id: day
                required property int index
                required property var modelData
                readonly property var reading: typeof modelData === "object" ? modelData : null
                width: forecast.look.dayTile
                height: forecast.look.dayTile + Appearance.dashboard.font.label * 2
                isShown: forecast.isShown
                enterDelay: forecast.enterDelay + index * forecast.stagger
                enterDuration: Motion.search.tileEnter

                Rectangle {
                    width: forecast.look.dayTile
                    height: forecast.look.dayTile
                    radius: Appearance.radius.small
                    color: "transparent"
                    border.width: 1
                    border.color: Appearance.color.textMuted

                    Glyph {
                        anchors.centerIn: parent
                        width: forecast.look.dayGlyph
                        height: forecast.look.dayGlyph
                        name: "weather-" + (day.reading?.kind ?? "cloudy")
                        stroke: Appearance.dashboard.iconStroke * 24 / width
                        color: Appearance.color.text
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: forecast.look.dayTile + Appearance.unit.base
                    text: forecast.degrees(day.reading?.high ?? 0)
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.dashboard.font.day
                }
            }
        }
    }
}
