import QtQuick
import qs.config
import qs.components
import "../../utils/Prompts.js" as Prompts

FocusScope {
    id: prompt

    required property bool isMirrored
    property var request: null
    property rect body: Qt.rect(0, 0, 0, 0)
    property bool isBodyShown: false
    property var shown: null
    property string zone: "field"
    property bool isChoiceChosen: false
    property bool isChecking: false
    property real shakeOffset: 0
    readonly property var look: Appearance.prompt
    readonly property size bodySize: Qt.size(look.width, Math.ceil(content.implicitHeight) + look.padding * 2)
    readonly property bool isContentShown: isBodyShown
    readonly property bool isPassword: shown !== null && shown.kind === "password"
    readonly property bool isNew: shown !== null && shown.isNew
    readonly property bool hasChoice: shown !== null && shown.choice.length > 0
    readonly property bool canSubmit: !isChecking && Prompts.canSubmit(shown, field.text, repeat.text)
    readonly property string warning: shown === null ? "" : isNew && repeat.text.length > 0 && repeat.text !== field.text ? "THE PASSWORDS DO NOT MATCH" : shown.warning

    signal submitted(string password, bool isChoiceChosen)
    signal cancelled(string reason)

    transform: Upright {
        isMirrored: prompt.isMirrored
        axis: prompt.width / 2
    }

    function zones() {
        const order = []
        if (isPassword)
            order.push("field")
        if (isNew)
            order.push("repeat")
        if (hasChoice)
            order.push("choice")
        order.push("cancel", "confirm")
        return order
    }

    function cycle(step) {
        const order = zones()
        const at = Math.max(0, order.indexOf(zone))
        zone = order[(at + step + order.length) % order.length]
    }

    function submit() {
        if (!canSubmit)
            return
        isChecking = shown.source === "polkit"
        submitted(field.text, isChoiceChosen)
    }

    function press() {
        if (zone === "choice")
            isChoiceChosen = !isChoiceChosen
        else if (zone === "cancel")
            cancelled("the CANCEL button")
        else if (zone === "field" && isNew)
            zone = "repeat"
        else
            submit()
    }

    function focusZone() {
        if (zone === "repeat")
            repeat.focusInput()
        else if (zone === "field")
            field.focusInput()
        else
            prompt.forceActiveFocus()
    }

    function take(next) {
        const isFresh = shown === null || next === null || shown.key !== next.key
        const isRetry = !isFresh && next.attempt > shown.attempt
        if (next !== null)
            shown = next
        isChecking = isChecking && !isRetry && !(next?.isReady ?? false)
        if (isFresh || isRetry) {
            field.text = ""
            repeat.text = ""
        }
        if (isFresh && next !== null) {
            isChoiceChosen = next.isChoiceChosen
            zone = zones()[0]
            isChecking = false
        }
        if (isRetry)
            shake.restart()
    }

    onRequestChanged: take(request)
    onZoneChanged: focusZone()
    onIsBodyShownChanged: {
        if (isBodyShown)
            focusZone()
    }

    SequentialAnimation {
        id: shake
        paused: Motion.isHeld && running

        NumberAnimation { target: prompt; property: "shakeOffset"; to: prompt.look.shake; duration: Motion.pace(Motion.prompt.shake / 4) }
        NumberAnimation { target: prompt; property: "shakeOffset"; to: -prompt.look.shake; duration: Motion.pace(Motion.prompt.shake / 2) }
        NumberAnimation { target: prompt; property: "shakeOffset"; to: 0; duration: Motion.pace(Motion.prompt.shake / 4); easing.type: Easing.OutBack }
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            prompt.cancelled("Escape")
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            prompt.press()
            break
        case Qt.Key_Space:
            if (prompt.zone === "field" || prompt.zone === "repeat")
                return
            prompt.press()
            break
        case Qt.Key_Tab:
        case Qt.Key_Down:
            prompt.cycle(1)
            break
        case Qt.Key_Backtab:
        case Qt.Key_Up:
            prompt.cycle(-1)
            break
        case Qt.Key_Left:
        case Qt.Key_Right:
            if (prompt.zone !== "cancel" && prompt.zone !== "confirm")
                return
            prompt.zone = prompt.zone === "cancel" ? "confirm" : "cancel"
            break
        default:
            return
        }
        event.accepted = true
    }

    Column {
        id: content
        x: prompt.body.x + prompt.look.padding + prompt.shakeOffset
        y: prompt.body.y + prompt.look.padding
        width: prompt.look.width - prompt.look.padding * 2
        spacing: prompt.look.rowGap
        visible: prompt.isContentShown || title.presence > 0

        Turn {
            id: title
            width: parent.width
            height: titleText.implicitHeight
            isShown: prompt.isContentShown
            enterDuration: Motion.clipboard.faceEnter
            leaveDuration: Motion.clipboard.faceLeave

            ScrambleText {
                id: titleText
                width: parent.width
                label: "prompt title"
                target: (prompt.shown?.title ?? "").toUpperCase()
                isShown: parent.isShown
                color: Appearance.color.accent
                family: Appearance.font.sans
            }
        }

        Turn {
            width: parent.width
            height: message.implicitHeight
            isShown: prompt.isContentShown && message.text.length > 0
            visible: message.text.length > 0
            enterDelay: Motion.prompt.stagger
            leaveDuration: Motion.clipboard.faceLeave

            Text {
                id: message
                width: parent.width
                wrapMode: Text.WordWrap
                text: [prompt.shown?.message ?? "", prompt.shown?.description ?? ""].filter(line => line.length > 0).join("\n")
                color: Appearance.color.text
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.body
            }
        }

        PromptField {
            id: field
            width: parent.width
            visible: prompt.isPassword
            isShown: prompt.isContentShown && prompt.isPassword
            look: prompt.look
            label: prompt.shown?.field ?? ""
            isEcho: prompt.shown?.isEcho ?? false
            isChecking: prompt.isChecking
            isError: prompt.warning.length > 0
            isSelected: prompt.zone === "field"
            enterDelay: Motion.prompt.stagger * 2
            leaveDuration: Motion.clipboard.faceLeave
            onPointed: prompt.zone = "field"
        }

        PromptField {
            id: repeat
            width: parent.width
            visible: prompt.isNew
            isShown: prompt.isContentShown && prompt.isNew
            look: prompt.look
            label: "REPEAT"
            isError: prompt.warning.length > 0
            isSelected: prompt.zone === "repeat"
            enterDelay: Motion.prompt.stagger * 3
            leaveDuration: Motion.clipboard.faceLeave
            onPointed: prompt.zone = "repeat"
        }

        Turn {
            width: parent.width
            height: warningText.implicitHeight
            visible: prompt.warning.length > 0
            isShown: prompt.isContentShown && prompt.warning.length > 0
            isFlipping: false

            Text {
                id: warningText
                width: parent.width
                wrapMode: Text.WordWrap
                text: prompt.warning.toUpperCase()
                color: Appearance.color.danger
                font.family: Appearance.font.sans
                font.pixelSize: Appearance.font.chip
                font.letterSpacing: Appearance.font.labelSpacing
            }
        }

        Turn {
            width: parent.width
            height: prompt.look.toggle + prompt.look.caret * 2
            visible: prompt.hasChoice
            isShown: prompt.isContentShown && prompt.hasChoice
            enterDelay: Motion.prompt.stagger * 4
            leaveDuration: Motion.clipboard.faceLeave

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: prompt.look.buttonGap

                Rectangle {
                    width: prompt.look.toggle
                    height: prompt.look.toggle
                    radius: width / 2
                    color: prompt.isChoiceChosen ? Appearance.color.accent : "transparent"
                    border.width: prompt.look.caret
                    border.color: prompt.zone === "choice" || choiceHover.hovered ? Appearance.color.accent : Appearance.color.hairline
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: prompt.shown?.choice ?? ""
                    color: Appearance.color.textMuted
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.label
                }
            }

            HoverHandler {
                id: choiceHover
            }

            TapHandler {
                onTapped: {
                    prompt.zone = "choice"
                    prompt.isChoiceChosen = !prompt.isChoiceChosen
                }
            }
        }

        Row {
            width: parent.width
            spacing: prompt.look.buttonGap

            PromptButton {
                width: (parent.width - parent.spacing) / 2
                look: prompt.look
                text: "CANCEL"
                isShown: prompt.isContentShown
                isSelected: prompt.zone === "cancel"
                enterDelay: Motion.prompt.stagger * 5
                leaveDuration: Motion.clipboard.faceLeave
                onTapped: prompt.cancelled("a tap on CANCEL")
            }

            PromptButton {
                width: (parent.width - parent.spacing) / 2
                look: prompt.look
                text: prompt.isChecking ? "CHECKING" : "CONFIRM"
                isShown: prompt.isContentShown
                isSelected: prompt.zone === "confirm"
                isFilled: true
                isEnabled: prompt.canSubmit
                enterDelay: Motion.prompt.stagger * 6
                leaveDuration: Motion.clipboard.faceLeave
                onTapped: {
                    prompt.zone = "confirm"
                    prompt.submit()
                }
            }
        }
    }
}
