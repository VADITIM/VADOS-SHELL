import QtQuick
import qs.config
import qs.components

Item {
    id: editor

    property string name: ""
    property string secondName: ""
    property string picture: ""
    property string github: ""
    property real areaWidth: 0
    property real areaHeight: 0
    property bool isEditing: false
    property bool isLinkEditing: false
    readonly property bool isNameHovered: nameArea.containsMouse || secondArea.containsMouse
    readonly property var look: Appearance.settings
    readonly property var style: Appearance.settings.profile
    readonly property real historyWidth: Math.min(areaWidth, style.historyWidth)
    readonly property real historyX: (areaWidth - historyWidth) / 2
    readonly property real cell: Math.max(0, (historyWidth - style.boxPadding * 2 - (style.weeks - 1) * style.cellGap) / style.weeks)
    readonly property real gridY: style.boxPadding + historyTitle.implicitHeight + style.nameGap
    readonly property real historyHeight: gridY + style.days * cell + (style.days - 1) * style.cellGap + style.boxPadding
    readonly property real reserved: namePiece.height + style.lineGap + secondPiece.height + style.nameGap + style.sectionGap + linkPiece.height + style.nameGap + historyHeight
    readonly property real diameter: Math.max(0, Math.min(areaHeight * style.avatarShare, areaWidth * style.avatarWidthShare, areaHeight - reserved))
    readonly property real nameWidth: diameter + style.sectionGap
    readonly property real avatarY: secondPiece.y + secondPiece.height + style.nameGap
    readonly property real historyY: linkPiece.y + linkPiece.height + style.nameGap
    readonly property real blockHeight: historyY + historyHeight

    y: Math.max(0, (areaHeight - blockHeight) / 2)

    signal profileRequested(string field, string value)
    signal pictureRequested()

    function beginNames(input) {
        isEditing = true
        input.forceActiveFocus()
        input.selectAll()
    }

    function settleNames() {
        Qt.callLater(() => {
            if (!nameInput.activeFocus && !secondInput.activeFocus)
                editor.isEditing = false
        })
    }

    function finishEditing() {
        nameInput.focus = false
        secondInput.focus = false
        linkInput.focus = false
    }

    function leave(input, event) {
        input.focus = false
        event.accepted = true
    }

    width: areaWidth
    height: areaHeight

    MouseArea {
        anchors.fill: parent
        enabled: editor.isEditing || editor.isLinkEditing
        onClicked: editor.finishEditing()
    }

    Piece {
        x: (editor.areaWidth - editor.diameter) / 2
        y: editor.avatarY
        width: editor.diameter
        height: editor.diameter

        Item {
            id: avatar
            anchors.fill: parent

            Masked {
                anchors.fill: parent
                visible: portrait.status === Image.Ready
                mask: Squircle {
                    anchors.fill: parent
                    color: "black"
                }

                Image {
                    id: portrait
                    anchors.fill: parent
                    source: editor.picture
                    sourceSize.width: avatar.width * 2
                    sourceSize.height: avatar.height * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            Squircle {
                anchors.fill: parent
                color: Appearance.color.wash
                visible: portrait.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    text: (editor.name || "?").charAt(0).toUpperCase()
                    color: Appearance.color.textFaint
                    font.family: Appearance.font.mono
                    font.pixelSize: Math.round(editor.diameter * editor.style.initialShare)
                    font.bold: true
                }
            }

            Squircle {
                anchors.fill: parent
                color: Qt.alpha(Appearance.color.ground, editor.style.hoverShade)
                opacity: avatarArea.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(avatarArea.containsMouse ? Motion.hoverIn : Motion.hoverOut)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "CHANGE PICTURE"
                    color: Appearance.color.text
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.label
                    font.letterSpacing: Appearance.font.labelSpacing
                }
            }

            Squircle {
                anchors.fill: parent
                strokeWidth: editor.style.ring
                strokeColor: Appearance.color.text
            }

            Press {
                target: avatar
                isPressed: avatarArea.pressed
            }

            MouseArea {
                id: avatarArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: editor.pictureRequested()
            }
        }
    }

    Piece {
        id: namePiece
        x: (editor.areaWidth - width) / 2
        y: 0
        width: editor.nameWidth
        height: nameInput.implicitHeight + editor.style.underline

        Item {
            anchors.fill: parent

            TextInput {
                id: nameInput
                width: parent.width
                horizontalAlignment: TextInput.AlignHCenter
                clip: true
                readOnly: !editor.isEditing
                text: editor.name
                color: Appearance.color.text
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.mono
                font.pixelSize: editor.style.nameSize
                font.bold: true
                font.capitalization: Font.AllUppercase
                onTextEdited: editor.profileRequested("name", text)
                onActiveFocusChanged: if (!activeFocus) editor.settleNames()
                Keys.onReturnPressed: secondInput.forceActiveFocus()
                Keys.onEscapePressed: event => editor.leave(nameInput, event)

                Text {
                    width: nameInput.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: nameInput.text.length === 0
                    text: "USERNAME"
                    color: Appearance.color.textFaint
                    font: nameInput.font
                }
            }

            Rectangle {
                x: (parent.width - width) / 2
                y: parent.height - height
                width: editor.isEditing ? parent.width : Math.min(parent.width, nameInput.contentWidth)
                height: editor.style.underline
                radius: height / 2
                color: Appearance.color.accent
                opacity: nameInput.activeFocus ? 1 : editor.isNameHovered || editor.isEditing ? editor.style.hint : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Motion.pace(Motion.settings.slide)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: nameArea
                anchors.fill: parent
                enabled: !editor.isEditing
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: editor.beginNames(nameInput)
            }
        }
    }

    Piece {
        id: secondPiece
        x: namePiece.x
        y: namePiece.y + namePiece.height + editor.style.lineGap
        width: editor.nameWidth
        height: secondInput.implicitHeight + editor.style.underline

        Item {
            anchors.fill: parent

            TextInput {
                id: secondInput
                width: parent.width
                horizontalAlignment: TextInput.AlignHCenter
                clip: true
                readOnly: !editor.isEditing
                text: editor.secondName
                color: editor.isEditing ? Appearance.color.text : Appearance.color.textMuted
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.mono
                font.pixelSize: editor.style.secondSize
                onTextEdited: editor.profileRequested("secondName", text)
                onActiveFocusChanged: if (!activeFocus) editor.settleNames()
                Keys.onReturnPressed: secondInput.focus = false
                Keys.onEscapePressed: event => editor.leave(secondInput, event)

                TypedText {
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    x: (secondInput.width - width) / 2
                    target: "Last Name"
                    leaveBudget: Motion.settings.pageSwap
                    isShown: secondInput.text.length === 0 && editor.isEditing
                    color: Appearance.color.textFaint
                    font: secondInput.font
                }
            }

            Rectangle {
                x: (parent.width - width) / 2
                y: parent.height - height
                width: editor.isEditing ? parent.width : 0
                height: editor.style.underline
                radius: height / 2
                color: Appearance.color.accent
                opacity: secondInput.activeFocus ? 1 : editor.style.hint
                visible: width > 0

                Behavior on width {
                    NumberAnimation {
                        duration: Motion.pace(Motion.settings.slide)
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: secondArea
                anchors.fill: parent
                enabled: !editor.isEditing
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: editor.beginNames(secondInput)
            }
        }
    }

    Piece {
        id: linkPiece
        x: editor.historyX
        y: editor.avatarY + editor.diameter + editor.style.sectionGap
        width: editor.historyWidth
        height: linkInput.implicitHeight + editor.style.underline
        isFlipping: false

        LabelReveal {
            anchors.fill: parent
            label: "github name"
            isShown: linkPiece.isShown && linkPiece.presence > 0
            leaveDuration: Motion.settings.revealLeave
            growDuration: Motion.settings.revealGrow
            retractDuration: Motion.settings.revealRetract
            sweepWidth: Math.min(width, Math.max(linkInput.contentWidth, linkPlaceholder.implicitWidth))

            Text {
                id: linkPrefix
                opacity: editor.isLinkEditing ? 1 : 0
                text: "github.com/"
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: editor.style.linkSize

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }
            }

            TextInput {
                id: linkInput
                x: editor.isLinkEditing ? linkPrefix.width : 0
                width: linkPiece.width - x
                clip: true
                readOnly: !editor.isLinkEditing
                text: editor.github
                color: Appearance.color.text
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.mono
                font.pixelSize: editor.style.linkSize
                font.bold: true
                font.capitalization: editor.isLinkEditing ? Font.MixedCase : Font.AllUppercase
                onTextEdited: editor.profileRequested("github", text)
                onActiveFocusChanged: if (!activeFocus) editor.isLinkEditing = false
                Keys.onReturnPressed: linkInput.focus = false
                Keys.onEscapePressed: event => editor.leave(linkInput, event)

                Behavior on x {
                    NumberAnimation {
                        duration: Motion.pace(Motion.settings.slide)
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: linkPlaceholder
                    visible: linkInput.text.length === 0
                    text: editor.isLinkEditing ? "username" : "GITHUB"
                    color: Appearance.color.textFaint
                    font: linkInput.font
                }
            }

            Rectangle {
                y: linkPiece.height - height
                width: editor.isLinkEditing ? linkPiece.width : Math.min(linkPiece.width, linkInput.contentWidth)
                height: editor.style.underline
                radius: height / 2
                color: Appearance.color.accent
                opacity: linkInput.activeFocus ? 1 : linkArea.containsMouse ? editor.style.hint : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Motion.pace(Motion.settings.slide)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            id: linkArea
            anchors.fill: parent
            enabled: !editor.isLinkEditing
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
            onClicked: {
                editor.isLinkEditing = true
                linkInput.forceActiveFocus()
                linkInput.selectAll()
            }
        }
    }

    Piece {
        id: historyPiece
        x: editor.historyX
        y: editor.historyY
        width: editor.historyWidth
        height: editor.historyHeight
        isFlipping: false

        Item {
            anchors.fill: parent

            Outline {
                anchors.fill: parent
                label: "github history"
                radius: Appearance.radius.medium
                isShown: historyPiece.isShown && historyPiece.presence > 0
                traceDuration: Motion.settings.outlineTrace
                leaveDuration: Motion.settings.outlineLeave
            }

            TypedText {
                id: historyTitle
                characterInterval: Motion.type.quick
                untypeInterval: Motion.type.quickUntype
                x: editor.style.boxPadding
                y: editor.style.boxPadding
                target: "GITHUB HISTORY"
                leaveBudget: Motion.settings.pageSwap
                holdsWidth: true
                isShown: historyPiece.isShown && historyPiece.presence > 0
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }

            Repeater {
                model: editor.style.weeks * editor.style.days

                Turn {
                    required property int index
                    x: editor.style.boxPadding + Math.floor(index / editor.style.days) * (editor.cell + editor.style.cellGap)
                    y: editor.gridY + (index % editor.style.days) * (editor.cell + editor.style.cellGap)
                    width: editor.cell
                    height: editor.cell
                    isShown: historyPiece.isShown
                    enterDelay: historyPiece.enterDelay + Math.round(index * Motion.settings.spread / (editor.style.weeks * editor.style.days))
                    enterDuration: Motion.settings.cellEnter
                    leaveWindow: 0
                    leaveDuration: Motion.settings.cellLeave

                    Rectangle {
                        anchors.fill: parent
                        radius: editor.cell * editor.style.cellRound
                        color: Appearance.color.wash
                    }
                }
            }
        }
    }
}
