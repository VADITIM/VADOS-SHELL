import QtQuick
import QtTest
import "../../shell/utils/Prompts.js" as Prompts

TestCase {
    name: "Prompts"

    function flowOf(fields) {
        return Object.assign({ cookie: "c1", message: "Authentication is needed", inputPrompt: "Password: ", responseVisible: false, isResponseRequired: true, supplementaryIsError: false, supplementaryMessage: "", isCompleted: false }, fields)
    }

    function keyringEvent(fields) {
        return Object.assign({ id: 3, kind: "password", title: "Unlock Keyring", message: "An application wants access", description: "", warning: "", choice_label: "", choice_chosen: false, password_new: false, continue_label: "Unlock" }, fields)
    }

    function test_polkitFlowBecomesARequest() {
        const request = Prompts.fromPolkit(flowOf({}), 0)
        compare(request.source, "polkit")
        compare(request.kind, "password")
        compare(request.field, "Password", "the trailing colon of the PAM prompt is dropped")
        verify(request.isReady)
        compare(request.warning, "")
    }

    function test_completedOrMissingFlowAsksNothing() {
        compare(Prompts.fromPolkit(null, 0), null)
        compare(Prompts.fromPolkit(flowOf({ isCompleted: true }), 0), null)
    }

    function test_polkitErrorIsAWarningButInfoIsNot() {
        compare(Prompts.fromPolkit(flowOf({ supplementaryIsError: true, supplementaryMessage: "Sorry, try again" }), 1).warning, "Sorry, try again")
        compare(Prompts.fromPolkit(flowOf({ supplementaryMessage: "Touch the key" }), 0).warning, "")
    }

    function test_keyringEventsBecomeRequests() {
        const request = Prompts.fromKeyring(keyringEvent({ choice_label: "Remember", choice_chosen: true }))
        compare(request.source, "keyring")
        compare(request.id, 3)
        compare(request.choice, "Remember")
        verify(request.isChoiceChosen)
        compare(Prompts.fromKeyring({ kind: "close", id: 3 }), null)
        compare(Prompts.fromKeyring({ kind: "ready" }), null)
    }

    function test_polkitGoesFirst() {
        const polkit = Prompts.fromPolkit(flowOf({}), 0)
        const keyring = Prompts.fromKeyring(keyringEvent({}))
        compare(Prompts.pick(polkit, keyring), polkit)
        compare(Prompts.pick(null, keyring), keyring)
        compare(Prompts.pick(null, null), null)
    }

    function test_submitNeedsAReadyRequestAndMatchingNewPasswords() {
        verify(!Prompts.canSubmit(null, "", ""))
        verify(!Prompts.canSubmit(Prompts.fromPolkit(flowOf({ isResponseRequired: false }), 0), "x", ""), "nothing is sent while polkit checks")
        verify(Prompts.canSubmit(Prompts.fromKeyring(keyringEvent({ kind: "confirm" })), "", ""))
        const fresh = Prompts.fromKeyring(keyringEvent({ password_new: true }))
        verify(!Prompts.canSubmit(fresh, "", ""))
        verify(!Prompts.canSubmit(fresh, "abc", "abd"))
        verify(Prompts.canSubmit(fresh, "abc", "abc"))
    }

    function test_keyringReplyCarriesOnlyWhatWasAsked() {
        const asked = Prompts.fromKeyring(keyringEvent({ choice_label: "Remember" }))
        compare(Prompts.keyringReply(asked, true, "secret", true), { id: 3, reply: "continue", password: "secret", choice: true })
        compare(Prompts.keyringReply(asked, false, "secret", false), { id: 3, reply: "cancel", choice: false })
        const confirm = Prompts.fromKeyring(keyringEvent({ kind: "confirm" }))
        compare(Prompts.keyringReply(confirm, true, "ignored", false), { id: 3, reply: "continue" })
    }
}
