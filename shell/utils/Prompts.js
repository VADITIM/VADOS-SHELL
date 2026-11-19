.pragma library

function fromPolkit(flow, attempt) {
    if (!flow || flow.isCompleted)
        return null
    return {
        source: "polkit",
        key: "polkit:" + (flow.cookie ?? ""),
        attempt: attempt,
        kind: "password",
        title: "ADMIN RIGHTS",
        message: flow.message ?? "",
        description: "",
        field: (flow.inputPrompt ?? "").replace(/:\s*$/, ""),
        isEcho: flow.responseVisible === true,
        isReady: flow.isResponseRequired === true,
        warning: flow.supplementaryIsError === true ? (flow.supplementaryMessage ?? "") : "",
        choice: "",
        isChoiceChosen: false,
        isNew: false,
        continueLabel: ""
    }
}

function fromKeyring(event) {
    if (!event || (event.kind !== "password" && event.kind !== "confirm"))
        return null
    return {
        source: "keyring",
        key: "keyring:" + event.id,
        id: event.id,
        attempt: 0,
        kind: event.kind,
        title: event.title || "KEYRING",
        message: event.message ?? "",
        description: event.description ?? "",
        field: event.password_new === true ? "NEW PASSWORD" : "PASSWORD",
        isEcho: false,
        isReady: true,
        warning: event.warning ?? "",
        choice: event.choice_label ?? "",
        isChoiceChosen: event.choice_chosen === true,
        isNew: event.password_new === true,
        continueLabel: event.continue_label ?? ""
    }
}

function pick(polkitRequest, keyringRequest) {
    return polkitRequest ?? keyringRequest ?? null
}

function canSubmit(request, password, repeat) {
    if (!request || !request.isReady)
        return false
    if (request.kind === "confirm")
        return true
    if (request.isNew)
        return password.length > 0 && password === repeat
    return true
}

function keyringReply(request, isContinue, password, isChoiceChosen) {
    const reply = { id: request.id, reply: isContinue ? "continue" : "cancel" }
    if (isContinue && request.kind === "password")
        reply.password = password
    if (request.choice.length > 0)
        reply.choice = isChoiceChosen === true
    return reply
}
