.pragma library

const operators = ["+", "-", "*", "/"]
const digits = "0123456789"
const significant = 12
const exponentDigits = 8
const largest = 1e15
const smallest = 1e-6
const exponentMark = "e"

const signs = { "*": "×", "/": "÷", "-": "−" }

const empty = { expression: "", previous: "", isDone: false }

function tokens(expression) {
    const found = []
    let index = 0
    while (index < expression.length) {
        const character = expression[index]
        if (digits.indexOf(character) >= 0 || character === ".") {
            let end = index
            while (end < expression.length && (digits.indexOf(expression[end]) >= 0 || expression[end] === "."))
                end++
            const text = expression.slice(index, end)
            if (text === "." || text.split(".").length > 2)
                return null
            found.push({ kind: "number", value: Number(text) })
            index = end
        } else if (operators.indexOf(character) >= 0 || "()%".indexOf(character) >= 0) {
            found.push({ kind: character })
            index++
        } else if (character === " ") {
            index++
        } else {
            return null
        }
    }
    return found
}

function closed(expression) {
    let depth = 0
    for (const character of expression) {
        if (character === "(")
            depth++
        else if (character === ")")
            depth = Math.max(0, depth - 1)
    }
    return expression + ")".repeat(depth)
}

function evaluate(expression) {
    const list = tokens(closed(String(expression)))
    if (list === null || list.length === 0)
        return { isValid: false, value: 0, error: "incomplete" }
    let at = 0
    let error = ""

    function peek() {
        return at < list.length ? list[at].kind : ""
    }

    function fail(kind) {
        if (error.length === 0)
            error = kind
        return 0
    }

    function primary() {
        const token = list[at]
        if (!token)
            return fail("incomplete")
        if (token.kind === "number") {
            at++
            return token.value
        }
        if (token.kind !== "(")
            return fail("incomplete")
        at++
        const value = sum()
        if (peek() !== ")")
            return fail("incomplete")
        at++
        return value
    }

    function postfix() {
        let value = primary()
        while (peek() === "%") {
            at++
            value = value / 100
        }
        return value
    }

    function unary() {
        if (peek() === "-") {
            at++
            return -unary()
        }
        if (peek() === "+") {
            at++
            return unary()
        }
        return postfix()
    }

    function product() {
        let value = unary()
        while (peek() === "*" || peek() === "/") {
            const kind = list[at++].kind
            const right = unary()
            if (kind === "/" && right === 0)
                return fail("divide")
            value = kind === "*" ? value * right : value / right
        }
        return value
    }

    function sum() {
        let value = product()
        while (peek() === "+" || peek() === "-") {
            const kind = list[at++].kind
            const right = product()
            value = kind === "+" ? value + right : value - right
        }
        return value
    }

    const value = sum()
    if (at < list.length)
        fail("incomplete")
    if (!isFinite(value))
        fail("overflow")
    return { isValid: error.length === 0, value: error.length === 0 ? value : 0, error: error }
}

function format(value) {
    if (value === 0)
        return "0"
    const size = Math.abs(value)
    if (size >= smallest && size < largest)
        return String(Number(value.toPrecision(significant)))
    let power = Math.floor(Math.log10(size))
    let mantissa = Number((value / Math.pow(10, power)).toPrecision(exponentDigits))
    if (Math.abs(mantissa) >= 10) {
        mantissa = mantissa / 10
        power++
    }
    return String(mantissa) + exponentMark + power
}

function shown(expression) {
    let text = ""
    for (const character of expression)
        text += signs[character] ?? character
    return text
}

function lastNumber(expression) {
    let start = expression.length
    while (start > 0 && (digits.indexOf(expression[start - 1]) >= 0 || expression[start - 1] === "."))
        start--
    return expression.slice(start)
}

function endsWithValue(expression) {
    const last = expression.slice(-1)
    return last.length > 0 && (digits.indexOf(last) >= 0 || last === ")" || last === "%" || last === ".")
}

function opened(expression) {
    let depth = 0
    for (const character of expression)
        depth += character === "(" ? 1 : character === ")" ? -1 : 0
    return depth
}

function typedDigit(expression, key) {
    const last = expression.slice(-1)
    if (last === ")" || last === "%")
        return expression + "*" + key
    if (lastNumber(expression) === "0")
        return expression.slice(0, -1) + key
    return expression + key
}

function typedPoint(expression) {
    const last = expression.slice(-1)
    const number = lastNumber(expression)
    if (number.indexOf(".") >= 0)
        return expression
    if (last === ")" || last === "%")
        return expression + "*0."
    return expression + (number.length === 0 ? "0." : ".")
}

function typedOperator(expression, key) {
    const last = expression.slice(-1)
    if (expression.length === 0)
        return key === "-" ? "-" : "0" + key
    if (last === "(")
        return key === "-" ? expression + "-" : expression
    if (operators.indexOf(last) < 0)
        return expression + key
    const before = expression.slice(-2, -1)
    if (expression.length === 1)
        return key === "-" ? "-" : expression
    if (before === "(")
        return key === "-" ? expression : expression.slice(0, -1)
    if (operators.indexOf(before) >= 0)
        return expression.slice(0, -2) + key
    if (key === "-" && (last === "*" || last === "/"))
        return expression + key
    return expression.slice(0, -1) + key
}

function typed(expression, key) {
    if (digits.indexOf(key) >= 0)
        return typedDigit(expression, key)
    if (key === ".")
        return typedPoint(expression)
    if (operators.indexOf(key) >= 0)
        return typedOperator(expression, key)
    const last = expression.slice(-1)
    if (key === "%")
        return endsWithValue(expression) && last !== "." ? expression + "%" : expression
    if (key === "(")
        return expression + (endsWithValue(expression) ? "*(" : "(")
    if (key === ")")
        return opened(expression) > 0 && endsWithValue(expression) ? expression + ")" : expression
    return expression
}

function press(state, key) {
    const current = state ?? empty
    if (key === "clear")
        return empty
    if (key === "back")
        return current.isDone ? empty : { expression: current.expression.slice(0, -1), previous: current.previous, isDone: false }
    if (key === "equals") {
        if (current.isDone || current.expression.length === 0)
            return current
        const result = evaluate(current.expression)
        if (!result.isValid)
            return current
        return { expression: format(result.value), previous: closed(current.expression), isDone: true }
    }
    if (current.isDone) {
        const continues = operators.indexOf(key) >= 0 || key === "%"
        return { expression: typed(continues ? current.expression : "", key), previous: current.previous, isDone: false }
    }
    return { expression: typed(current.expression, key), previous: current.previous, isDone: false }
}

function keyOf(text) {
    const named = { "x": "*", "X": "*", "×": "*", "÷": "/", "−": "-", ",": ".", "=": "equals" }
    if (named[text] !== undefined)
        return named[text]
    if (String(text).length === 1 && (digits.indexOf(text) >= 0 || operators.indexOf(text) >= 0 || "().%".indexOf(text) >= 0))
        return text
    return ""
}

function preview(state) {
    if (!state || state.isDone || state.expression.length === 0)
        return ""
    const result = evaluate(state.expression)
    if (!result.isValid)
        return ""
    const text = format(result.value)
    return text === state.expression ? "" : text
}

function failure(state) {
    if (!state || state.isDone || state.expression.length === 0)
        return ""
    return evaluate(state.expression).error === "divide" ? "divide" : ""
}
