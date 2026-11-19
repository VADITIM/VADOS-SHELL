import QtQuick
import qs.config
import qs.components

Item {
    id: section

    property string title
    property string icon
    property bool hasRule: !isGroup
    property bool isGroup: false
    readonly property var look: Appearance.settings.section
    default property alias body: holder.data

    width: look.width
    height: holder.y + holder.height + (hasRule ? look.rowGap + look.rule : 0)

    Piece {
        role: "card"
        visible: section.hasRule
        y: section.height - height
        width: section.width
        height: section.look.rule

        Rectangle {
            width: section.width
            height: section.look.rule
            color: Appearance.color.hairline
            opacity: section.look.ruleShade
        }
    }

    Piece {
        role: "stripe"
        visible: holder.height > 0 && !section.isGroup
        x: -section.look.stripeGap - section.look.stripe
        y: holder.y
        width: section.look.stripe
        height: holder.height

        Rectangle {
            width: section.look.stripe
            height: holder.height
            radius: width / 2
            color: Appearance.color.accent
        }
    }

    Piece {
        id: heading
        role: "title"
        isFlipping: false
        width: titleRow.implicitWidth
        height: titleRow.implicitHeight

        Row {
            id: titleRow
            spacing: section.look.tickGap

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                visible: section.icon.length > 0
                width: section.look.titleIcon
                height: width
                name: section.icon
                color: Appearance.color.accent
                scale: heading.presence
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: section.icon.length === 0
                width: section.look.tick
                height: section.look.tickHeight
                radius: width / 2
                color: Appearance.color.accent
                scale: heading.presence
            }

            LabelReveal {
                width: titleText.implicitWidth
                height: titleText.implicitHeight
                label: "section title"
                isShown: heading.isShown && heading.presence > 0
                growDuration: Motion.settings.revealGrow
                retractDuration: Motion.settings.revealRetract
                leaveDuration: Motion.settings.revealLeave

                Text {
                    id: titleText
                    text: section.title
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: section.isGroup ? section.look.groupTitle : section.look.title
                    font.letterSpacing: section.look.titleSpacing
                    font.bold: true
                }
            }
        }
    }

    Column {
        id: holder
        y: heading.height + section.look.titleGap
        width: section.width
        spacing: section.look.rowGap
    }
}
