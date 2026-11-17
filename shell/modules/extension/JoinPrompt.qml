import QtQuick
import qs.config
import qs.components

Column {
    id: prompt

    property string ask: "passphrase"
    property string ssid: ""
    property string error: ""
    property bool isShown: false
    property bool isRevealed: false
    readonly property bool hasIdentity: ask === "identity"
    readonly property bool isNaming: ask === "name"
    readonly property bool canSubmit: secret.text.length > 0 && (!hasIdentity || identity.text.length > 0)
    readonly property string title: isNaming ? "HIDDEN NETWORK" : hasIdentity ? "SIGN IN TO " + ssid.toUpperCase() : ask === "key" ? "KEY PASSPHRASE" : "PASSWORD FOR " + ssid.toUpperCase()

    signal submitted(var values)
    signal canceled()

    function submit() {
        if (!canSubmit)
            return
        const values = hasIdentity ? [identity.text, secret.text] : [secret.text]
        secret.text = ""
        submitted(values)
    }

    spacing: Appearance.extension.promptGap
    Component.onCompleted: (hasIdentity ? identity : secret).input.forceActiveFocus()

    TypedText {
        width: Math.min(fullWidth, prompt.width)
        clip: true
        isShown: prompt.isShown
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        target: prompt.title
        color: Appearance.color.text
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.label
        font.letterSpacing: Appearance.font.labelSpacing
        font.bold: true
    }

    TypedText {
        width: Math.min(fullWidth, prompt.width)
        visible: prompt.error.length > 0
        isShown: prompt.isShown && prompt.error.length > 0
        characterInterval: Motion.type.quick
        untypeInterval: Motion.type.quickUntype
        target: prompt.error
        color: Appearance.color.danger
        font.family: Appearance.font.sans
        font.pixelSize: Appearance.font.chip
        font.letterSpacing: Appearance.font.labelSpacing
        font.bold: true
    }

    Turn {
        width: prompt.width
        height: Appearance.extension.field
        visible: prompt.hasIdentity
        isShown: prompt.isShown && prompt.hasIdentity
        enterDelay: Motion.reveal.stagger

        JoinField {
            id: identity
            width: parent.width
            placeholder: "USER NAME"
            KeyNavigation.tab: secret.input
            onSubmitted: secret.input.forceActiveFocus()
            onCanceled: prompt.canceled()
        }
    }

    Turn {
        width: prompt.width
        height: Appearance.extension.field
        isShown: prompt.isShown
        enterDelay: Motion.reveal.stagger * 2

        JoinField {
            id: secret
            width: parent.width
            placeholder: prompt.isNaming ? "NETWORK NAME" : "PASSWORD"
            isSecret: !prompt.isNaming
            isRevealed: prompt.isRevealed
            KeyNavigation.tab: prompt.hasIdentity ? identity.input : secret.input
            onSubmitted: prompt.submit()
            onCanceled: prompt.canceled()
        }
    }

    Row {
        anchors.right: parent.right
        spacing: 6

        Turn {
            visible: !prompt.isNaming
            isShown: prompt.isShown && !prompt.isNaming
            enterDelay: Motion.reveal.stagger * 3

            GlyphButton {
                label: prompt.isRevealed ? "HIDE" : "SHOW"
                onClicked: prompt.isRevealed = !prompt.isRevealed
            }
        }

        Turn {
            isShown: prompt.isShown
            enterDelay: Motion.reveal.stagger * 4

            GlyphButton {
                label: "CANCEL"
                onClicked: prompt.canceled()
            }
        }

        Turn {
            isShown: prompt.isShown
            enterDelay: Motion.reveal.stagger * 5

            GlyphButton {
                label: "JOIN"
                isSelected: prompt.canSubmit
                color: prompt.canSubmit ? Appearance.color.textBody : Appearance.color.textFaint
                onClicked: prompt.submit()
            }
        }
    }
}
