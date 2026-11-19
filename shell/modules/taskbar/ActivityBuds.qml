import QtQuick
import qs.config
import qs.components

Item {
    id: buds

    required property Item host
    required property Item pill
    property var items: []
    property int side: -1
    property bool isShown: false
    property string label: "activity buds"
    readonly property var look: Appearance.activity.bud
    readonly property real centerX: pill.expandedLeft + pill.expandedSize.width / 2
    readonly property real rowWidth: items.length * look.size + Math.max(0, items.length - 1) * look.spacing

    signal chosen(string key)

    Repeater {
        model: buds.items

        Item {
            id: bud
            required property var modelData
            required property int index
            property real share: buds.isShown ? 1 : 0
            readonly property real reach: buds.pill.bodyHeight / 2 + bud.share * (buds.look.gap + buds.look.size) - buds.look.size / 2
            readonly property real size: buds.look.size * Math.min(1, bud.share) * buds.pill.popScale
            readonly property real centerX: buds.centerX - buds.rowWidth / 2 + buds.look.size / 2 + bud.index * (buds.look.size + buds.look.spacing)

            x: bud.centerX - buds.look.size / 2
            y: buds.side * bud.reach - buds.look.size / 2
            width: buds.look.size
            height: buds.look.size
            visible: bud.size > 0.5

            Behavior on share {
                SequentialAnimation {
                    PauseAnimation {
                        duration: Motion.pace(buds.isShown ? bud.index * Motion.activity.budStagger : 0)
                    }
                    NumberAnimation {
                        duration: Motion.pace(buds.isShown ? Motion.activity.budEnter : Motion.activity.budLeave)
                        easing.type: buds.isShown ? Easing.OutBack : Easing.InQuad
                        easing.overshoot: Motion.activity.budOvershoot
                    }
                }
            }

            LiquidShape {
                parent: buds.host.liquidShapes
                visible: bud.visible
                width: bud.size
                height: bud.size
                x: buds.pill.x + bud.centerX - bud.size / 2
                y: buds.pill.y + buds.side * bud.reach - bud.size / 2
            }

            GlyphButton {
                anchors.centerIn: parent
                width: buds.look.size
                height: buds.look.size
                opacity: Math.max(0, Math.min(1, bud.share * 2 - 1))
                enabled: buds.isShown
                glyphSize: buds.look.glyph
                glyphName: bud.modelData.glyph
                isSelected: bud.modelData.isSelected ?? false
                isArmed: bud.modelData.isOff ?? false
                transform: Upright {
                    isMirrored: buds.host.isMirrored
                    axis: buds.look.size / 2
                }
                onClicked: buds.chosen(bud.modelData.key)
            }
        }
    }
}
