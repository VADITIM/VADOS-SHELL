import QtQuick
import qs.config
import qs.components
import "../../utils/Alerts.js" as Sources
import "../../utils/Geometry.js" as Geometry

Item {
    id: alerts

    required property bool isMirrored
    property var peek: null
    property rect body: Qt.rect(0, 0, 0, 0)
    property bool isBodyShown: false
    property var heldPeek: null
    property real slide: 0
    property bool isFollowing: false
    property bool isResetting: false

    readonly property bool isPeeking: peek !== null
    readonly property var lead: Sources.leadOf(heldPeek?.notifications ?? [])
    readonly property var source: Sources.identify(lead?.appName, lead?.desktopEntry)
    readonly property color tint: source.tint.length > 0 ? source.tint : Appearance.color.accent
    readonly property int count: heldPeek?.notifications?.length ?? 0
    readonly property bool isContentShown: isPeeking && isBodyShown
    readonly property bool isExpanded: hover.hovered && isContentShown
    readonly property string labelText: count > 1 ? source.label + "  +" + (count - 1) : source.label
    readonly property string fullTitle: Sources.plainOf(lead?.summary)
    readonly property string fullMessage: Sources.plainOf(lead?.body)
    readonly property string imageSource: lead?.image ?? ""
    readonly property bool hasImage: picture.status === Image.Ready && picture.implicitWidth > 0
    readonly property real textLeft: Appearance.alerts.padding + Appearance.alerts.badge + Appearance.alerts.gap
    readonly property real textRoom: textLeft + Appearance.alerts.padding
    readonly property real sideRoom: Appearance.alerts.padding * 2
    readonly property bool hasMessage: fullMessage.length > 0
    readonly property real naturalWidth: Math.max(textRoom + Math.max(labelOpen.implicitWidth, titleOpen.implicitWidth), sideRoom + messageNatural.implicitWidth)
    readonly property real expandedWidth: hasImage ? Appearance.alerts.expandedWidth : Math.min(Appearance.alerts.expandedWidth, Math.max(Appearance.alerts.width, Math.ceil(naturalWidth)))
    readonly property real headerWidth: expandedWidth - textRoom
    readonly property real fullWidth: expandedWidth - sideRoom
    readonly property real imageHeight: hasImage ? Math.min(Appearance.alerts.imageHeight, fullWidth * picture.implicitHeight / picture.implicitWidth) : 0
    readonly property real restHeaderHeight: labelMeasure.implicitHeight + Appearance.alerts.lineGap + titleNatural.implicitHeight
    readonly property real restColumnHeight: restHeaderHeight + (hasMessage ? Appearance.alerts.lineGap + messageNatural.implicitHeight : 0)
    readonly property real openHeaderHeight: labelOpen.implicitHeight + Appearance.alerts.lineGap + titleWrapped.implicitHeight
    readonly property real badgeTop: (Appearance.alerts.height - Appearance.alerts.badge) / 2
    readonly property real columnTop: Math.max(0, (Appearance.alerts.height - restColumnHeight) / 2)
    readonly property real headerBottom: Math.max(badgeTop + Appearance.alerts.badge, columnTop + openHeaderHeight)
    readonly property real messageTop: headerBottom + Appearance.alerts.sectionGap
    readonly property real textBottom: hasMessage ? messageTop + messageWrapped.implicitHeight : headerBottom
    readonly property real imageTop: textBottom + Appearance.alerts.imageGap
    readonly property real expandedHeight: Math.max(Appearance.alerts.height, Math.ceil((hasImage ? imageTop + imageHeight : textBottom) + Appearance.alerts.padding))
    readonly property size bodySize: isExpanded ? Qt.size(expandedWidth, expandedHeight) : Qt.size(Appearance.alerts.width, Appearance.alerts.height)
    readonly property real textWidth: Math.max(0, (isExpanded ? expandedWidth : body.width) - textRoom)
    readonly property real messageWidth: Math.max(0, isExpanded ? fullWidth : textWidth)

    signal dismissRequested()
    signal openRequested(var notification)
    signal holdRequested(bool isOn)

    transform: Upright {
        isMirrored: alerts.isMirrored
        axis: alerts.width / 2
    }

    onIsExpandedChanged: holdRequested(isExpanded)

    onPeekChanged: {
        if (!peek)
            return
        if (heldPeek === null || !isContentShown) {
            isResetting = true
            slide = 0
            isResetting = false
        }
        heldPeek = peek
    }

    Behavior on slide {
        enabled: !alerts.isFollowing && !alerts.isResetting

        NumberAnimation {
            duration: Motion.pace(Motion.alerts.settle)
            easing.type: Easing.OutCubic
        }
    }

    Text {
        id: labelMeasure
        visible: false
        text: alerts.labelText
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
        font.capitalization: Font.AllUppercase
    }

    Text {
        id: labelOpen
        visible: false
        text: alerts.labelText
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.alerts.openLabel
        font.letterSpacing: Appearance.font.labelSpacing
        font.capitalization: Font.AllUppercase
    }

    Text {
        id: titleNatural
        visible: false
        text: alerts.fullTitle
        textFormat: Text.PlainText
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.body
        font.bold: true
    }

    Text {
        id: titleOpen
        visible: false
        text: alerts.fullTitle
        textFormat: Text.PlainText
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.alerts.openTitle
        font.bold: true
    }

    Text {
        id: titleWrapped
        visible: false
        width: alerts.headerWidth
        text: alerts.fullTitle.length > 0 ? alerts.fullTitle : " "
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: Appearance.alerts.titleLines
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.alerts.openTitle
        font.bold: true
    }

    Text {
        id: messageNatural
        visible: false
        text: alerts.fullMessage
        textFormat: Text.PlainText
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.body
    }

    Text {
        id: messageWrapped
        visible: false
        width: alerts.fullWidth
        text: alerts.hasMessage ? alerts.fullMessage : " "
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: Appearance.alerts.bodyLines
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.body
    }

    Item {
        id: content
        x: alerts.body.x
        y: alerts.body.y
        width: alerts.body.width
        height: alerts.body.height
        visible: alerts.heldPeek !== null && width > 1
        clip: true
        transform: Upright {
            isMirrored: alerts.isMirrored
            axis: content.width / 2
        }

        HoverHandler {
            id: hover
            enabled: alerts.isContentShown
        }

        Item {
            id: face
            x: alerts.slide
            width: content.width
            height: content.height
            opacity: 1 - Math.min(1, Math.abs(alerts.slide) / Math.max(1, content.width))

            Turn {
                x: alerts.isMirrored ? face.width - Appearance.alerts.padding - Appearance.alerts.badge : Appearance.alerts.padding
                y: Math.min(alerts.badgeTop, (face.height - Appearance.alerts.badge) / 2)
                width: Appearance.alerts.badge
                height: Appearance.alerts.badge
                isShown: alerts.isContentShown
                enterDuration: Motion.alerts.faceEnter
                leaveDuration: Motion.alerts.faceLeave
                leaveWindow: 0

                Rectangle {
                    width: Appearance.alerts.badge
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: alerts.tint
                    border.width: Appearance.alerts.ring

                    Glyph {
                        anchors.centerIn: parent
                        width: Appearance.alerts.glyph
                        height: width
                        name: alerts.source.glyph
                        color: alerts.tint
                    }
                }
            }

            Column {
                id: column
                x: alerts.isMirrored ? Appearance.alerts.padding : alerts.textLeft
                y: Math.min(alerts.columnTop, (face.height - alerts.restColumnHeight) / 2)
                width: alerts.textWidth
                spacing: Appearance.alerts.lineGap

                Turn {
                    width: alerts.textWidth
                    height: label.height
                    isShown: alerts.isContentShown
                    enterDuration: Motion.alerts.faceEnter
                    leaveDuration: Motion.alerts.faceLeave
                    leaveWindow: 0

                    Text {
                        id: label
                        width: alerts.textWidth
                        horizontalAlignment: alerts.isMirrored ? Text.AlignRight : Text.AlignLeft
                        text: alerts.labelText
                        color: alerts.tint
                        elide: Text.ElideRight
                        font.family: Appearance.font.mono
                        font.pixelSize: alerts.isExpanded ? Appearance.alerts.openLabel : Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                        font.capitalization: Font.AllUppercase

                        Behavior on font.pixelSize {
                            NumberAnimation {
                                duration: Motion.pace(Motion.alerts.settle)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Turn {
                    width: alerts.textWidth
                    height: title.height
                    isShown: alerts.isContentShown
                    enterDuration: Motion.alerts.faceEnter
                    enterDelay: Motion.alerts.stagger
                    leaveDuration: Motion.alerts.faceLeave
                    leaveWindow: 0

                    Behavior on height {
                        NumberAnimation {
                            duration: Motion.pace(Motion.alerts.settle)
                            easing.type: Easing.OutCubic
                        }
                    }

                    TypedText {
                        id: title
                        width: alerts.textWidth
                        height: implicitHeight
                        horizontalAlignment: alerts.isMirrored ? Text.AlignRight : Text.AlignLeft
                        target: alerts.isExpanded ? alerts.fullTitle : Sources.clip(alerts.lead?.summary, Appearance.alerts.titleCharacters)
                        isShown: alerts.isContentShown
                        characterInterval: Motion.type.quick
                        untypeInterval: Motion.type.quickUntype
                        leaveBudget: Motion.alerts.faceLeave
                        typeBudget: alerts.isExpanded ? Motion.alerts.typeBudget : 0
                        wrapMode: Text.Wrap
                        maximumLineCount: alerts.isExpanded || shown !== target ? Appearance.alerts.titleLines : 1
                        elide: Text.ElideRight
                        color: Appearance.color.text
                        font.family: Appearance.font.mono
                        font.pixelSize: alerts.isExpanded ? Appearance.alerts.openTitle : Appearance.font.body
                        font.bold: true

                        Behavior on font.pixelSize {
                            NumberAnimation {
                                duration: Motion.pace(Motion.alerts.settle)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Turn {
                x: alerts.isExpanded || alerts.isMirrored ? Appearance.alerts.padding : alerts.textLeft
                y: alerts.isExpanded ? alerts.messageTop : column.y + alerts.restHeaderHeight + Appearance.alerts.lineGap
                width: alerts.messageWidth
                height: message.height
                visible: message.target.length > 0
                isShown: alerts.isContentShown
                enterDuration: Motion.alerts.faceEnter
                enterDelay: Motion.alerts.stagger * 2
                leaveDuration: Motion.alerts.faceLeave
                leaveWindow: 0

                Behavior on x {
                    NumberAnimation {
                        duration: Motion.pace(Motion.alerts.settle)
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Motion.pace(Motion.alerts.settle)
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Motion.pace(Motion.alerts.settle)
                        easing.type: Easing.OutCubic
                    }
                }

                TypedText {
                    id: message
                    width: alerts.messageWidth
                    height: implicitHeight
                    horizontalAlignment: alerts.isMirrored ? Text.AlignRight : Text.AlignLeft
                    target: alerts.isExpanded ? alerts.fullMessage : Sources.clip(alerts.lead?.body, Appearance.alerts.bodyCharacters)
                    isShown: alerts.isContentShown
                    characterInterval: Motion.type.quick
                    untypeInterval: Motion.type.quickUntype
                    leaveBudget: Motion.alerts.faceLeave
                    typeBudget: alerts.isExpanded ? Motion.alerts.typeBudget : 0
                    wrapMode: Text.Wrap
                    maximumLineCount: alerts.isExpanded || shown !== target ? Appearance.alerts.bodyLines : 1
                    elide: Text.ElideRight
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.mono
                    font.pixelSize: Appearance.font.body
                }
            }

            Item {
                id: photo
                readonly property real shortSide: Math.min(width, height)
                property real bloom: isShown ? 1 : 0
                property real corner: isShown && bloom >= 1 ? 1 : 0
                readonly property bool isShown: alerts.isExpanded && alerts.hasImage
                x: Appearance.alerts.padding
                y: alerts.imageTop
                width: alerts.fullWidth
                height: alerts.imageHeight
                visible: bloom > 0
                scale: bloom

                Behavior on bloom {
                    NumberAnimation {
                        duration: Motion.pace(photo.isShown ? Motion.alerts.imagePop : Motion.alerts.imageLeave)
                        easing.type: photo.isShown ? Easing.OutBack : Easing.InCubic
                        easing.overshoot: Motion.alerts.imageOvershoot
                    }
                }

                Behavior on corner {
                    NumberAnimation {
                        duration: Motion.pace(photo.isShown ? Motion.alerts.imageCorner : Motion.alerts.imageLeave)
                        easing.type: Easing.OutCubic
                    }
                }

                Masked {
                    anchors.fill: parent
                    mask: Rectangle {
                        x: (photo.width - width) / 2
                        y: (photo.height - height) / 2
                        width: Geometry.mix(photo.shortSide, photo.width, photo.corner)
                        height: Geometry.mix(photo.shortSide, photo.height, photo.corner)
                        radius: Geometry.mix(photo.shortSide / 2, Appearance.alerts.imageRadius, photo.corner)
                    }

                    Image {
                        id: picture
                        anchors.fill: parent
                        source: alerts.heldPeek !== null ? alerts.imageSource : ""
                        sourceSize.width: Appearance.alerts.expandedWidth * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }
                }
            }
        }

        Gesture {
            anchors.fill: parent
            enabled: alerts.isContentShown
            isVertical: false
            cursorShape: Qt.PointingHandCursor
            onCrossed: alerts.isFollowing = true
            onMoved: travelX => {
                if (alerts.isFollowing)
                    alerts.slide = travelX
            }
            onThrown: (travelX, travelY, velocityX) => {
                alerts.isFollowing = false
                const isAway = Math.abs(travelX) >= Motion.alerts.swipe || Math.abs(velocityX) >= Motion.alerts.fling
                if (!isAway) {
                    alerts.slide = 0
                    return
                }
                alerts.slide = Math.sign(travelX !== 0 ? travelX : velocityX) * content.width
                alerts.dismissRequested()
            }
            onTapped: alerts.openRequested(alerts.lead)
        }
    }
}
