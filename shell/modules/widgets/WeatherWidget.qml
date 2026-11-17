import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: face

    property bool isShown: false
    property bool isLive: false
    property var reading: ({ isReady: false, temperature: 0, rainChance: 0, kind: "cloudy", days: [] })
    readonly property var look: Appearance.widgets

    function degrees(value) {
        return reading.isReady ? Math.round(value) + "°" : "--°"
    }

    Binding on reading {
        when: face.isLive
        restoreMode: Binding.RestoreNone
        value: ({ isReady: Weather.isReady, temperature: Weather.temperature, rainChance: Weather.rainChance, kind: Weather.kind, days: Weather.days })
    }

    Turn {
        id: now
        anchors.verticalCenter: parent.verticalCenter
        width: face.look.weatherGlyph
        height: face.look.weatherGlyph
        isShown: face.isShown
        enterEasing: Easing.OutBack
        spinAngle: Motion.widgets.glyphSpin

        Glyph {
            width: face.look.weatherGlyph
            height: face.look.weatherGlyph
            name: "weather-" + face.reading.kind
            color: Appearance.color.text
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        x: now.width + face.look.gap

        TypedText {
            target: face.degrees(face.reading.temperature)
            isShown: face.isShown
            characterInterval: Motion.type.quick
            untypeInterval: Motion.type.quickUntype
            color: Appearance.color.text
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.degrees
            font.bold: true
        }

        Row {
            spacing: Appearance.unit.base

            TypedText {
                anchors.verticalCenter: parent.verticalCenter
                target: face.reading.isReady ? Math.round(face.reading.rainChance * 100) + "%" : "--%"
                isShown: face.isShown
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                color: Appearance.color.textMuted
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
            }

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.font.label
                height: Appearance.font.label
                name: "umbrella"
                color: Appearance.color.textMuted
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: face.look.gap

        Repeater {
            model: Weather.forecastDays

            Turn {
                id: day

                required property int index
                readonly property var forecast: face.reading.days[index] ?? null

                width: face.look.dayGlyph + face.look.gap
                height: face.look.dayGlyph + Appearance.font.label + face.look.captionGap
                isShown: face.isShown
                enterDelay: index * Motion.widgets.stagger
                enterEasing: Easing.OutBack

                Glyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: face.look.dayGlyph
                    height: face.look.dayGlyph
                    name: "weather-" + (day.forecast?.kind ?? "cloudy")
                    color: Appearance.color.text
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: face.degrees(day.forecast?.high ?? 0)
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                }
            }
        }
    }
}
