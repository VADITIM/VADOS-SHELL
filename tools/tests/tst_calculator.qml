import QtQuick
import QtTest
import qs.config
import qs.modules.calculator
import "../../shell/utils/Arithmetic.js" as Arithmetic
import "../../shell/utils/Builtins.js" as Builtins
import "../../shell/utils/Features.js" as Features

Item {
    id: scene

    width: Appearance.calculator.width
    height: Appearance.calculator.height

    Calculator {
        id: calculator
        anchors.fill: parent
        isShown: true
    }

    TestCase {
        name: "Calculator"
        when: windowShown

        function typed(text) {
            let state = Arithmetic.empty
            for (const character of text)
                state = Arithmetic.press(state, Arithmetic.keyOf(character) || character)
            return state
        }

        function keyLabelled(label) {
            let found = null
            const visit = item => {
                for (const child of item.children) {
                    if (child.label === label && child.kind !== undefined)
                        found = child
                    visit(child)
                }
            }
            visit(calculator)
            return found
        }

        function test_precedenceParenthesesAndPercent() {
            compare(Arithmetic.evaluate("12+3*4").value, 24)
            compare(Arithmetic.evaluate("(12+3)*4").value, 60)
            compare(Arithmetic.evaluate("2*(3+4").value, 14, "open parentheses close at the end")
            compare(Arithmetic.evaluate("50%*8").value, 4)
            compare(Arithmetic.evaluate("-3*-2").value, 6)
            compare(Arithmetic.evaluate("10/4").value, 2.5)
        }

        function test_brokenInputIsNeverValue() {
            compare(Arithmetic.evaluate("5/0").error, "divide")
            compare(Arithmetic.evaluate("1+").error, "incomplete")
            compare(Arithmetic.evaluate("1..2").isValid, false)
            compare(Arithmetic.evaluate("alert(1)").isValid, false, "only arithmetic is read, nothing is run")
            compare(Arithmetic.evaluate("").isValid, false)
        }

        function test_resultsReadLikeOnCalculators() {
            compare(Arithmetic.format(0.1 + 0.2), "0.3")
            compare(Arithmetic.format(1 / 3), "0.333333333333")
            compare(Arithmetic.format(2e20), "2e20")
            compare(Arithmetic.format(-1.5e-9), "-1.5e-9")
            compare(Arithmetic.format(0), "0")
            compare(Arithmetic.shown("3*-2/1"), "3×−2÷1")
        }

        function test_typingKeepsTheExpressionWellFormed() {
            compare(typed("0005").expression, "5", "leading zeros fold")
            compare(typed("1..5").expression, "1.5", "one point per number")
            compare(typed("7+*2").expression, "7*2", "a second operator replaces the first")
            compare(typed("2*-3").expression, "2*-3", "a minus after a product is a sign")
            compare(typed("2(3").expression, "2*(3", "a parenthesis after a value multiplies")
            compare(typed("(-+").expression, "(", "a sign after a parenthesis can be taken back")
            compare(typed(")").expression, "", "a parenthesis closes only what is open")
            compare(typed("+").expression, "0+")
        }

        function test_equalsThenContinueOrStartOver() {
            const done = typed("3+4=")
            compare(done.expression, "7")
            compare(done.previous, "3+4")
            verify(done.isDone)
            compare(Arithmetic.press(done, "*").expression, "7*", "an operator continues from the result")
            compare(Arithmetic.press(done, "9").expression, "9", "a digit starts over")
            compare(Arithmetic.press(done, "back").expression, "", "back after a result clears")
            compare(typed("5/0=").expression, "5/0", "equals on a broken expression keeps it")
            compare(Arithmetic.preview(typed("3+4")), "7")
            compare(Arithmetic.failure(typed("5/0")), "divide")
        }

        function test_theLauncherFindsEveryAppWindow() {
            const windows = Features.features.filter(feature => feature.surface === "window")
            verify(windows.length > 0)
            for (const feature of windows) {
                const app = Builtins.byKey(feature.key)
                verify(app !== null, feature.key + " has a launcher row")
                verify(app.id.length > 0 && app.name.length > 0 && app.icon.length > 0)
                compare(Builtins.byId(app.id), app)
            }
            compare(Builtins.opened([], "calculator"), ["calculator"])
            compare(Builtins.opened(["calculator"], "calculator"), ["calculator"], "an open window opens once")
            compare(Builtins.opened([], "ghost"), [], "an unknown app never opens")
            compare(Builtins.closed(["calculator"], "calculator"), [])
            compare(Builtins.toggled(Builtins.toggled([], "calculator"), "calculator"), [])
        }

        function test_keyboardDrivesTheDisplay() {
            tryVerify(() => calculator.isReady, 2000)
            calculator.forceActiveFocus()
            calculator.entry = Arithmetic.empty
            keyClick(Qt.Key_1)
            keyClick(Qt.Key_2)
            keyClick(Qt.Key_Plus)
            keyClick(Qt.Key_3)
            compare(calculator.entry.expression, "12+3")
            compare(calculator.caption, "= 15")
            keyClick(Qt.Key_Return)
            compare(calculator.entry.expression, "15")
            compare(calculator.caption, "12+3 =")
            keyClick(Qt.Key_Escape)
            compare(calculator.entry.expression, "")
        }

        function test_tappingKeysPressesThem() {
            calculator.entry = Arithmetic.empty
            const seven = keyLabelled("7")
            const times = keyLabelled("×")
            verify(seven !== null && times !== null)
            tryVerify(() => seven.width > 0, 1000)
            mouseClick(seven, seven.width / 2, seven.height / 2)
            mouseClick(times, times.width / 2, times.height / 2)
            mouseClick(seven, seven.width / 2, seven.height / 2)
            compare(calculator.entry.expression, "7*7")
            compare(calculator.preview, "49")
        }
    }
}
