import QtQuick
import qs.config
import qs.components
import qs.services
import "../../utils/Geometry.js" as Geometry

Flow {
    id: page

    property bool isShown: false
    property string picked: ""
    readonly property var look: Appearance.settings.section
    readonly property string applied: SystemFont.applied
    readonly property bool canApply: picked.length > 0 && picked !== applied && !SystemFont.isBusy

    signal fontRequested(string family)

    spacing: look.columnGap

    onIsShownChanged: {
        SystemFont.isWatching = isShown
        if (!isShown)
            picked = ""
    }

    Section {
        title: "SYSTEM FONT"

        Item {
            width: parent.width
            height: Appearance.settings.option

            Piece {
                role: "label"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "CURRENT"
                    color: Appearance.color.textBody
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }
            }

            Piece {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: page.applied.length > 0 ? page.applied.toUpperCase() : "UNCHANGED"
                    color: page.applied.length > 0 ? Appearance.color.accent : Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                    font.bold: true
                }
            }
        }

        Piece {
            width: parent.width
            height: page.look.preview * 2

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                elide: Text.ElideRight
                text: page.picked.length > 0 ? "The quick brown fox 0123456789" : "PICK A FAMILY TO PREVIEW IT"
                color: page.picked.length > 0 ? Appearance.color.text : Appearance.color.textFaint
                font.family: page.picked.length > 0 ? page.picked : Appearance.font.mono
                font.pixelSize: page.picked.length > 0 ? page.look.preview : Appearance.font.label
                font.letterSpacing: page.picked.length > 0 ? 0 : Appearance.font.labelSpacing
            }
        }

        Row {
            spacing: Appearance.unit.small

            Piece {
                Action {
                    label: "APPLY"
                    isPrimary: true
                    isAvailable: page.canApply
                    onClicked: page.fontRequested(page.picked)
                }
            }

            Piece {
                Action {
                    label: "RESTORE"
                    isAvailable: SystemFont.isApplied
                    onClicked: page.fontRequested("")
                }
            }
        }
    }

    Section {
        title: "FAMILIES  " + SystemFont.families.length

        Piece {
            id: listPiece
            width: parent.width
            height: page.look.list
            isFlipping: false
            enterDuration: Motion.settings.listRun
            enterEasing: Easing.OutCubic

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: SystemFont.families

                Drift {}

                delegate: Item {
                    id: row

                    required property string modelData
                    required property int index
                    readonly property real arrival: Geometry.clampUnit(listPiece.presence * (1 + Motion.settings.listSpread) - Math.min(index, page.look.listReach) / page.look.listReach * Motion.settings.listSpread)
                    readonly property bool isPicked: page.picked === modelData
                    readonly property bool isApplied: page.applied === modelData

                    width: list.width
                    height: page.look.listRow
                    opacity: arrival
                    transform: Translate {
                        x: page.look.listSlide * (row.arrival - 1)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Appearance.color.wash
                        opacity: area.containsMouse || row.isPicked ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.pace(area.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    Text {
                        x: Appearance.settings.fieldPadding
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x * 2 - mark.width
                        elide: Text.ElideRight
                        text: row.modelData
                        color: row.isPicked || row.isApplied ? Appearance.color.accent : Appearance.color.textBody
                        font.family: row.modelData
                        font.pixelSize: Appearance.font.body
                    }

                    Text {
                        id: mark
                        anchors.right: parent.right
                        anchors.rightMargin: Appearance.settings.fieldPadding
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.isApplied ? "ON" : ""
                        color: Appearance.color.accent
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.chip
                        font.letterSpacing: Appearance.font.labelSpacing
                        font.bold: true
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.picked = row.modelData
                    }
                }
            }
        }
    }
}
