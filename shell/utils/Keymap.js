.pragma library

const modernProtocol = 12
const momentaryBase = 0x5220
const toggleBase = 0x5260
const layerReach = 8

const basic = [
    ["KC_NO", 0x00, "NONE", "special"],
    ["KC_TRNS", 0x01, "▽", "special"],
    ["KC_A", 0x04, "A", "letters"], ["KC_B", 0x05, "B", "letters"], ["KC_C", 0x06, "C", "letters"],
    ["KC_D", 0x07, "D", "letters"], ["KC_E", 0x08, "E", "letters"], ["KC_F", 0x09, "F", "letters"],
    ["KC_G", 0x0A, "G", "letters"], ["KC_H", 0x0B, "H", "letters"], ["KC_I", 0x0C, "I", "letters"],
    ["KC_J", 0x0D, "J", "letters"], ["KC_K", 0x0E, "K", "letters"], ["KC_L", 0x0F, "L", "letters"],
    ["KC_M", 0x10, "M", "letters"], ["KC_N", 0x11, "N", "letters"], ["KC_O", 0x12, "O", "letters"],
    ["KC_P", 0x13, "P", "letters"], ["KC_Q", 0x14, "Q", "letters"], ["KC_R", 0x15, "R", "letters"],
    ["KC_S", 0x16, "S", "letters"], ["KC_T", 0x17, "T", "letters"], ["KC_U", 0x18, "U", "letters"],
    ["KC_V", 0x19, "V", "letters"], ["KC_W", 0x1A, "W", "letters"], ["KC_X", 0x1B, "X", "letters"],
    ["KC_Y", 0x1C, "Y", "letters"], ["KC_Z", 0x1D, "Z", "letters"],
    ["KC_1", 0x1E, "1", "numbers"], ["KC_2", 0x1F, "2", "numbers"], ["KC_3", 0x20, "3", "numbers"],
    ["KC_4", 0x21, "4", "numbers"], ["KC_5", 0x22, "5", "numbers"], ["KC_6", 0x23, "6", "numbers"],
    ["KC_7", 0x24, "7", "numbers"], ["KC_8", 0x25, "8", "numbers"], ["KC_9", 0x26, "9", "numbers"],
    ["KC_0", 0x27, "0", "numbers"],
    ["KC_ENT", 0x28, "ENTER", "editing"], ["KC_ESC", 0x29, "ESC", "editing"], ["KC_BSPC", 0x2A, "BACKSPACE", "editing"],
    ["KC_TAB", 0x2B, "TAB", "editing"], ["KC_SPC", 0x2C, "SPACE", "editing"],
    ["KC_MINS", 0x2D, "-", "symbols"], ["KC_EQL", 0x2E, "=", "symbols"], ["KC_LBRC", 0x2F, "[", "symbols"],
    ["KC_RBRC", 0x30, "]", "symbols"], ["KC_BSLS", 0x31, "\\", "symbols"], ["KC_NUHS", 0x32, "ISO #", "symbols"],
    ["KC_SCLN", 0x33, ";", "symbols"], ["KC_QUOT", 0x34, "'", "symbols"], ["KC_GRV", 0x35, "`", "symbols"],
    ["KC_COMM", 0x36, ",", "symbols"], ["KC_DOT", 0x37, ".", "symbols"], ["KC_SLSH", 0x38, "/", "symbols"],
    ["KC_NUBS", 0x64, "ISO \\", "symbols"],
    ["KC_CAPS", 0x39, "CAPS", "editing"],
    ["KC_F1", 0x3A, "F1", "function"], ["KC_F2", 0x3B, "F2", "function"], ["KC_F3", 0x3C, "F3", "function"],
    ["KC_F4", 0x3D, "F4", "function"], ["KC_F5", 0x3E, "F5", "function"], ["KC_F6", 0x3F, "F6", "function"],
    ["KC_F7", 0x40, "F7", "function"], ["KC_F8", 0x41, "F8", "function"], ["KC_F9", 0x42, "F9", "function"],
    ["KC_F10", 0x43, "F10", "function"], ["KC_F11", 0x44, "F11", "function"], ["KC_F12", 0x45, "F12", "function"],
    ["KC_PSCR", 0x46, "PRINT", "navigation"], ["KC_SCRL", 0x47, "SCROLL", "navigation"], ["KC_PAUS", 0x48, "PAUSE", "navigation"],
    ["KC_INS", 0x49, "INSERT", "navigation"], ["KC_HOME", 0x4A, "HOME", "navigation"], ["KC_PGUP", 0x4B, "PAGE UP", "navigation"],
    ["KC_DEL", 0x4C, "DELETE", "navigation"], ["KC_END", 0x4D, "END", "navigation"], ["KC_PGDN", 0x4E, "PAGE DOWN", "navigation"],
    ["KC_RGHT", 0x4F, "→", "navigation"], ["KC_LEFT", 0x50, "←", "navigation"], ["KC_DOWN", 0x51, "↓", "navigation"],
    ["KC_UP", 0x52, "↑", "navigation"],
    ["KC_NUM", 0x53, "NUM LOCK", "keypad"], ["KC_PSLS", 0x54, "KP /", "keypad"], ["KC_PAST", 0x55, "KP *", "keypad"],
    ["KC_PMNS", 0x56, "KP -", "keypad"], ["KC_PPLS", 0x57, "KP +", "keypad"], ["KC_PENT", 0x58, "KP ENTER", "keypad"],
    ["KC_P1", 0x59, "KP 1", "keypad"], ["KC_P2", 0x5A, "KP 2", "keypad"], ["KC_P3", 0x5B, "KP 3", "keypad"],
    ["KC_P4", 0x5C, "KP 4", "keypad"], ["KC_P5", 0x5D, "KP 5", "keypad"], ["KC_P6", 0x5E, "KP 6", "keypad"],
    ["KC_P7", 0x5F, "KP 7", "keypad"], ["KC_P8", 0x60, "KP 8", "keypad"], ["KC_P9", 0x61, "KP 9", "keypad"],
    ["KC_P0", 0x62, "KP 0", "keypad"], ["KC_PDOT", 0x63, "KP .", "keypad"],
    ["KC_APP", 0x65, "MENU", "editing"],
    ["KC_F13", 0x68, "F13", "function"], ["KC_F14", 0x69, "F14", "function"], ["KC_F15", 0x6A, "F15", "function"],
    ["KC_F16", 0x6B, "F16", "function"], ["KC_F17", 0x6C, "F17", "function"], ["KC_F18", 0x6D, "F18", "function"],
    ["KC_F19", 0x6E, "F19", "function"], ["KC_F20", 0x6F, "F20", "function"], ["KC_F21", 0x70, "F21", "function"],
    ["KC_F22", 0x71, "F22", "function"], ["KC_F23", 0x72, "F23", "function"], ["KC_F24", 0x73, "F24", "function"],
    ["KC_MUTE", 0xA8, "MUTE", "media"], ["KC_VOLU", 0xA9, "VOLUME +", "media"], ["KC_VOLD", 0xAA, "VOLUME -", "media"],
    ["KC_MNXT", 0xAB, "NEXT", "media"], ["KC_MPRV", 0xAC, "PREVIOUS", "media"], ["KC_MSTP", 0xAD, "STOP", "media"],
    ["KC_MPLY", 0xAE, "PLAY", "media"],
    ["KC_LCTL", 0xE0, "LEFT CTRL", "modifiers"], ["KC_LSFT", 0xE1, "LEFT SHIFT", "modifiers"], ["KC_LALT", 0xE2, "LEFT ALT", "modifiers"],
    ["KC_LGUI", 0xE3, "LEFT SUPER", "modifiers"], ["KC_RCTL", 0xE4, "RIGHT CTRL", "modifiers"], ["KC_RSFT", 0xE5, "RIGHT SHIFT", "modifiers"],
    ["KC_RALT", 0xE6, "RIGHT ALT", "modifiers"], ["KC_RGUI", 0xE7, "RIGHT SUPER", "modifiers"]
]

