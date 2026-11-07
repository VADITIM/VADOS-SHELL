.pragma library

const version = 1

const settings = {
    "taskbar.enabled": { type: "boolean", fallback: true },
    "taskbar.style": { type: "string", fallback: "floating", choices: ["floating", "fused", "bare"] },
    "taskbar.side": { type: "string", fallback: "left", choices: ["left", "right"] },
    "taskbar.compact": { type: "boolean", fallback: false },
    "appearance.accent": { type: "colour", fallback: "#ffffff" },
    "desktop.mode": { type: "string", fallback: "canvas", choices: ["canvas", "desktop"] },
    "search.favorites": { type: "names", fallback: [] },
    "profile.name": { type: "string", fallback: "" },
    "profile.picture": { type: "string", fallback: "" },
    "weather.location": { type: "string", fallback: "" },
    "notifications.enabled": { type: "boolean", fallback: false },
    "motion.reduced": { type: "boolean", fallback: false },
    "attention.doNotDisturb": { type: "boolean", fallback: false },
    "rendering.quality": { type: "string", fallback: "full", choices: ["full", "lite"] }
}

const migrations = [
    raw => raw
]

const colourPattern = /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/

function describe(value) {
    return JSON.stringify(value) ?? String(value)
}

function isPlainObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
}

function copyOf(value) {
    return Array.isArray(value) ? value.slice() : value
}

function splitKey(key) {
    const dot = key.indexOf(".")
    return { group: key.slice(0, dot), name: key.slice(dot + 1) }
}

function findProblem(key, value) {
    const rule = settings[key]
    if (!rule)
        return "is not a setting"
    if (rule.type === "boolean" && typeof value !== "boolean")
        return `is ${describe(value)}, expected true or false`
    if (rule.type === "string" && typeof value !== "string")
        return `is ${describe(value)}, expected text in quotes`
    if (rule.type === "colour" && !(typeof value === "string" && colourPattern.test(value)))
        return `is ${describe(value)}, expected a hex colour like "#ffffff"`
    if (rule.type === "names" && !(Array.isArray(value) && value.every(entry => typeof entry === "string")))
        return `is ${describe(value)}, expected a list of names in quotes`
    if (rule.choices && rule.choices.indexOf(value) < 0)
        return `is ${describe(value)}, expected one of ${rule.choices.map(describe).join(", ")}`
    return ""
}

function createDefaults() {
    const result = { version: version }
    for (const key in settings) {
        const parts = splitKey(key)
        result[parts.group] = result[parts.group] ?? {}
        result[parts.group][parts.name] = copyOf(settings[key].fallback)
    }
    return result
}

function readVersion(raw) {
    if (!("version" in raw))
        return { number: 0, problem: "" }
    if (Number.isInteger(raw.version) && raw.version >= 0)
        return { number: raw.version, problem: "" }
    return { number: 0, problem: `version is ${describe(raw.version)}, expected a whole number; reading the file as unversioned` }
}

function migrate(raw) {
    const found = readVersion(raw)
    const problems = found.problem ? [found.problem] : []
    if (found.number > version) {
        problems.push(`version is ${found.number}, newer than this shell (${version}); reading only the settings it knows`)
        return { settings: raw, from: found.number, problems: problems }
    }
    let migrated = raw
    for (let step = found.number; step < version; step++)
        migrated = migrations[step](migrated)
    return { settings: migrated, from: found.number, problems: problems }
}

function validate(raw) {
    const result = createDefaults()
    const problems = []
    let isRepaired = false
    for (const group in raw) {
        if (group === "version")
            continue
        const values = raw[group]
        const isKnownGroup = Object.keys(settings).some(key => splitKey(key).group === group)
        if (!isKnownGroup) {
            problems.push(`${group} is not a settings group; it is ignored`)
            continue
        }
        if (!isPlainObject(values)) {
            problems.push(`${group} is ${describe(values)}, expected a group of settings in braces; using the defaults for ${group}`)
            isRepaired = true
            continue
        }
        for (const name in values) {
            const key = group + "." + name
            if (!settings[key]) {
                problems.push(`${key} is not a setting; it is ignored`)
                continue
            }
            const problem = findProblem(key, values[name])
            if (problem) {
                problems.push(`${key} ${problem}; using ${describe(settings[key].fallback)}`)
                isRepaired = true
                continue
            }
            result[group][name] = copyOf(values[name])
        }
    }
    return { settings: result, problems: problems, isRepaired: isRepaired }
}

function repair(raw) {
    if (!isPlainObject(raw))
        return {
            settings: createDefaults(),
            problems: [`the file holds ${describe(raw)}, expected settings in braces; using the defaults and leaving the file as it is`],
            shouldWrite: false
        }
    const migrated = migrate(raw)
    const validated = validate(migrated.settings)
    const isNewer = migrated.from > version
    return {
        settings: validated.settings,
        problems: migrated.problems.concat(validated.problems),
        shouldWrite: !isNewer && (migrated.from < version || validated.isRepaired)
    }
}
