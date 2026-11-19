import QtQuick
import qs.config
import qs.components
import qs.services
import "../../utils/About.js" as About
import "../../utils/GitHub.js" as Hub

Item {
    id: editor

    property string name: ""
    property string secondName: ""
    property string picture: ""
    property string github: ""
    property real areaWidth: 0
    property real areaHeight: 0
    property bool isEditing: false
    property string editingField: ""
    property bool isLinkEditing: false
    readonly property var look: Appearance.settings
    readonly property var style: Appearance.settings.profile
    property int slideIndex: 0
    property bool isSwapping: false
    property var favorites: []
    property bool isPicking: false
    readonly property string slide: Hub.slides[slideIndex]
    readonly property var shownFavorites: GitHub.favorites.map(repository => repository.name)
    readonly property real contentHeight: historyHeight - gridY - style.boxPadding
    readonly property real cardWidth: (historyWidth - style.boxPadding * 2 - style.rowGap * (Hub.favoriteLimit - 1)) / Hub.favoriteLimit
    readonly property var cells: Hub.lastDays(GitHub.days, style.weeks * style.days)
    readonly property int highest: cells.reduce((most, day) => Math.max(most, day.count), 0)
    readonly property string notice: GitHub.status === "missing" ? "PRESS CONNECT OR TYPE YOUR GITHUB NAME" : GitHub.status === "failed" ? "GITHUB IS UNREACHABLE, RETRYING" : GitHub.status === "loading" && cells.length === 0 ? "CONNECTING" : ""
    readonly property real historyWidth: Math.min(areaWidth - (style.arrow + style.arrowGap) * 4, style.historyWidth)
    readonly property real historyRun: historyWidth + (style.arrowGap + style.arrow) * 2
    readonly property real widestValue: About.keys.reduce((widest, key) => {
        const value = (about[key] || "-").toUpperCase();
        return Math.max(widest, valueMetrics.advanceWidth(value) + Appearance.font.labelSpacing * value.length);
    }, 0)
    readonly property real blockWidth: Math.max(historyRun, diameter + style.sectionGap + style.infoLabel + widestValue)
    readonly property real blockX: Math.max(0, (areaWidth - blockWidth) / 2)
    readonly property real historyX: blockX + (blockWidth - historyWidth) / 2
    property int swapStep: 1
    readonly property real cell: Math.max(0, (historyWidth - style.boxPadding * 2 - (style.weeks - 1) * style.cellGap) / style.weeks)
    readonly property real gridY: style.boxPadding + historyTitle.implicitHeight + style.nameGap
    readonly property real historyHeight: gridY + style.days * cell + (style.days - 1) * style.cellGap + style.boxPadding
    readonly property real reserved: nameSlot + style.lineGap + secondSlot + style.nameGap + style.sectionGap + linkPiece.height + style.nameGap + historyHeight
    readonly property real diameter: Math.max(0, Math.min(areaHeight * style.avatarShare, areaWidth * style.avatarWidthShare, historyWidth - style.infoWidth - style.sectionGap, areaHeight - reserved))
    readonly property real avatarX: blockX
    readonly property real infoX: avatarX + diameter + style.sectionGap
    readonly property real infoWidth: Math.max(0, blockX + blockWidth - infoX)
    readonly property string banner: Banner.render(name.toUpperCase())
    readonly property real nameSlot: nameInput.implicitHeight + style.underline
    readonly property real secondSlot: secondInput.implicitHeight + style.underline
    readonly property real headBottom: avatarY - style.nameGap
    readonly property int bannerPixel: style.bannerSize
    readonly property real nameBannerHeight: banner.length > 0 ? nameBannerText.implicitHeight : 0
    readonly property real nameBlockWidth: banner.length > 0 ? nameBannerText.implicitWidth : style.fieldWidth
    readonly property real secondBlockWidth: Math.max(style.fieldWidth, secondInput.contentWidth)
    readonly property real nameBlockHeight: banner.length > 0 ? nameBannerHeight : nameSlot
    readonly property real bannerRowWidth: nameBlockWidth
    readonly property real rowX: (areaWidth - bannerRowWidth) / 2
    readonly property real secondTop: headBottom - secondSlot
    readonly property real nameTop: secondTop - style.lineGap - nameBlockHeight
    readonly property bool showsNameText: editingField === "name" || banner.length === 0 && editingField !== "second" || nameHover.hovered
    readonly property int uptimeMinutes: Machine.bootTime > 0 ? Math.floor((DateTime.now.getTime() - Machine.bootTime) / 60000) : -1
    readonly property var about: ({
            os: Machine.os,
            kernel: Machine.kernel,
            compositor: Compositor.label,
            shell: "VAD/OS SHELL " + Release.version,
            host: Machine.host,
            uptime: uptimeMinutes >= 0 ? About.uptimeOf(uptimeMinutes * 60) : "",
            cpu: Hardware.cpuName,
            gpu: Hardware.gpuName,
            memory: About.memoryOf(Hardware.memoryTotal)
        })
    readonly property real nameWidth: diameter + style.sectionGap
    readonly property real avatarY: nameSlot + style.lineGap + secondSlot + style.nameGap
    readonly property real historyY: linkPiece.y + linkPiece.height + style.nameGap
    readonly property real blockHeight: historyY + historyHeight

    y: Math.max(0, (areaHeight - blockHeight) / 2)

    signal profileRequested(string field, string value)

    signal pictureRequested()
    signal favoritesRequested(var names)

    function beginNames(input) {
        isEditing = true
        editingField = input === secondInput ? "second" : "name"
        input.forceActiveFocus()
        input.selectAll()
    }

    function settleNames() {
        Qt.callLater(() => {
            if (!nameInput.activeFocus && !secondInput.activeFocus) {
                editor.isEditing = false
                editor.editingField = ""
            }
        })
    }

    function finishEditing() {
        nameInput.focus = false
        secondInput.focus = false
        linkInput.focus = false
    }

    function advance(step) {
        if (isSwapping)
            return
        swapStep = step
        isSwapping = true
        swap.restart()
    }

    function leave(input, event) {
        input.focus = false
        event.accepted = true
    }

    width: areaWidth
    height: areaHeight

    FontMetrics {
        id: valueMetrics
        font.family: Appearance.font.sans
        font.pixelSize: editor.style.infoSize
    }

    Item {
        id: bannerField
        x: (editor.areaWidth - width) / 2
        y: editor.nameTop - (height - editor.nameBlockHeight) / 2
        width: editor.areaWidth * editor.style.sliceReach
        height: editor.areaHeight * editor.style.sliceReach
    }

    MouseArea {
        anchors.fill: parent
        enabled: editor.isEditing || editor.isLinkEditing
        onClicked: editor.finishEditing()
    }

    Timer {
        id: swap
        interval: Motion.pace(Motion.settings.pageSwap)
        onTriggered: {
            editor.slideIndex = Hub.stepIndex(editor.slideIndex, Hub.slides.length, editor.swapStep)
            editor.isPicking = false
            editor.isSwapping = false
        }
    }

    Column {
        x: editor.infoX
        y: editor.avatarY + Math.max(0, (editor.diameter - height) / 2)
        width: editor.infoWidth
        spacing: editor.style.infoGap

        Repeater {
            model: About.keys

            Piece {
                id: info

                required property string modelData

                isFlipping: false
                width: editor.infoWidth
                height: Math.max(infoLabel.implicitHeight, infoValue.implicitHeight)

                ScrambleText {
                    id: infoLabel
                    anchors.verticalCenter: parent.verticalCenter
                    label: "profile info label"
                    typeBudget: Motion.settings.infoType
                    target: About.labels[info.modelData]
                    isShown: info.isShown
                    color: Appearance.color.textMuted
                    family: Appearance.font.mono
                    pixelSize: editor.style.infoSize
                    isBold: false
                }

                Item {
                    x: editor.style.infoLabel
                    width: info.width - x
                    height: info.height

                    ScrambleText {
                        id: infoValue
                        anchors.verticalCenter: parent.verticalCenter
                        label: "profile info value"
                        typeBudget: Motion.settings.infoType
                        target: (editor.about[info.modelData] || "-").toUpperCase()
                        isShown: info.isShown
                        family: Appearance.font.sans
                        pixelSize: editor.style.infoSize
                        isBold: false
                    }
                }
            }
        }
    }

    Piece {
        id: avatarPiece
        x: editor.avatarX
        y: editor.avatarY
        isFlipping: false
        enterEasing: Easing.OutCubic
        enterDuration: Motion.settings.avatarPop
        width: editor.diameter
        height: editor.diameter

        Item {
            id: avatar
            anchors.fill: parent
            opacity: avatarPiece.presence
            transform: [
                Rotation {
                    origin.x: avatar.width / 2
                    origin.y: avatar.height / 2
                    angle: editor.style.avatarSpin * (1 - avatarPiece.presence)
                }
            ]

            Masked {
                anchors.fill: parent
                visible: portrait.status === Image.Ready
                mask: Rectangle {
                    anchors.fill: parent
                    radius: width / 2
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

            Rectangle {
                anchors.fill: parent
                radius: width / 2
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

            Rectangle {
                anchors.fill: parent
                radius: width / 2
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

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: editor.style.ring
                border.color: Appearance.color.accent
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
        isFlipping: false
        x: editor.rowX
        y: editor.nameTop
        width: editor.nameBlockWidth
        height: editor.nameBlockHeight

        Item {
            x: Math.min(0, (namePiece.width - width) / 2)
            y: editor.banner.length > 0 ? -editor.nameSlot - editor.style.lineGap : 0
            width: Math.max(namePiece.width, editor.style.fieldWidth)
            height: namePiece.height - y

            HoverHandler {
                id: nameHover
            }

            TextInput {
                id: nameInput
                width: parent.width
                opacity: editor.showsNameText ? 1 : 0
                enabled: editor.showsNameText
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
                Keys.onReturnPressed: editor.beginNames(secondInput)
                Keys.onTabPressed: event => {
                    event.accepted = true
                    editor.beginNames(secondInput)
                }
                Keys.onEscapePressed: event => editor.leave(nameInput, event)

                Text {
                    width: nameInput.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: nameInput.text.length === 0
                    text: "USERNAME"
                    color: Appearance.color.textFaint
                    font: nameInput.font
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }
            }

            Rectangle {
                x: (parent.width - width) / 2
                y: editor.nameSlot - height
                width: editor.editingField === "name" ? parent.width : Math.min(parent.width, nameInput.contentWidth)
                height: editor.style.underline
                radius: height / 2
                color: Appearance.color.accent
                opacity: nameInput.activeFocus ? 1 : editor.showsNameText ? editor.style.hint : 0
                visible: width > 0

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
                anchors.fill: parent
                enabled: editor.editingField !== "name"
                cursorShape: Qt.IBeamCursor
                onClicked: editor.beginNames(nameInput)
            }
        }

        SliceText {
            id: nameBannerText
            label: "profile name banner"
            width: implicitWidth
            height: implicitHeight
            look: editor.look.home.slice
            pace: Motion.settings.nameBanner
            character: Motion.liquid.snap
            hasSweep: true
            field: bannerField
            isShown: namePiece.isShown
            text: editor.banner
            color: Appearance.color.text
            fontFamily: Appearance.font.mono
            pixelSize: editor.bannerPixel
            lineHeight: editor.style.bannerLine
        }
    }

    Piece {
        id: secondPiece
        isFlipping: false
        x: (editor.areaWidth - width) / 2
        y: editor.secondTop
        width: editor.secondBlockWidth
        height: editor.secondSlot

        Item {
            width: secondPiece.width
            height: secondPiece.height - y

            TextInput {
                id: secondInput
                width: parent.width
                opacity: true ? 1 : 0
                enabled: true
                horizontalAlignment: TextInput.AlignHCenter
                clip: true
                readOnly: !editor.isEditing
                text: editor.secondName
                color: editor.editingField === "second" ? Appearance.color.text : Appearance.color.textMuted
                selectionColor: Appearance.color.accent
                selectedTextColor: Appearance.color.ground
                font.family: Appearance.font.sans
                font.pixelSize: editor.style.secondSize
                onTextEdited: editor.profileRequested("secondName", text)
                onActiveFocusChanged: if (!activeFocus) editor.settleNames()
                Keys.onReturnPressed: secondInput.focus = false
                Keys.onEscapePressed: event => editor.leave(secondInput, event)

                TypedText {
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    x: (secondInput.width - width) / 2
                    target: "Second Name"
                    leaveBudget: Motion.settings.pageSwap
                    isShown: secondInput.text.length === 0 && editor.editingField === "second"
                    color: Appearance.color.textFaint
                    font: secondInput.font
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.pace(Motion.stateDuration)
                    }
                }
            }

            Rectangle {
                x: (parent.width - width) / 2
                y: editor.secondSlot - height
                width: editor.editingField === "second" ? parent.width : Math.min(parent.width, secondInput.contentWidth)
                height: editor.style.underline
                radius: height / 2
                color: Appearance.color.accent
                opacity: secondInput.activeFocus ? 1 : editor.style.hint
                visible: width > 0

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
                anchors.fill: parent
                enabled: editor.editingField !== "second"
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
                    text: editor.isLinkEditing ? "username" : GitHub.detected.length > 0 ? GitHub.detected.toUpperCase() : "GITHUB"
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
        id: connectPiece
        x: editor.historyX + editor.historyWidth - width
        y: linkPiece.y + linkPiece.height - height
        width: connectLabel.implicitWidth
        height: connectLabel.implicitHeight

        Text {
            id: connectLabel
            text: GitHub.isConnecting ? "CONNECTING" : GitHub.isSignedIn ? "CONNECTED" : "CONNECT"
            color: connectArea.containsMouse || GitHub.isConnecting ? Appearance.color.accent : Appearance.color.textFaint
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.label
            font.letterSpacing: Appearance.font.labelSpacing

            MouseArea {
                id: connectArea
                anchors.fill: parent
                anchors.margins: -editor.style.rowGap
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: GitHub.connect()
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
                target: Hub.titles[editor.slide]
                leaveBudget: Motion.settings.pageSwap
                holdsWidth: true
                isShown: historyPiece.isShown && historyPiece.presence > 0
                color: Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }

            Text {
                id: pickToggle
                x: parent.width - editor.style.boxPadding - width
                y: editor.style.boxPadding
                visible: editor.slide === "favorites" && GitHub.repositories.length > 0
                text: editor.isPicking ? "DONE" : "EDIT"
                color: pickArea.containsMouse || editor.isPicking ? Appearance.color.accent : Appearance.color.textFaint
                font.family: Appearance.font.mono
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing

                MouseArea {
                    id: pickArea
                    anchors.fill: parent
                    anchors.margins: -editor.style.rowGap
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editor.isPicking = !editor.isPicking
                }
            }

            Repeater {
                model: editor.style.weeks * editor.style.days

                Turn {
                    id: cellTurn

                    required property int index
                    readonly property var day: editor.cells[index - (editor.style.weeks * editor.style.days - editor.cells.length)] ?? null
                    readonly property int level: day ? Hub.levelOf(day.count, editor.highest) : 0

                    x: editor.style.boxPadding + Math.floor(index / editor.style.days) * (editor.cell + editor.style.cellGap)
                    y: editor.gridY + (index % editor.style.days) * (editor.cell + editor.style.cellGap)
                    width: editor.cell
                    height: editor.cell
                    isShown: historyPiece.isShown && editor.slide === "history" && !editor.isSwapping
                    enterDelay: historyPiece.enterDelay + Math.round(index * Motion.settings.spread / (editor.style.weeks * editor.style.days))
                    enterDuration: Motion.settings.cellEnter
                    leaveWindow: 0
                    leaveDuration: Motion.settings.cellLeave

                    Rectangle {
                        anchors.fill: parent
                        radius: editor.cell * editor.style.cellRound
                        color: cellTurn.level > 0 ? Qt.alpha(Appearance.color.accent, editor.style.cellFloor + cellTurn.level * editor.style.cellStep) : Appearance.color.wash

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.pace(Motion.stateDuration)
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: editor.gridY + (editor.historyHeight - editor.gridY - editor.style.boxPadding - height) / 2
                visible: editor.notice.length > 0 && (editor.slide === "history" || GitHub.status !== "ready")
                text: editor.notice
                color: Appearance.color.textMuted
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.label
                font.letterSpacing: Appearance.font.labelSpacing
            }

            Row {
                x: editor.style.boxPadding
                y: editor.gridY
                spacing: editor.style.rowGap
                visible: editor.slide === "favorites" && !editor.isPicking

                Repeater {
                    model: editor.slide === "favorites" && !editor.isPicking ? GitHub.favorites : []

                    RepositoryCard {
                        required property var modelData
                        required property int index

                        width: editor.cardWidth
                        height: editor.contentHeight
                        style: editor.style
                        label: (modelData.language || "REPOSITORY").toUpperCase()
                        corner: modelData.stars > 0 ? "★ " + modelData.stars : ""
                        title: Hub.shortName(modelData.name)
                        detail: modelData.description
                        stamp: Hub.ageOf(modelData.date, DateTime.now.getTime())
                        isShown: historyPiece.isShown && !editor.isSwapping
                        enterDelay: index * Motion.settings.stagger
                        onOpened: GitHub.open(modelData.url)
                    }
                }
            }

            Flickable {
                id: picker
                x: editor.style.boxPadding
                y: editor.gridY
                width: editor.historyWidth - editor.style.boxPadding * 2
                height: editor.contentHeight
                visible: editor.slide === "favorites" && editor.isPicking
                clip: true
                contentWidth: pickerFlow.width
                flickableDirection: Flickable.HorizontalFlick

                Drift {
                    isHorizontal: true
                }

                Grid {
                    id: pickerFlow
                    flow: Grid.TopToBottom
                    rows: editor.style.pickRows
                    rowSpacing: editor.style.rowGap
                    columnSpacing: editor.style.rowGap

                    Repeater {
                        model: editor.isPicking ? GitHub.repositories : []

                        Item {
                            id: chip

                            required property var modelData
                            readonly property bool isChosen: editor.shownFavorites.indexOf(modelData.name) >= 0

                            width: editor.cardWidth
                            height: (editor.contentHeight - editor.style.rowGap * (editor.style.pickRows - 1)) / editor.style.pickRows

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: chipArea.containsMouse ? Appearance.color.raised : "transparent"
                                border.width: editor.style.underline
                                border.color: chip.isChosen ? Appearance.color.accent : Appearance.color.wash
                            }

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - editor.style.rowPadding * 2
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: Hub.shortName(chip.modelData.name)
                                color: chip.isChosen ? Appearance.color.text : Appearance.color.textMuted
                                font.family: Appearance.font.sans
                                font.pixelSize: Appearance.font.label
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: editor.favoritesRequested(Hub.toggled(editor.shownFavorites, chip.modelData.name))
                            }
                        }
                    }
                }
            }

            Flickable {
                id: pushStrip
                x: editor.style.boxPadding
                y: editor.gridY
                width: editor.historyWidth - editor.style.boxPadding * 2
                height: editor.contentHeight
                visible: editor.slide === "pushes"
                clip: true
                contentWidth: pushRow.width
                flickableDirection: Flickable.HorizontalFlick

                Drift {
                    isHorizontal: true
                }

                Row {
                    id: pushRow
                    spacing: editor.style.rowGap

                    Repeater {
                        model: editor.slide === "pushes" ? GitHub.pushes : []

                        RepositoryCard {
                            required property var modelData
                            required property int index

                            width: editor.cardWidth
                            height: editor.contentHeight
                            style: editor.style
                            label: Hub.shortName(modelData.repository).toUpperCase()
                            corner: Hub.ageOf(modelData.date, DateTime.now.getTime())
                            title: modelData.title
                            detail: ""
                            stamp: ""
                            isShown: historyPiece.isShown && !editor.isSwapping
                            enterDelay: Math.min(index, Hub.favoriteLimit) * Motion.settings.stagger
                            onOpened: GitHub.open(modelData.url)
                        }
                    }
                }
            }
        }
    }

    Piece {
        id: forwardPiece
        x: editor.historyX + editor.historyWidth + editor.style.arrowGap
        y: editor.historyY + (editor.historyHeight - height) / 2
        width: editor.style.arrow
        height: editor.style.arrow

        Item {
            id: forwardFace
            anchors.fill: parent

            Squircle {
                anchors.fill: parent
                corner: editor.style.arrowCorner
                color: Qt.alpha(Appearance.color.textMuted, forwardArea.containsMouse ? editor.style.arrowWash * 2 : editor.style.arrowWash)
            }

            Glyph {
                id: forwardGlyph
                anchors.centerIn: parent
                width: editor.style.arrowGlyph
                height: editor.style.arrowGlyph
                name: "arrow-right"
                color: Appearance.color.accent
                transform: Translate {
                    id: forwardShift
                }
            }

            SequentialAnimation {
                id: forwardNudge
                paused: Motion.isHeld && running

                NumberAnimation {
                    target: forwardShift
                    property: "x"
                    to: editor.style.arrowNudge
                    duration: Motion.pace(Motion.press.down)
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: forwardShift
                    property: "x"
                    to: 0
                    duration: Motion.pace(Motion.stateDuration)
                    easing.type: Easing.OutBack
                }
            }

            Press {
                target: forwardFace
                isPressed: forwardArea.pressed
                isRaised: forwardArea.containsMouse
            }

            MouseArea {
                id: forwardArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    forwardNudge.restart()
                    editor.advance(1)
                }
            }
        }
    }

    Piece {
        id: backPiece
        x: editor.historyX - editor.style.arrowGap - width
        y: editor.historyY + (editor.historyHeight - height) / 2
        width: editor.style.arrow
        height: editor.style.arrow

        Item {
            id: backFace
            anchors.fill: parent

            Squircle {
                anchors.fill: parent
                corner: editor.style.arrowCorner
                color: Qt.alpha(Appearance.color.textMuted, backArea.containsMouse ? editor.style.arrowWash * 2 : editor.style.arrowWash)
            }

            Glyph {
                id: backGlyph
                anchors.centerIn: parent
                width: editor.style.arrowGlyph
                height: editor.style.arrowGlyph
                name: "arrow-right"
                rotation: 180
                color: Appearance.color.accent
                transform: Translate {
                    id: backShift
                }
            }

            SequentialAnimation {
                id: backNudge
                paused: Motion.isHeld && running

                NumberAnimation {
                    target: backShift
                    property: "x"
                    to: editor.style.arrowNudge
                    duration: Motion.pace(Motion.press.down)
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: backShift
                    property: "x"
                    to: 0
                    duration: Motion.pace(Motion.stateDuration)
                    easing.type: Easing.OutBack
                }
            }

            Press {
                target: backFace
                isPressed: backArea.pressed
                isRaised: backArea.containsMouse
            }

            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    backNudge.restart()
                    editor.advance(-1)
                }
            }
        }
    }
}