const ansi = [
    ["KC_ESC", 1, "KC_F1", "KC_F2", "KC_F3", "KC_F4", 0.5, "KC_F5", "KC_F6", "KC_F7", "KC_F8", 0.5, "KC_F9", "KC_F10", "KC_F11", "KC_F12"],
    ["KC_GRV", "KC_1", "KC_2", "KC_3", "KC_4", "KC_5", "KC_6", "KC_7", "KC_8", "KC_9", "KC_0", "KC_MINS", "KC_EQL", ["KC_BSPC", 2]],
    [["KC_TAB", 1.5], "KC_Q", "KC_W", "KC_E", "KC_R", "KC_T", "KC_Y", "KC_U", "KC_I", "KC_O", "KC_P", "KC_LBRC", "KC_RBRC", ["KC_BSLS", 1.5]],
    [["KC_CAPS", 1.75], "KC_A", "KC_S", "KC_D", "KC_F", "KC_G", "KC_H", "KC_J", "KC_K", "KC_L", "KC_SCLN", "KC_QUOT", ["KC_ENT", 2.25]],
    [["KC_LSFT", 2.25], "KC_Z", "KC_X", "KC_C", "KC_V", "KC_B", "KC_N", "KC_M", "KC_COMM", "KC_DOT", "KC_SLSH", ["KC_RSFT", 2.75]],
    [["KC_LCTL", 1.25], ["KC_LGUI", 1.25], ["KC_LALT", 1.25], ["KC_SPC", 6.25], ["KC_RALT", 1.25], ["KC_RGUI", 1.25], ["KC_APP", 1.25], ["KC_RCTL", 1.25]]
]

