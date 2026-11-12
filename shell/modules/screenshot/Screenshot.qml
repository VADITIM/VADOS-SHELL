import QtQuick
import qs.config
import qs.components
import "../../utils/Ink.js" as Ink

Item {
    id: shot

    property bool isOpen: false
    property url frame: ""
    property bool isMirrored: false
    property real pillSpineX: Appearance.taskbar.margin + Appearance.taskbar.thickness / 2
    property real pillCenterY: height / 2
    property size pillSize: Qt.size(Appearance.activity.width, Appearance.activity.length)
    property string pillGlyph: ""
    property var selection: null
    property string tool: "select"
    property string shapeKind: "box"
    property color inkColor: Appearance.capture.ink
    property string menu: ""
    property var strokes: []
    property var drawing: null
    property var heldSelection: null
    property var heldStroke: null
    property int heldIndex: -1
    property int heldCorner: -1
    property int editingIndex: -1
    property string dragMode: ""
    property bool isCutting: false
    property real presence: 0

    readonly property var look: Appearance.capture
    readonly property var bounds: ({ x: 0, y: 0, width: width, height: height })
    readonly property bool hasSelection: Ink.isUsable(selection, look.smallest)
    readonly property var shown: selection ?? { x: 0, y: 0, width: 0, height: 0 }
    readonly property real pixelRatio: frameImage.implicitWidth > 0 && width > 0 ? frameImage.implicitWidth / width : 1
    readonly property point pointer: pointerHover.hovered ? pointerHover.point.position : Qt.point(-1, -1)
    readonly property bool isPointerInside: hasSelection && Ink.contains(selection, pointer)
    readonly property bool isEditing: tool === "select" || tool === "shape"
    readonly property bool canCarry: isEditing || tool === "text"
    readonly property var handles: isEditing ? Ink.handlesOf(strokes) : []
    readonly property var selectionHandles: tool === "select" && hasSelection ? Ink.cornersOfRect(selection) : []
    readonly property bool isOverHandle: isEditing && (Ink.cornerAt(handles, pointer, look.grab) >= 0 || Ink.cornerAt(selectionHandles, pointer, look.grab) >= 0)
    readonly property var cycle: Ink.tools.filter(entry => entry.key !== "color")
    readonly property bool isPresent: lifecycle.isPresent
    readonly property string phase: lifecycle.phase

    signal closeRequested()
    signal cutReady(var result)

    opacity: presence
    focus: true

    function reset() {
        selection = null
        heldSelection = null
        heldStroke = null
        heldIndex = -1
        heldCorner = -1
        editingIndex = -1
        strokes = []
        drawing = null
        dragMode = ""
        menu = ""
        tool = "select"
        isCutting = false
    }

    function pick(key) {
        finishText()
        menu = ""
        tool = key
    }

    function toggleMenu(key) {
        finishText()
        menu = menu === key ? "" : key
        if (key === "shape")
            tool = "shape"
    }

    function editText(index) {
        editingIndex = index
        textEditor.text = strokes[index].text
        textEditor.cursorPosition = textEditor.length
        textEditor.forceActiveFocus()
    }

    function writeText(text) {
        if (editingIndex >= 0)
            strokes = Ink.replaced(strokes, editingIndex, Ink.withText(strokes[editingIndex], text))
    }

    function finishText() {
        if (editingIndex < 0)
            return
        const index = editingIndex
        editingIndex = -1
        if (strokes[index].text.trim().length === 0)
            strokes = Ink.removed(strokes, index)
        shot.forceActiveFocus()
    }

    function placeText(point) {
        const index = Ink.textAt(strokes, point, look.grab)
        if (index >= 0) {
            editText(index)
            return
        }
        strokes = strokes.concat([Ink.textOf(inkColor.toString(), look.textSize, { x: point.x, y: point.y - look.textSize * look.textLift })])
        editText(strokes.length - 1)
    }

    function pickColor(value) {
        inkColor = value
        if (!Ink.isDrawing(tool))
            tool = "paint"
    }

    function pickShape(key) {
        shapeKind = key
        menu = ""
        tool = "shape"
    }

    function undo() {
        strokes = Ink.undone(strokes)
    }

    function nudge(stepX, stepY) {
        if (hasSelection)
            selection = Ink.moved(selection, stepX, stepY, bounds)
    }

    function selectAll() {
        finishText()
        selection = { x: 0, y: 0, width: width, height: height }
    }

    function cut() {
        if (isCutting || !lifecycle.isShowing)
            return
        finishText()
        if (!hasSelection)
            selection = { x: 0, y: 0, width: width, height: height }
        menu = ""
        isCutting = true
        const size = Qt.size(Math.round(selection.width * pixelRatio), Math.round(selection.height * pixelRatio))
        if (!cutArea.grabToImage(result => shot.cutReady(result), size)) {
            isCutting = false
            closeRequested()
        }
    }

    function hold(index, corner) {
        heldIndex = index
        heldCorner = corner
        heldStroke = strokes[index]
    }

    function startDrag(pressed) {
        const point = Ink.pointOf(pressed)
        finishText()
        menu = ""
        const isInside = hasSelection && Ink.contains(selection, point)
        const grab = isEditing ? Ink.grabOf(strokes, point, look.grab) : null
        const selectionCorner = Ink.cornerAt(selectionHandles, point, look.grab)
        const shapeIndex = canCarry ? Ink.shapeAt(strokes, point, look.grab) : -1
        if (grab) {
            dragMode = "reshape"
            hold(grab.index, grab.corner)
        } else if (selectionCorner >= 0) {
            dragMode = "resize"
            heldCorner = selectionCorner
            heldSelection = selection
        } else if (shapeIndex >= 0) {
            dragMode = "carry"
            hold(shapeIndex, -1)
        } else if (isInside && tool === "select") {
            dragMode = "move"
            heldSelection = selection
        } else if (Ink.isDrawing(tool)) {
            dragMode = "draw"
            drawing = Ink.strokeOf(tool === "shape" ? shapeKind : "paint", inkColor.toString(), look.stroke, point)
        } else if (tool === "text") {
            dragMode = "idle"
        } else if (tool === "erase") {
            dragMode = "erase"
            strokes = Ink.erased(strokes, point, look.eraser)
        } else {
            dragMode = "select"
            heldSelection = selection
            selection = Ink.rectOf(point, point)
        }
    }

    function followDrag(moved, travelX, travelY) {
        const point = Ink.pointOf(moved)
        if (dragMode === "move")
            selection = Ink.moved(heldSelection, travelX, travelY, bounds)
        else if (dragMode === "resize")
            selection = Ink.resized(heldSelection, heldCorner, point, bounds)
        else if (dragMode === "reshape")
            strokes = Ink.replaced(strokes, heldIndex, Ink.reshaped(heldStroke, heldCorner, point))
        else if (dragMode === "carry")
            strokes = Ink.replaced(strokes, heldIndex, Ink.shifted(heldStroke, travelX, travelY))
        else if (dragMode === "draw")
            drawing = Ink.extended(drawing, point)
        else if (dragMode === "erase")
            strokes = Ink.erased(strokes, point, look.eraser)
        else if (dragMode === "select")
            selection = Ink.clampInto(Ink.rectOf(Ink.pointOf(gesture.pressPoint), point), bounds)
    }

    function tap(tapped) {
        const point = Ink.pointOf(tapped)
        const wasEditing = editingIndex >= 0
        finishText()
        if (menu.length > 0)
            menu = ""
        else if (tool === "text" && !wasEditing)
            placeText(point)
        else if (tool === "select" && Ink.textAt(strokes, point, look.grab) >= 0)
            editText(Ink.textAt(strokes, point, look.grab))
        else if (tool === "erase")
            strokes = Ink.erased(strokes, point, look.eraser)
        else if (tool === "select" && hasSelection && !Ink.contains(selection, point))
            selection = Ink.centeredAt(selection, point, bounds)
    }

    function endDrag() {
        if (dragMode === "draw" && drawing)
            strokes = strokes.concat([drawing])
        if (dragMode === "select" && !hasSelection)
            selection = Ink.isUsable(heldSelection, look.smallest) ? heldSelection : null
        drawing = null
        heldSelection = null
        heldStroke = null
        heldIndex = -1
        heldCorner = -1
        dragMode = ""
    }

    property Lifecycle lifecycle: Lifecycle {
        name: "screenshot"
        canRecover: true
        onMoved: (from, to, event) => {
            if (event === "settle") {
                enter.stop()
                leave.stop()
                shot.presence = to === "idle" ? 0 : 1
            } else if (to === "preparing") {
                leave.stop()
                shot.reset()
                shot.forceActiveFocus()
                shot.lifecycle.send("prepared")
            } else if (to === "entering" && from === "preparing") {
                enter.start()
            } else if (to === "recovering") {
                leave.stop()
                shot.reset()
                shot.forceActiveFocus()
                shot.lifecycle.send("recovered")
            } else if (to === "entering") {
                enter.start()
            } else if (to === "exiting") {
                enter.stop()
                leave.start()
            }
        }
    }

    onIsOpenChanged: lifecycle.send(isOpen ? "show" : "hide")
    Component.onCompleted: {
        if (isOpen)
            lifecycle.send("show")
    }

    SequentialAnimation {
        id: enter
        paused: Motion.isHeld && running

        NumberAnimation {
            target: shot
            property: "presence"
            to: 1
            duration: Motion.pace(Motion.capture.dim)
            easing.type: Easing.OutQuad
        }
        ScriptAction { script: shot.lifecycle.send("entered") }
    }

    SequentialAnimation {
        id: leave
        paused: Motion.isHeld && running

        NumberAnimation {
            target: shot
            property: "presence"
            to: 0
            duration: Motion.pace(Motion.capture.leave)
            easing.type: Easing.OutQuad
        }
        ScriptAction { script: shot.lifecycle.send("exited") }
    }

    Keys.onPressed: event => {
        const isControl = (event.modifiers & Qt.ControlModifier) !== 0
        const step = (event.modifiers & Qt.ShiftModifier) !== 0 ? look.nudgeFar : look.nudge
        if (event.key === Qt.Key_Escape)
            shot.closeRequested()
        else if ((isControl && (event.key === Qt.Key_C || event.key === Qt.Key_S)) || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            shot.cut()
        else if (isControl && event.key === Qt.Key_A)
            shot.selectAll()
        else if (isControl && event.key === Qt.Key_Z)
            shot.undo()
        else if (event.key === Qt.Key_Tab)
            shot.pick(Ink.nextOf(shot.cycle, shot.tool, 1))
        else if (event.key === Qt.Key_Backtab)
            shot.pick(Ink.nextOf(shot.cycle, shot.tool, -1))
        else if (event.key === Qt.Key_Left)
            shot.nudge(-step, 0)
        else if (event.key === Qt.Key_Right)
            shot.nudge(step, 0)
        else if (event.key === Qt.Key_Up)
            shot.nudge(0, -step)
        else if (event.key === Qt.Key_Down)
            shot.nudge(0, step)
        else
            return
        event.accepted = true
    }

    Image {
        id: frameImage
        anchors.fill: parent
        source: shot.frame
        cache: false
        smooth: true
        mipmap: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Appearance.color.shadow.r, Appearance.color.shadow.g, Appearance.color.shadow.b, shot.look.dim)
    }

    InkCanvas {
        anchors.fill: parent
        strokes: shot.strokes
        drawing: shot.drawing
        hiddenIndex: shot.editingIndex
    }

    Item {
        id: cutArea
        x: shot.shown.x
        y: shot.shown.y
        width: shot.shown.width
        height: shot.shown.height
        visible: shot.selection !== null
        clip: true

        Image {
            x: -cutArea.x
            y: -cutArea.y
            width: shot.width
            height: shot.height
            source: shot.frame
            cache: false
            smooth: true
            mipmap: true
        }

        InkCanvas {
            x: -cutArea.x
            y: -cutArea.y
            width: shot.width
            height: shot.height
            strokes: shot.strokes
            drawing: shot.drawing
            hiddenIndex: shot.editingIndex
        }
    }

    Rectangle {
        x: shot.shown.x - border.width
        y: shot.shown.y - border.width
        width: shot.shown.width + border.width * 2
        height: shot.shown.height + border.width * 2
        visible: shot.selection !== null && !shot.isCutting
        color: "transparent"
        border.width: shot.look.outline
        border.color: Appearance.color.accent
    }

    Rectangle {
        readonly property bool isAbove: shot.shown.y >= height + shot.look.sizeGap
        x: Math.max(0, Math.min(shot.width - width, shot.shown.x))
        y: isAbove ? shot.shown.y - height - shot.look.sizeGap : Math.min(shot.height - height, shot.shown.y + shot.shown.height + shot.look.sizeGap)
        width: sizeText.implicitWidth + shot.look.sizePadding * 2
        height: shot.look.sizeHeight
        radius: height / 2
        visible: shot.hasSelection && !shot.isCutting
        color: Appearance.color.panel

        Text {
            id: sizeText
            anchors.centerIn: parent
            text: Math.round(shot.shown.width * shot.pixelRatio) + " × " + Math.round(shot.shown.height * shot.pixelRatio)
            color: Appearance.color.textBody
            font.family: Appearance.font.mono
            font.pixelSize: Appearance.font.chip
            font.letterSpacing: Appearance.font.labelSpacing
        }
    }

    Rectangle {
        x: shot.pointer.x - width / 2
        y: shot.pointer.y - height / 2
        width: shot.look.eraser * 2
        height: width
        radius: width / 2
        visible: shot.tool === "erase" && shot.isPointerInside && !shot.isCutting
        color: "transparent"
        border.width: shot.look.outline
        border.color: Appearance.color.text
    }

    Repeater {
        model: shot.isCutting ? [] : shot.handles.concat(shot.selectionHandles)

        Rectangle {
            required property var modelData
            x: modelData.x - width / 2
            y: modelData.y - height / 2
            width: shot.look.handle
            height: width
            radius: width / 2
            color: Appearance.color.panel
            border.width: shot.look.outline
            border.color: Appearance.color.accent
        }
    }

    HoverHandler {
        id: pointerHover
    }

    Gesture {
        id: gesture
        anchors.fill: parent
        threshold: 0
        enabled: shot.lifecycle.isShowing && !shot.isCutting
        cursorShape: shot.isOverHandle ? Qt.SizeFDiagCursor : shot.tool === "text" ? Qt.IBeamCursor : shot.isPointerInside && shot.tool === "select" ? Qt.SizeAllCursor : Qt.CrossCursor
        onCrossed: shot.startDrag(gesture.pressPoint)
        onMoved: (travelX, travelY) => shot.followDrag(Qt.point(gesture.pressPoint.x + travelX, gesture.pressPoint.y + travelY), travelX, travelY)
        onEnded: shot.endDrag()
        onTapped: mouse => shot.tap(Qt.point(mouse.x, mouse.y))
    }

    TextEdit {
        id: textEditor
        readonly property var stroke: shot.editingIndex >= 0 ? shot.strokes[shot.editingIndex] : null
        x: stroke ? stroke.points[0].x : 0
        y: stroke ? stroke.points[0].y : 0
        visible: stroke !== null
        enabled: visible
        color: stroke ? stroke.color : Appearance.color.text
        selectionColor: Appearance.color.accent
        font.family: Appearance.font.fixedMono
        font.pixelSize: stroke ? stroke.width : shot.look.textSize
        font.bold: true
        cursorVisible: visible
        onTextChanged: if (visible && stroke && text !== stroke.text) shot.writeText(text)
        Keys.onPressed: event => {
            const isShift = (event.modifiers & Qt.ShiftModifier) !== 0
            if (event.key === Qt.Key_Escape || ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !isShift)) {
                shot.finishText()
                event.accepted = true
            }
        }

        Rectangle {
            x: -shot.look.textPadding
            y: -shot.look.textPadding
            z: -1
            width: Math.max(parent.contentWidth, shot.look.textSize / 2) + shot.look.textPadding * 2
            height: parent.contentHeight + shot.look.textPadding * 2
            radius: shot.look.textPadding
            color: "transparent"
            border.width: shot.look.outline
            border.color: Appearance.color.accent
        }
    }

    Toolbar {
        x: shot.isMirrored ? shot.width - shot.pillSpineX - width + spineX : shot.pillSpineX - spineX
        y: shot.pillCenterY - height / 2
        isShown: !shot.isCutting && shot.lifecycle.isShowing
        startSize: shot.pillSize
        startGlyph: shot.pillGlyph
        isMirrored: shot.isMirrored
        tool: shot.tool
        shapeKind: shot.shapeKind
        inkColor: shot.inkColor
        menu: shot.menu
        onToolPicked: key => shot.pick(key)
        onMenuToggled: key => shot.toggleMenu(key)
        onColorPicked: value => shot.pickColor(value)
        onShapePicked: key => shot.pickShape(key)
    }
}
