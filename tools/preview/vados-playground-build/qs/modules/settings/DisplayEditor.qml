import QtQuick
import qs.config
import qs.components
import "../../utils/Displays.js" as Displays

Row {
    id: editor

    property var outputs: []
    property var trial: ({ phase: "idle" })
    property int trialLeft: 0
    property real areaWidth: 0
    property real areaHeight: 0
    property Item side: null
    readonly property real sideHeight: sideColumn.height
    property var draft: []
    property var base: []
    property var bodyNames: []
    property string picked: ""
    property string carried: ""
    property real carryX: 0
    property real carryY: 0
    property real carryFromX: 0
    property real carryFromY: 0
    property var heldView: null
    property real zoom: 1
    property real panX: 0
    property real panY: 0
    property real panFromX: 0
    property real panFromY: 0
    property bool isPanning: false
    property bool isViewing: false
    readonly property var look: Appearance.settings.displays
    readonly property var section: Appearance.settings.section
    readonly property bool isTrying: trial.phase === "trying"
    readonly property bool isEdited: !Displays.isSameLayout(Displays.anchored(draft, base), Displays.normalized(base))
    readonly property string problem: draft.length > 0 ? Displays.problemOf(draft) : "empty"
    readonly property bool canApply: isEdited && problem.length === 0
    readonly property var pickedOutput: draft.find(output => output.name === picked) ?? draft[0] ?? null
    readonly property string pickedName: pickedOutput ? pickedOutput.name : ""
    readonly property var resolutions: pickedOutput ? Displays.resolutionsOf(pickedOutput) : []
    readonly property int resolutionIndex: pickedOutput ? resolutions.findIndex(size => size.width === pickedOutput.mode.width && size.height === pickedOutput.mode.height) : -1
    readonly property var refreshes: pickedOutput ? Displays.refreshesOf(pickedOutput, pickedOutput.mode.width, pickedOutput.mode.height) : []
    readonly property real canvasWidth: Math.max(0, areaWidth - (side ? 0 : section.width + section.columnGap))
    readonly property real canvasHeight: Math.max(0, areaHeight)
    readonly property var liveView: viewOf(draft)
    readonly property var view: carried.length > 0 && heldView ? heldView : liveView
    readonly property string pressedName: gesture.pressed ? nameAt(gesture.pressPoint.x, gesture.pressPoint.y) : ""
    readonly property string problemText: ({
            overlap: "TWO MONITORS OVERLAP. DRAG ONE AGAINST AN EDGE.",
            gap: "EVERY MONITOR HAS TO TOUCH ANOTHER ALONG AN EDGE.",
            empty: "NO MONITORS FOUND."
        })[problem] ?? "THIS LAYOUT CANNOT BE APPLIED."

    signal applyRequested(var layout)
    signal keepRequested
    signal revertRequested

    spacing: section.columnGap

    function fitOf(bounds) {
        if (bounds.width <= 0 || bounds.height <= 0 || canvasWidth <= look.padding * 2 || canvasHeight <= look.padding * 2)
            return 0
        return Math.min((canvasWidth - look.padding * 2) / bounds.width, (canvasHeight - look.padding * 2) / bounds.height)
    }

    function clampPan(value, span, extent) {
        const room = Math.max(0, (extent - span) / 2 + look.padding)
        return Math.max(-room, Math.min(room, value))
    }

    function viewOf(layout) {
        const bounds = Displays.boundsOf(layout)
        const ratio = fitOf(bounds) * zoom
        if (ratio <= 0)
            return { x: 0, y: 0, ratio: 0, offsetX: 0, offsetY: 0 }
        const shiftX = clampPan(panX, canvasWidth, bounds.width * ratio)
        const shiftY = clampPan(panY, canvasHeight, bounds.height * ratio)
        return { x: bounds.x, y: bounds.y, ratio: ratio, offsetX: (canvasWidth - bounds.width * ratio) / 2 + shiftX, offsetY: (canvasHeight - bounds.height * ratio) / 2 + shiftY }
    }

    function panTo(x, y) {
        const bounds = Displays.boundsOf(draft)
        const ratio = fitOf(bounds) * zoom
        isViewing = true
        panX = clampPan(x, canvasWidth, bounds.width * ratio)
        panY = clampPan(y, canvasHeight, bounds.height * ratio)
        isViewing = false
    }

    function zoomAt(pointX, pointY, factor) {
        const bounds = Displays.boundsOf(draft)
        const fit = fitOf(bounds)
        if (fit <= 0 || carried.length > 0)
            return
        const current = liveView
        const worldX = (pointX - current.offsetX) / current.ratio + current.x
        const worldY = (pointY - current.offsetY) / current.ratio + current.y
        const next = Math.max(1, Math.min(look.zoomMax, zoom * factor))
        const ratio = fit * next
        isViewing = true
        zoom = next
        panTo(pointX - (worldX - bounds.x) * ratio - (canvasWidth - bounds.width * ratio) / 2, pointY - (worldY - bounds.y) * ratio - (canvasHeight - bounds.height * ratio) / 2)
    }

    function rectOnCanvas(output) {
        const rect = Displays.rectOf(output)
        return { x: (rect.x - view.x) * view.ratio + view.offsetX, y: (rect.y - view.y) * view.ratio + view.offsetY, width: rect.width * view.ratio, height: rect.height * view.ratio }
    }

    function nameAt(x, y) {
        const hit = draft.find(output => {
            const rect = rectOnCanvas(output)
            return x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height
        })
        return hit ? hit.name : ""
    }

    function reset() {
        base = outputs
        draft = outputs.map(output => Object.assign({}, output))
        const names = outputs.map(output => output.name)
        if (names.join("\n") !== bodyNames.join("\n"))
            bodyNames = names
        if (!names.includes(picked))
            picked = names.length > 0 ? names[0] : ""
    }

    function change(changes) {
        if (!pickedOutput)
            return
        draft = Displays.settled(Displays.withOutput(draft, pickedName, changes), pickedName, look.snap)
    }

    function stepResolution(direction) {
        if (!pickedOutput || resolutions.length === 0)
            return
        const index = Math.max(0, Math.min(resolutions.length - 1, resolutionIndex - direction))
        const size = resolutions[index]
        change({ mode: Displays.modeFor(pickedOutput, size.width, size.height, Displays.hertzOf(pickedOutput.mode.refresh)) })
    }

    function pickRefresh(hertz) {
        if (pickedOutput)
            change({ mode: Displays.modeFor(pickedOutput, pickedOutput.mode.width, pickedOutput.mode.height, hertz) })
    }

    function pickUp(name, travelX, travelY) {
        const output = draft.find(entry => entry.name === name)
        if (!output || view.ratio <= 0)
            return
        heldView = liveView
        const rect = rectOnCanvas(output)
        carryFromX = rect.x
        carryFromY = rect.y
        carryX = carryFromX + travelX
        carryY = carryFromY + travelY
        picked = name
        carried = name
    }

    function follow(travelX, travelY) {
        carryX = carryFromX + travelX
        carryY = carryFromY + travelY
    }

    function drop(velocityX, velocityY) {
        const name = carried
        const held = heldView
        if (name.length === 0 || !held || held.ratio <= 0)
            return
        const x = Math.round((carryX + velocityX * Motion.displays.fling - held.offsetX) / held.ratio + held.x)
        const y = Math.round((carryY + velocityY * Motion.displays.fling - held.offsetY) / held.ratio + held.y)
        draft = Displays.snapped(draft, name, x, y, look.snap)
        carried = ""
        heldView = null
    }

    function apply() {
        if (!canApply)
            return
        const layout = Displays.anchored(draft, base)
        base = draft
        applyRequested(layout)
    }

    function confirm() {
        if (isTrying && !isEdited)
            keepRequested()
        else
            apply()
    }

    onOutputsChanged: {
        const names = outputs.map(output => output.name).join("\n")
        if (!isEdited || draft.map(output => output.name).join("\n") !== names)
            reset()
    }
    Component.onCompleted: reset()

    Column {
        spacing: editor.section.rowGap

        Piece {
            role: "surface"
            width: editor.canvasWidth
            height: editor.canvasHeight

            Item {
                id: frame
                width: editor.canvasWidth
                height: editor.canvasHeight
                clip: true

                Squircle {
                    anchors.fill: parent
                    corner: editor.look.corner
                    color: Appearance.color.raised
                    strokeWidth: editor.look.line
                    strokeColor: Qt.alpha(Appearance.color.text, editor.look.lineAlpha)
                }

                Repeater {
                    model: editor.bodyNames

                    Item {
                        id: body

                        required property string modelData
                        readonly property var output: editor.draft.find(entry => entry.name === modelData) ?? null
                        readonly property var rect: output ? editor.rectOnCanvas(output) : ({ x: 0, y: 0, width: 0, height: 0 })
                        readonly property bool isCarried: editor.carried === modelData
                        readonly property bool isPicked: editor.pickedName === modelData
                        property real restX: 0
                        property real restY: 0
                        property real restWidth: 0
                        property real restHeight: 0
                        property bool isSettled: false

                        function rest() {
                            restX = rect.x
                            restY = rect.y
                            restWidth = rect.width
                            restHeight = rect.height
                            isSettled = true
                        }

                        function land() {
                            isSettled = false
                            restX = editor.carryX
                            restY = editor.carryY
                            isSettled = true
                            Qt.callLater(rest)
                        }

                        x: isCarried ? editor.carryX : restX
                        y: isCarried ? editor.carryY : restY
                        z: isCarried ? 1 : 0
                        width: restWidth
                        height: restHeight
                        visible: output !== null

                        onRectChanged: {
                            if (!isCarried)
                                rest()
                        }
                        onIsCarriedChanged: {
                            if (!isCarried)
                                land()
                        }
                        Component.onCompleted: rest()

                        Behavior on restX {
                            enabled: body.isSettled && !editor.isViewing
                            NumberAnimation {
                                duration: Motion.pace(Motion.displays.glide)
                                easing.type: Easing.OutBack
                            }
                        }

                        Behavior on restY {
                            enabled: body.isSettled && !editor.isViewing
                            NumberAnimation {
                                duration: Motion.pace(Motion.displays.glide)
                                easing.type: Easing.OutBack
                            }
                        }

                        Behavior on restWidth {
                            enabled: body.isSettled && !editor.isViewing
                            NumberAnimation {
                                duration: Motion.pace(Motion.displays.frame)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on restHeight {
                            enabled: body.isSettled && !editor.isViewing
                            NumberAnimation {
                                duration: Motion.pace(Motion.displays.frame)
                                easing.type: Easing.OutCubic
                            }
                        }

                        Piece {
                            anchors.fill: parent
                            isCentered: true

                            Item {
                                id: face
                                anchors.fill: parent

                                Press {
                                    target: face
                                    isPressed: editor.pressedName === body.modelData && !body.isCarried
                                    isRaised: body.isCarried
                                }

                                Squircle {
                                    anchors.fill: parent
                                    corner: editor.look.corner
                                    color: body.isPicked ? Qt.alpha(Appearance.color.accent, editor.look.bodyAlpha) : Qt.alpha(Appearance.color.text, editor.look.restAlpha)
                                    strokeWidth: body.isPicked || body.isCarried ? editor.look.outline : editor.look.line
                                    strokeColor: body.isPicked ? Appearance.color.accent : Qt.alpha(Appearance.color.text, editor.look.lineAlpha * 2)
                                }

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - editor.look.padding / 2
                                    spacing: editor.look.nameGap

                                    Text {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: body.modelData.toUpperCase()
                                        color: body.isPicked ? Appearance.color.accent : Appearance.color.text
                                        font.family: Appearance.font.mono
                                        font.pixelSize: Appearance.font.label
                                        font.letterSpacing: Appearance.font.labelSpacing
                                        font.bold: true
                                    }

                                    Text {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: body.output ? body.output.mode.width + " X " + body.output.mode.height + "  " + Displays.hertzOf(body.output.mode.refresh) + " HZ" : ""
                                        color: Appearance.color.textMuted
                                        font.family: Appearance.font.mono
                                        font.pixelSize: Appearance.font.chip
                                        font.letterSpacing: Appearance.font.labelSpacing
                                    }
                                }
                            }
                        }
                    }
                }

                Gesture {
                    id: gesture
                    anchors.fill: parent
                    cursorShape: editor.carried.length > 0 ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onTapped: mouse => {
                        const name = editor.nameAt(mouse.x, mouse.y)
                        if (name.length > 0)
                            editor.picked = name
                    }
                    onCrossed: (travelX, travelY) => {
                        const name = editor.nameAt(pressPoint.x, pressPoint.y)
                        if (name.length > 0) {
                            editor.pickUp(name, travelX, travelY)
                            return
                        }
                        editor.panFromX = editor.panX
                        editor.panFromY = editor.panY
                        editor.isPanning = true
                    }
                    onMoved: (travelX, travelY) => {
                        if (editor.carried.length > 0)
                            editor.follow(travelX, travelY)
                        else if (editor.isPanning)
                            editor.panTo(editor.panFromX + travelX, editor.panFromY + travelY)
                    }
                    onThrown: (travelX, travelY, velocityX, velocityY) => {
                        editor.isPanning = false
                        editor.drop(velocityX, velocityY)
                    }

                    WheelHandler {
                        id: wheel
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => editor.zoomAt(wheel.point.position.x, wheel.point.position.y, Math.pow(editor.look.zoomStep, event.angleDelta.y / Motion.settings.wheelNotch))
                    }
                }
            }
        }
    }

    Column {
        id: sideColumn
        parent: editor.side ?? editor
        spacing: editor.section.gap

        Section {
            title: "MONITOR"

            OptionGroup {
                options: editor.draft.map(output => output.name)
                current: editor.pickedName
                onPicked: option => editor.picked = option
            }

            Hint {
                text: !editor.pickedOutput ? "NO MONITORS FOUND" : (editor.pickedOutput.description ?? "").length > 0 ? editor.pickedOutput.description.toUpperCase() : "NO DESCRIPTION"
            }
        }

        Section {
            title: "MODE"

            Item {
                width: parent.width
                height: editor.look.stepper

                Piece {
                    role: "label"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "RESOLUTION"
                        color: Appearance.color.textBody
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                    }
                }

                Piece {
                    anchors.right: parent.right
                    height: editor.look.stepper

                    Row {
                        GlyphButton {
                            label: "<"
                            implicitHeight: editor.look.stepper
                            opacity: editor.resolutionIndex < editor.resolutions.length - 1 ? 1 : editor.section.disabled
                            onClicked: editor.stepResolution(-1)
                        }

                        Item {
                            width: editor.look.value
                            height: editor.look.stepper

                            Text {
                                anchors.centerIn: parent
                                text: editor.pickedOutput ? editor.pickedOutput.mode.width + " X " + editor.pickedOutput.mode.height : "-"
                                color: Appearance.color.text
                                font.family: Appearance.font.mono
                                font.pixelSize: Appearance.font.label
                                font.letterSpacing: Appearance.font.labelSpacing
                                font.bold: true
                            }
                        }

                        GlyphButton {
                            label: ">"
                            implicitHeight: editor.look.stepper
                            opacity: editor.resolutionIndex > 0 ? 1 : editor.section.disabled
                            onClicked: editor.stepResolution(1)
                        }
                    }
                }
            }

            OptionGroup {
                label: "REFRESH"
                options: editor.refreshes.map(hertz => hertz + " hz")
                current: editor.pickedOutput ? Displays.hertzOf(editor.pickedOutput.mode.refresh) + " hz" : ""
                onPicked: option => editor.pickRefresh(parseInt(option))
            }
        }

        Section {
            title: "SCALE & ROTATION"

            OptionGroup {
                label: "SCALE"
                options: Displays.scales.map(scale => String(scale))
                current: editor.pickedOutput ? String(editor.pickedOutput.scale) : ""
                onPicked: option => editor.change({ scale: parseFloat(option) })
            }

            OptionGroup {
                label: "ROTATION"
                options: Displays.rotations
                current: editor.pickedOutput ? editor.pickedOutput.transform : ""
                onPicked: option => editor.change({ transform: option })
            }
        }

        Row {
            spacing: Appearance.unit.small

            Piece {
                Action {
                    label: "APPLY"
                    isPrimary: true
                    isAvailable: editor.canApply
                    onClicked: editor.apply()
                }
            }

            Piece {
                Action {
                    label: "RESET"
                    isAvailable: editor.isEdited
                    onClicked: editor.reset()
                }
            }
        }

        Piece {
            Turn {
                isShown: editor.isTrying
                leaveWindow: 0
                enabled: editor.isTrying

                Row {
                    spacing: Appearance.unit.small

                    Text {
                        height: Appearance.settings.action.height
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: Appearance.settings.fieldPadding
                        text: "KEEP THIS LAYOUT?  " + Math.ceil(editor.trialLeft / 1000) + " S"
                        color: Appearance.color.accent
                        font.family: Appearance.font.mono
                        font.pixelSize: Appearance.font.label
                        font.letterSpacing: Appearance.font.labelSpacing
                        font.bold: true
                    }

                    Action {
                        label: "KEEP"
                        isPrimary: true
                        onClicked: editor.keepRequested()
                    }

                    Action {
                        label: "REVERT"
                        onClicked: editor.revertRequested()
                    }
                }
            }
        }

        Hint {
            isWanted: editor.isEdited && editor.problem.length > 0
            width: editor.section.width
            text: editor.problemText
        }
    }
}
