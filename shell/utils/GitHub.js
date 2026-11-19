.pragma library

const site = "https://github.com/"
const api = "https://api.github.com"
var favoriteLimit = 5
var pushLimit = 15
var slides = ["history", "favorites", "pushes"]
var titles = { history: "GITHUB HISTORY", favorites: "FAVORITES", pushes: "RECENT PUSHES" }
const loginLength = 39
const dayLength = 86400000
const loginCharacters = "abcdefghijklmnopqrstuvwxyz0123456789-"

const repositoryFields = "nameWithOwner url description stargazerCount pushedAt primaryLanguage { name }"
const graph = "query($login: String!) { user(login: $login) {"
    + " contributionsCollection { contributionCalendar { weeks { contributionDays { contributionCount date } } } }"
    + " pinnedItems(first: 6, types: REPOSITORY) { nodes { ... on Repository { " + repositoryFields + " } } }"
    + " repositories(first: 60, ownerAffiliations: OWNER, orderBy: { field: PUSHED_AT, direction: DESC }) { nodes { " + repositoryFields + " } } } }"

function loginCommand() {
    return ["gh", "api", "user", "--jq", ".login"]
}

function connectCommand() {
    return ["sh", "-c", "for terminal in xdg-terminal-exec \"$TERMINAL\" foot alacritty wezterm ghostty konsole; do "
        + "command -v \"$terminal\" >/dev/null 2>&1 && exec \"$terminal\" -e gh auth login --web; done; "
        + "command -v kitty >/dev/null 2>&1 && exec kitty gh auth login --web; exit 127"]
}

function graphCommand(login) {
    return ["gh", "api", "graphql", "-f", "query=" + graph, "-f", "login=" + login]
}

function eventsCommand(login) {
    return ["gh", "api", "/users/" + login + "/events?per_page=60"]
}

function eventsLink(login) {
    return api + "/users/" + encodeURIComponent(login) + "/events/public?per_page=60"
}

function reposLink(login) {
    return api + "/users/" + encodeURIComponent(login) + "/repos?sort=pushed&per_page=60"
}

function reposCommand() {
    return ["gh", "api", "/user/repos?sort=pushed&per_page=60&affiliation=owner"]
}

function profileLink(login) {
    return site + login
}

function isLogin(text) {
    const lower = (text ?? "").toLowerCase()
    if (lower.length === 0 || lower.length > loginLength || lower.startsWith("-") || lower.endsWith("-") || lower.includes("--"))
        return false
    return Array.from(lower).every(character => loginCharacters.includes(character))
}

function levelOf(count, highest) {
    if (count <= 0 || highest <= 0)
        return 0
    return Math.min(4, Math.ceil(count / highest * 4))
}

function lastDays(days, total) {
    return days.slice(Math.max(0, days.length - total))
}

function readCalendar(answer) {
    const weeks = answer?.data?.user?.contributionsCollection?.contributionCalendar?.weeks ?? []
    const days = []
    for (const week of weeks)
        for (const day of week.contributionDays)
            days.push({ date: day.date, count: day.contributionCount })
    return days
}

function repositoryOf(node) {
    return {
        name: node.nameWithOwner,
        url: node.url,
        description: node.description ?? "",
        stars: node.stargazerCount ?? 0,
        language: node.primaryLanguage?.name ?? "",
        date: node.pushedAt ?? ""
    }
}

function readPinned(answer) {
    return (answer?.data?.user?.pinnedItems?.nodes ?? []).filter(node => node && node.nameWithOwner).map(repositoryOf)
}

function readRepositories(answer) {
    return (answer?.data?.user?.repositories?.nodes ?? []).filter(node => node && node.nameWithOwner).map(repositoryOf)
}

function readRepos(repos) {
    return (Array.isArray(repos) ? repos : []).map(repo => ({
        name: repo.full_name,
        url: repo.html_url,
        description: repo.description ?? "",
        stars: repo.stargazers_count ?? 0,
        language: repo.language ?? "",
        date: repo.pushed_at ?? ""
    }))
}

function favoritesOf(repositories, pinned, chosen) {
    if (chosen.length === 0)
        return (pinned.length > 0 ? pinned : repositories).slice(0, favoriteLimit)
    const known = {}
    for (const repository of pinned.concat(repositories))
        known[repository.name] = repository
    return chosen.filter(name => known[name]).map(name => known[name]).slice(0, favoriteLimit)
}

function toggled(current, name) {
    if (current.indexOf(name) >= 0)
        return current.filter(entry => entry !== name)
    return current.length >= favoriteLimit ? current : current.concat([name])
}

function readPushes(events) {
    const pushes = []
    for (const event of Array.isArray(events) ? events : []) {
        if (event.type !== "PushEvent" || !event.repo)
            continue
        const payload = event.payload ?? {}
        const commits = payload.commits ?? []
        const last = commits.length > 0 ? commits[commits.length - 1] : null
        const hash = last ? last.sha : payload.head
        const branch = (payload.ref ?? "").replace("refs/heads/", "")
        pushes.push({
            repository: event.repo.name,
            title: last ? last.message.split("\n")[0] : "pushed to " + (branch || "a branch"),
            url: hash ? site + event.repo.name + "/commit/" + hash : site + event.repo.name,
            date: event.created_at,
            hash: hash ?? ""
        })
    }
    return pushes.sort((first, second) => Date.parse(second.date) - Date.parse(first.date)).slice(0, pushLimit)
}

function headlineQuery(pushes) {
    const parts = []
    pushes.forEach((push, index) => {
        const [owner, name] = push.repository.split("/")
        if (push.hash.length > 0)
            parts.push("push" + index + ": repository(owner: " + JSON.stringify(owner) + ", name: " + JSON.stringify(name) + ") { object(oid: " + JSON.stringify(push.hash) + ") { ... on Commit { messageHeadline } } }")
    })
    return parts.length > 0 ? "query { " + parts.join(" ") + " }" : ""
}

function headlineCommand(query) {
    return ["gh", "api", "graphql", "-f", "query=" + query]
}

function withHeadlines(pushes, answer) {
    const found = answer?.data ?? {}
    return pushes.map((push, index) => {
        const headline = found["push" + index]?.object?.messageHeadline
        return headline ? Object.assign({}, push, { title: headline }) : push
    })
}

function calendarFromPushes(pushes, total, now) {
    const counts = {}
    for (const push of pushes) {
        const key = (push.date ?? "").slice(0, 10)
        counts[key] = (counts[key] ?? 0) + 1
    }
    const days = []
    for (let back = total - 1; back >= 0; back--) {
        const key = new Date(now - back * dayLength).toISOString().slice(0, 10)
        days.push({ date: key, count: counts[key] ?? 0 })
    }
    return days
}

function shortName(repository) {
    return repository.split("/").pop()
}

function nextIndex(index, count) {
    return stepIndex(index, count, 1)
}

function stepIndex(index, count, step) {
    return count > 0 ? ((index + step) % count + count) % count : 0
}

function ageOf(date, now) {
    const seconds = Math.floor((now - Date.parse(date)) / 1000)
    if (!Number.isFinite(seconds))
        return ""
    if (seconds < 3600)
        return Math.max(1, Math.floor(seconds / 60)) + "M"
    if (seconds < 86400)
        return Math.floor(seconds / 3600) + "H"
    return Math.floor(seconds / 86400) + "D"
}
