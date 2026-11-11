import QtQuick
import qs.config
import qs.components

Item {
    id: editor

    property string name: ""
    property string secondName: ""
    property string picture: ""
    property string github: ""
    property color accent: Appearance.color.accent
    property real areaWidth: 0
    property real areaHeight: 0
    property bool isEditing: false
    property bool isLinkEditing: false
    property bool isWheelOpen: false
    property bool isHexTyped: false
    property bool isNameTyped: true
    readonly property bool isNameHovered: nameArea.containsMouse || secondArea.containsMouse
    readonly property var look: Appearance.settings
    readonly property var style: Appearance.settings.profile
    readonly property real diameter: Math.min(areaHeight * style.avatarShare, areaWidth * style.avatarWidthShare)
    readonly property real nameWidth: diameter + style.sectionGap
    readonly property real sideX: diameter + style.sectionGap * 2
    readonly property real sideWidth: Math.max(0, areaWidth - sideX)
    readonly property real wheelBlock: diameter + look.gap + look.knob
    readonly property real cell: Math.max(0, (sideWidth - style.boxPadding * 2 - (style.weeks - 1) * style.cellGap) / style.weeks)
    readonly property real gridY: style.boxPadding + historyTitle.implicitHeight + style.nameGap
    readonly property real avatarY: look.swatch + style.nameGap
    readonly property real historyY: linkPiece.y + linkPiece.height + style.nameGap
    readonly property real historyHeight: gridY + style.days * cell + (style.days - 1) * style.cellGap + style.boxPadding
    readonly property real blockHeight: Math.max(secondPiece.y + secondPiece.height, historyY + historyHeight)

    y: Math.max(0, (areaHeight - blockHeight) / 2)
    onIsWheelOpenChanged: if (isWheelOpen) isNameTyped = false

    signal profileRequested(string field, string value)
    signal pictureRequested()
    signal accentRequested(color value)

    function hexOf(source) {
        return source.toString().toUpperCase()
    }

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
        hexInput.focus = false
    }

    function leave(input, event) {
        input.focus = false
        event.accepted = true
    }

    width: areaWidth
    height: areaHeight

    MouseArea {
        anchors.fill: parent
        enabled: editor.isEditing || editor.isLinkEditing || hexInput.activeFocus
        onClicked: editor.finishEditing()
    }

    Piece {
        x: 0
        y: editor.avatarY
        width: editor.diameter
        height: editor.diameter

        Item {
            id: avatar
            anchors.fill: parent
            opacity: 1 - accentWheel.wheelShare
            enabled: !editor.isWheelOpen

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
        x: (editor.diameter - width) / 2
        y: editor.avatarY + editor.diameter + editor.style.nameGap
        width: editor.nameWidth
        height: nameInput.implicitHeight + editor.style.underline

        Item {
            anchors.fill: parent

            TextInput {
                id: nameInput
                width: parent.width
                visible: editor.isNameTyped
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

            TypedText {
                id: nameTyper
                x: (parent.width - width) / 2
                visible: !editor.isNameTyped
                target: nameInput.text.length > 0 ? nameInput.text.toUpperCase() : "USERNAME"
                isShown: !editor.isWheelOpen && accentWheel.wheelShare <= 0
                color: nameInput.text.length > 0 ? Appearance.color.text : Appearance.color.textFaint
                font: nameInput.font
                onShownChanged: if (isShown && shown === target) editor.isNameTyped = true
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
                enabled: !editor.isEditing && !editor.isWheelOpen
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
        x: editor.sideX
        y: editor.avatarY
        width: editor.sideWidth
        height: linkInput.implicitHeight + editor.style.underline
        isFlipping: false

        LabelReveal {
            anchors.fill: parent
            label: "github name"
            isShown: linkPiece.isShown && linkPiece.presence > 0
            leaveDuration: Motion.settings.revealLeave
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
        x: editor.sideX
        y: editor.historyY
        width: editor.sideWidth
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
                    enterDelay: historyPiece.enterDelay + index * Motion.settings.cellCascade
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

    Piece {
        x: 0
        y: 0
        width: editor.look.swatch
        height: editor.look.swatch

        Rectangle {
            id: swatch
            width: editor.look.swatch
            height: editor.look.swatch
            radius: Appearance.radius.medium
            color: editor.accent
            border.width: editor.isWheelOpen ? editor.style.underline : 1
            border.color: editor.isWheelOpen ? Appearance.color.text : Appearance.color.hairline

            Press {
                target: swatch
                isPressed: swatchArea.pressed
            }

            MouseArea {
                id: swatchArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: editor.isWheelOpen = !editor.isWheelOpen
            }
        }
    }

    Piece {
        id: fieldPiece
        readonly property bool isFieldShown: isShown && presence > 0
        x: editor.look.swatch + editor.style.lineGap * 2
        y: 0
        width: editor.look.fieldWidth
        height: editor.look.swatch
        isFlipping: false
        onIsShownChanged: if (!isShown) editor.isHexTyped = false

        Item {
            id: fieldWipe
            width: fieldPiece.isFieldShown ? fieldPiece.width : 0
            height: fieldPiece.height
            opacity: fieldPiece.isFieldShown ? 1 : 0
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: Motion.pace(fieldPiece.isFieldShown ? Motion.settings.wipe : Motion.settings.wipeLeave)
                    easing.type: fieldPiece.isFieldShown ? Easing.OutCubic : Easing.InCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.pace(fieldPiece.isFieldShown ? Motion.settings.wipe : Motion.settings.wipeLeave)
                }
            }

            Rectangle {
                width: fieldPiece.width
                height: fieldPiece.height
                radius: height / 2
                color: Appearance.color.wash
                border.width: 1
                border.color: hexInput.activeFocus ? Appearance.color.accent : "transparent"

                TypedText {
                    anchors.verticalCenter: parent.verticalCenter
                    x: editor.look.fieldPadding
                    visible: !editor.isHexTyped
                    target: editor.hexOf(editor.accent)
                    leaveBudget: Motion.settings.pageSwap
                    isShown: fieldPiece.isFieldShown && fieldWipe.width >= fieldPiece.width - 0.5
                    color: Appearance.color.text
                    font: hexInput.font
                    onShownChanged: if (isShown && shown === target) editor.isHexTyped = true
                }

                TextInput {
                    id: hexInput
                    anchors.verticalCenter: parent.verticalCenter
                    x: editor.look.fieldPadding
                    width: parent.width - x * 2
                    visible: editor.isHexTyped
                    maximumLength: 7
                    text: editor.hexOf(editor.accent)
                    color: Appearance.color.text
                    selectionColor: Appearance.color.accent
                    selectedTextColor: Appearance.color.ground
                    font.family: Appearance.font.mono
                    font.pixelSize: editor.look.hexText
                    font.capitalization: Font.AllUppercase
                    onTextEdited: {
                        const candidate = (text.trim().startsWith("#") ? "" : "#") + text.trim()
                        if (/^#[0-9a-fA-F]{6}$/.test(candidate))
                            editor.accentRequested(Qt.color(candidate))
                    }
                    onEditingFinished: text = editor.hexOf(editor.accent)
                    Keys.onEscapePressed: event => editor.leave(hexInput, event)
                }
            }
        }
    }

    Piece {
        x: 0
        y: editor.avatarY
        width: editor.diameter
        height: editor.wheelBlock

        ColorWheel {
            id: accentWheel
            look: editor.look
            diameter: editor.diameter
            wheelShare: editor.isWheelOpen ? 1 : 0
            sliderShare: editor.isWheelOpen && nameTyper.shown.length === 0 ? 1 : 0
            color: editor.accent
            visible: wheelShare > 0
            enabled: editor.isWheelOpen
            onPicked: value => editor.accentRequested(value)

            Behavior on wheelShare {
                NumberAnimation {
                    duration: Motion.pace(Motion.settings.wheelPop)
                    easing.type: editor.isWheelOpen ? Easing.OutBack : Easing.InBack
                }
            }

            Behavior on sliderShare {
                NumberAnimation {
                    duration: Motion.pace(editor.isWheelOpen ? Motion.settings.wipe : Motion.settings.wipeLeave)
                    easing.type: editor.isWheelOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
        }
    }
}