function entryOf(row) {
    return { name: row[0], code: row[1], label: row[2], group: row[3] }
}

function catalogue(protocol) {
    const entries = basic.map(entryOf)
    if (protocol >= modernProtocol) {
        for (let layer = 0; layer < layerReach; layer++) {
            entries.push({ name: "MO(" + layer + ")", code: momentaryBase + layer, label: "HOLD " + layer, group: "layers" })
            entries.push({ name: "TG(" + layer + ")", code: toggleBase + layer, label: "TOGGLE " + layer, group: "layers" })
        }
    }
    return entries
}

function labelOf(code, protocol) {
    const found = catalogue(protocol).find(entry => entry.code === code)
    return found ? found.label : "0x" + code.toString(16).toUpperCase().padStart(4, "0")
}

function matches(entry, query) {
    const needle = String(query ?? "").trim().toLowerCase()
    return needle.length === 0 || entry.name.toLowerCase().includes(needle) || entry.label.toLowerCase().includes(needle) || entry.group.includes(needle)
}

function matrixOf(label) {
    const parts = String(label ?? "").split("\n")
    const position = (parts[0] ?? "").split(",")
    if (position.length !== 2)
        return null
    const row = parseInt(position[0], 10)
    const column = parseInt(position[1], 10)
    if (!Number.isInteger(row) || !Number.isInteger(column))
        return null
    const option = (parts[3] ?? "").split(",")
    const choice = option.length === 2 ? parseInt(option[1], 10) : 0
    return { row: row, column: column, isDefault: choice === 0 }
}

function parseLayout(rows) {
    const keys = []
    let y = 0
    for (const row of Array.from(rows ?? [])) {
        if (!Array.isArray(row))
            continue
        let x = 0
        let width = 1
        let height = 1
        let isDecal = false
        for (const item of row) {
            if (item !== null && typeof item === "object") {
                x += item.x ?? 0
                y += item.y ?? 0
                width = item.w ?? width
                height = item.h ?? height
                isDecal = item.d ?? isDecal
                continue
            }
            const matrix = matrixOf(item)
            if (!isDecal && matrix !== null && matrix.isDefault)
                keys.push({ row: matrix.row, column: matrix.column, x: x, y: y, width: width, height: height })
            x += width
            width = 1
            height = 1
            isDecal = false
        }
        y += 1
    }
    return keys
}

function fallback() {
    const keys = []
    ansi.forEach((row, rowIndex) => {
        let x = 0
        for (const item of row) {
            if (typeof item === "number") {
                x += item
                continue
            }
            const name = Array.isArray(item) ? item[0] : item
            const width = Array.isArray(item) ? item[1] : 1
            const entry = basic.find(candidate => candidate[0] === name)
            keys.push({ row: -1, column: -1, x: x, y: rowIndex, width: width, height: 1, code: entry ? entry[1] : 0 })
            x += width
        }
    })
    return keys
}

function extentOf(keys) {
    let width = 0
    let height = 0
    for (const key of keys) {
        width = Math.max(width, key.x + key.width)
        height = Math.max(height, key.y + key.height)
    }
    return { width: width, height: height }
}

function codeAt(keymap, layer, row, column) {
    const value = ((keymap ?? [])[layer] ?? [])[row]
    return value ? (value[column] ?? 0) : 0
}

function keyName(layer, row, column) {
    return layer + ":" + row + ":" + column
}

function withEdit(edits, layer, row, column, code, original) {
    const next = Object.assign({}, edits)
    const name = keyName(layer, row, column)
    if (code === original)
        delete next[name]
    else
        next[name] = code
    return next
}

function changesOf(edits) {
    return Object.keys(edits ?? {}).map(name => {
        const parts = name.split(":").map(part => parseInt(part, 10))
        return { layer: parts[0], row: parts[1], column: parts[2], code: edits[name] }
    })
}
