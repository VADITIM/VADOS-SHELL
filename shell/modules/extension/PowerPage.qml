import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/Controls.js" as Controls

Item {
    id: page

    property bool isOpen: false
    property bool isShown: false
    property bool isProtected: false
    readonly property real footHeight: height - header.y
    readonly property real area: height - footHeight - Appearance.extension.splitRoom

    signal protectRequested(bool isProtected)

    onIsOpenChanged: {
        Profiles.isWatching = isOpen
        Brightness.isWatching = isOpen
    }

    Item {
        id: header
        y: parent.height - height
        width: parent.width
        height: Appearance.extension.header

        Turn {
            flipAngle: 0
            spinAngle: Motion.extension.glyphSpin
            enterDuration: Motion.extension.glyphPop
            enterEasing: Easing.OutBack
            anchors.verticalCenter: parent.verticalCenter
            width: Appearance.extension.glyph
            height: Appearance.extension.glyph
            isShown: page.isShown

            Glyph {
                anchors.fill: parent
                name: "battery"
                level: Battery.level
                color: Appearance.color.accent
            }
        }

        ScrambleText {
            label: "extension header"
            anchors.verticalCenter: parent.verticalCenter
            x: Appearance.extension.glyph + 10
            width: Math.min(implicitWidth, parent.width - x)
            clip: true
            isShown: page.isShown
            target: "POWER"
            color: Appearance.color.text
            family: Appearance.font.sans
            pixelSize: Appearance.font.label
        }
    }

    Flickable {
        id: scroller
        y: (page.area - height) / 2
        width: parent.width
        height: Math.min(page.area, contentHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: content.height

        Drift {}

        Column {
            id: content
            width: parent.width
            spacing: Appearance.extension.rowGap

            Repeater {
                model: Profiles.keys

                delegate: Sprout {
                    look: Appearance.extension.sprout
                    pace: Motion.extension.sprout
                    id: profileTurn

                    required property string modelData
                    required property int index
                    readonly property bool isActive: Profiles.active === modelData
                    readonly property color hue: Appearance.extension.profileColors[modelData] ?? Appearance.color.accent

                    width: parent.width
                    height: Appearance.extension.row
                    isShown: page.isShown
                    enterDelay: index * Motion.extension.sprout.stagger

                    Press {
                        target: profileFace
                        isPressed: profileArea.pressed
                    }

                    Item {
                        id: profileFace
                        anchors.fill: parent

                        HoverHandler {
                            id: profileHover
                        }

                        Sweep {
                            anchors.fill: parent
                            isOn: profileHover.hovered
                            fill: Appearance.extension.hoverWash
                        }

                        Sweep {
                            anchors.fill: parent
                            isOn: profileTurn.isActive
                        }

                        Glyph {
                            x: Appearance.extension.rowPadding
                            anchors.verticalCenter: parent.verticalCenter
                            width: Appearance.extension.glyph
                            height: Appearance.extension.glyph
                            name: profileTurn.modelData
                            color: profileTurn.hue

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.pace(profileHover.hovered ? Motion.hoverIn : Motion.hoverOut)
                                }
                            }
                        }

                        Text {
                            x: Appearance.extension.rowPadding * 2 + Appearance.extension.glyph
                            anchors.verticalCenter: parent.verticalCenter
                            text: Controls.profileTitle(profileTurn.modelData)
                            color: profileTurn.isActive || profileHover.hovered ? Appearance.color.text : Appearance.color.textBody

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.pace(Motion.stateDuration)
                                    easing.type: Easing.OutQuad
                                }
                            }
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                            font.bold: true
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: Appearance.extension.rowPadding * 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: Appearance.extension.lock
                            height: width
                            radius: width / 2
                            color: profileTurn.hue
                            visible: profileTurn.isActive
                        }

                        MouseArea {
                            id: profileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Profiles.set(profileTurn.modelData)
                        }
                    }
                }
            }

            Sprout {
                look: Appearance.extension.sprout
                pace: Motion.extension.sprout
                width: parent.width
                height: brightness.height
                isShown: page.isShown && Brightness.isAvailable
                enterDelay: Profiles.keys.length * Motion.extension.sprout.stagger

                Column {
                    id: brightness
                    x: Appearance.extension.rowPadding
                    width: parent.width - Appearance.extension.rowPadding * 2
                    topPadding: Appearance.extension.sectionGap
                    spacing: Appearance.extension.sectionGap

                    Rectangle {
                        width: parent.width * drawn
                        height: Appearance.extension.divider
                        property real drawn: page.isShown ? 1 : 0
                        color: Appearance.color.hairline

                        Behavior on drawn {
                            NumberAnimation {
                                duration: Motion.pace(page.isShown ? Motion.extension.draw : Motion.extension.sprout.leave)
                                easing.type: page.isShown ? Easing.OutCubic : Easing.InQuad
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.max(name.implicitHeight, percent.implicitHeight)

                        Text {
                            id: name
                            anchors.verticalCenter: parent.verticalCenter
                            text: "BRIGHTNESS"
                            color: Appearance.color.textBody
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                            font.bold: true
                        }

                        Text {
                            id: percent
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Brightness.level * 100) + "%"
                            color: Appearance.color.textMuted
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                        }
                    }

                    Track {
                        width: parent.width
                        value: Brightness.level
                        hasSteps: true
                        isFilled: page.isShown
                        onMoved: value => Brightness.setLevel(value)
                    }
                }
            }

            Sprout {
                look: Appearance.extension.sprout
                pace: Motion.extension.sprout
                width: parent.width
                height: protect.height
                isShown: page.isShown && Battery.canLimit
                enterDelay: (Profiles.keys.length + 1) * Motion.extension.sprout.stagger

                Column {
                    id: protect
                    width: parent.width
                    topPadding: Appearance.extension.sectionGap
                    spacing: Appearance.extension.sectionGap

                    Rectangle {
                        x: Appearance.extension.rowPadding
                        width: (parent.width - Appearance.extension.rowPadding * 2) * drawn
                        height: Appearance.extension.divider
                        property real drawn: page.isShown ? 1 : 0
                        color: Appearance.color.hairline

                        Behavior on drawn {
                            NumberAnimation {
                                duration: Motion.pace(page.isShown ? Motion.extension.draw : Motion.extension.sprout.leave)
                                easing.type: page.isShown ? Easing.OutCubic : Easing.InQuad
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Appearance.extension.row

                        Press {
                            target: protectFace
                            isPressed: protectArea.pressed
                        }

                        Item {
                            id: protectFace
                            anchors.fill: parent

                            HoverHandler {
                                id: protectHover
                            }

                            Sweep {
                                anchors.fill: parent
                                isOn: protectHover.hovered
                                fill: Appearance.extension.hoverWash
                            }

                            Text {
                                x: Appearance.extension.rowPadding
                                anchors.verticalCenter: parent.verticalCenter
                                text: "PROTECT BATTERY"
                                color: page.isProtected || protectHover.hovered ? Appearance.color.text : Appearance.color.textBody

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Motion.pace(Motion.stateDuration)
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                font.family: Appearance.font.sans
                                font.pixelSize: Appearance.font.label
                                font.letterSpacing: Appearance.font.labelSpacing
                                font.bold: true
                            }

                            Rectangle {
                                id: toggle
                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.extension.rowPadding
                                anchors.verticalCenter: parent.verticalCenter
                                width: Appearance.extension.toggleWidth
                                height: Appearance.extension.toggleHeight
                                radius: height / 2
                                color: page.isProtected ? Appearance.color.accent : Appearance.color.hairline

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Motion.pace(Motion.stateDuration)
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Motion.pace(Motion.stateDuration)
                                    }
                                }

                                Rectangle {
                                    readonly property real size: toggle.height - Appearance.extension.toggleInset * 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: page.isProtected ? toggle.width - size - Appearance.extension.toggleInset : Appearance.extension.toggleInset
                                    width: size
                                    height: size
                                    radius: size / 2
                                    color: page.isProtected ? Appearance.color.panel : Appearance.color.textBody

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Motion.pace(Motion.stateDuration)
                                            easing.type: Easing.OutQuad
                                        }
                                    }

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: Motion.pace(Motion.stateDuration)
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: protectArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.protectRequested(!page.isProtected)
                            }
                        }
                    }
                }
            }
        }
    }
}
