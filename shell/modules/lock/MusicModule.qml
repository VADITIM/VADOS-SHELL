import QtQuick
import qs.config
import qs.services
import qs.components

Item {
    id: music

    property Item host: null
    property bool isShown: false
    readonly property var look: Appearance.lock
    readonly property bool hasMedia: Activities.hasMedia

    anchors.fill: parent

    Column {
        anchors.centerIn: parent
        width: parent.width - music.look.padding * 2
        spacing: music.look.rowGap

        TypedText {
            width: parent.width
            target: music.hasMedia ? Activities.title : "NOTHING PLAYING"
            isShown: music.isShown
            elide: Text.ElideRight
            color: music.hasMedia ? Appearance.color.text : Appearance.color.textFaint
            font.family: music.hasMedia ? Appearance.font.sans : Appearance.font.mono
            font.pixelSize: music.hasMedia ? Appearance.font.body : Appearance.font.label
            font.letterSpacing: music.hasMedia ? 0 : Appearance.font.labelSpacing
        }

        TypedText {
            width: parent.width
            target: music.hasMedia ? Activities.artist : ""
            isShown: music.isShown && music.hasMedia
            elide: Text.ElideRight
            color: Appearance.color.textMuted
            font.family: Appearance.font.sans
            font.pixelSize: Appearance.font.label
        }

        Turn {
            width: parent.width
            height: music.look.bar
            isShown: music.isShown && music.hasMedia
            isFlipping: false

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Appearance.color.wash
            }

            Rectangle {
                width: parent.width * Activities.progress
                height: parent.height
                radius: height / 2
                color: Appearance.color.accent
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: music.look.padding

            Repeater {
                model: ["previous", "toggle", "next"]

                Turn {
                    id: control

                    required property string modelData
                    required property int index

                    isShown: music.isShown && music.hasMedia
                    enterDelay: index * Motion.pill.elementStagger
                    enterEasing: Easing.OutBack

                    GlyphButton {
                        glyphName: control.modelData === "toggle" ? (Activities.isPlaying ? "pause" : "play") : control.modelData
                        onClicked: {
                            if (control.modelData === "previous")
                                Activities.previous()
                            else if (control.modelData === "next")
                                Activities.next()
                            else
                                Activities.togglePlaying()
                        }
                    }
                }
            }
        }
    }
}
