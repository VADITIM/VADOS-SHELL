import QtQuick
import qs.config
import qs.components
import qs.services
import "../../utils/Family.js" as Catalogue

Flow {
    id: page

    property bool isShown: false
    property string armedKey: ""
    readonly property var look: Appearance.settings.section

    spacing: look.columnGap

    onIsShownChanged: {
        Family.isWatching = isShown
        if (!isShown)
            armedKey = ""
    }

    function act(row) {
        if (!row.isInstalled) {
            Family.openReleases(row.key)
        } else if (armedKey === row.key) {
            Family.makeDefault(row.key)
            armedKey = ""
        } else {
            armedKey = row.key
        }
    }

    Repeater {
        model: Catalogue.apps

        Section {
            id: card

            required property var modelData
            readonly property var row: Family.rows.find(candidate => candidate.key === modelData.key) ?? { key: modelData.key, isInstalled: false, canBeDefault: false, isDefault: false, icon: "" }
            readonly property bool isArmed: page.armedKey === modelData.key
            readonly property bool hasAction: !row.isInstalled || (row.canBeDefault && !row.isDefault)

            title: modelData.label

            Item {
                width: parent.width
                height: page.look.icon

                Piece {
                    id: badge
                    width: page.look.icon
                    height: page.look.icon

                    Squircle {
                        anchors.fill: parent
                        color: Appearance.color.wash
                        visible: card.row.icon.length === 0
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: card.row.icon.length === 0
                        text: card.modelData.label.charAt(0)
                        color: card.row.isInstalled ? Appearance.color.text : Appearance.color.textFaint
                        font.family: Appearance.font.sans
                        font.pixelSize: Appearance.settings.heading
                        font.bold: true
                    }

                    Image {
                        anchors.fill: parent
                        visible: card.row.icon.length > 0
                        source: card.row.icon
                        sourceSize.width: page.look.icon
                        sourceSize.height: page.look.icon
                        fillMode: Image.PreserveAspectFit
                    }
                }

                Column {
                    x: page.look.icon + Appearance.unit.medium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.unit.small

                    Piece {
                        role: "label"

                        Text {
                            text: card.modelData.role
                            color: Appearance.color.textBody
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.label
                            font.letterSpacing: Appearance.font.labelSpacing
                        }
                    }

                    Piece {
                        role: "hint"

                        Text {
                            text: Catalogue.statusOf(card.row)
                            color: card.row.isDefault ? Appearance.color.accent : card.row.isInstalled ? Appearance.color.text : Appearance.color.textFaint
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.chip
                            font.letterSpacing: Appearance.font.labelSpacing
                            font.bold: true
                        }
                    }
                }

                Piece {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: card.hasAction

                    Action {
                        label: !card.row.isInstalled ? "GET IT" : card.isArmed ? "CONFIRM" : "MAKE DEFAULT"
                        isArmed: card.isArmed
                        isPrimary: card.row.isInstalled
                        onClicked: page.act(card.row)
                    }
                }
            }
        }
    }
}
